#include "BBCRSaveCrypto_native.h"
#include <windows.h>
#include <wincrypt.h>
#include <bcrypt.h>
#include <algorithm>
#include <cstring>
#include <stdexcept>

namespace {
using Bytes = std::vector<unsigned char>;
constexpr size_t max_plain = 1024 * 1024;
constexpr size_t max_wrapped = 16384;
constexpr char magic[] = "BBCRSAV2";
constexpr char entropy_text[] = "BBCRForGM/save/v2/current-user";
thread_local std::int32_t status = 0;
thread_local std::string last_error;

struct Secret {
    Bytes bytes;
    explicit Secret(size_t size = 0) : bytes(size) {}
    ~Secret() { if (!bytes.empty()) SecureZeroMemory(bytes.data(), bytes.size()); }
    Secret(const Secret&) = delete;
    Secret& operator=(const Secret&) = delete;
};
struct LocalBlob {
    DATA_BLOB data{};
    ~LocalBlob() { if (data.pbData) { SecureZeroMemory(data.pbData, data.cbData); LocalFree(data.pbData); } }
};
struct File {
    HANDLE h = INVALID_HANDLE_VALUE;
    explicit File(HANDLE handle) : h(handle) {}
    ~File() { close(); }
    void close() { if (h != INVALID_HANDLE_VALUE) { CloseHandle(h); h = INVALID_HANDLE_VALUE; } }
    File(const File&) = delete;
};
struct Algorithm {
    BCRYPT_ALG_HANDLE h{};
    ~Algorithm() { if (h) BCryptCloseAlgorithmProvider(h, 0); }
};
struct Key {
    BCRYPT_KEY_HANDLE h{};
    ~Key() { if (h) BCryptDestroyKey(h); }
};
void require(bool ok, const char* message) { if (!ok) throw std::runtime_error(message); }
void nt(NTSTATUS result, const char* message) { require(result >= 0, message); }
void begin() { status = -1; last_error.clear(); }
void failed(const std::exception& e) { status = -1; last_error = e.what(); }
std::wstring wide(std::string_view value) {
    require(!value.empty() && value.size() < 32768 && value.find('\0') == std::string_view::npos, "Invalid save path");
    const int count = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(), static_cast<int>(value.size()), nullptr, 0);
    require(count > 0, "Invalid UTF-8 path");
    std::wstring result(count, L'\0');
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(), static_cast<int>(value.size()), result.data(), count);
    return result;
}
void text_valid(std::string_view text) {
    require(text.size() <= max_plain && text.find('\0') == std::string_view::npos, "Invalid save text length or embedded NUL");
    require(text.empty() || MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.data(), static_cast<int>(text.size()), nullptr, 0) > 0, "Invalid UTF-8 save text");
}
bool exists(const std::wstring& path) {
    const DWORD attributes = GetFileAttributesW(path.c_str());
    if (attributes != INVALID_FILE_ATTRIBUTES) { require(!(attributes & FILE_ATTRIBUTE_DIRECTORY), "Save path is a directory"); return true; }
    require(GetLastError() == ERROR_FILE_NOT_FOUND || GetLastError() == ERROR_PATH_NOT_FOUND, "Cannot inspect save file");
    return false;
}
Bytes read_file(const std::wstring& path) {
    File file(CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr));
    require(file.h != INVALID_HANDLE_VALUE, "Cannot open save file");
    LARGE_INTEGER size{};
    require(GetFileSizeEx(file.h, &size) && size.QuadPart >= 0 && size.QuadPart <= static_cast<LONGLONG>(max_plain + max_wrapped + 128), "Save file is oversized");
    Bytes result(static_cast<size_t>(size.QuadPart)); DWORD actual{};
    require(ReadFile(file.h, result.data(), static_cast<DWORD>(result.size()), &actual, nullptr) && actual == result.size(), "Cannot read complete save file");
    return result;
}
void u32(Bytes& out, size_t value) { for (unsigned i = 0; i < 4; ++i) out.push_back(static_cast<unsigned char>(value >> (i * 8))); }
size_t get32(const Bytes& data, size_t offset) {
    require(offset + 4 <= data.size(), "Truncated save header"); size_t value = 0;
    for (unsigned i = 0; i < 4; ++i) value |= static_cast<size_t>(data[offset + i]) << (i * 8);
    return value;
}
DATA_BLOB entropy() { return {static_cast<DWORD>(sizeof(entropy_text) - 1), reinterpret_cast<BYTE*>(const_cast<char*>(entropy_text))}; }
void random(Bytes& bytes) { nt(BCryptGenRandom(nullptr, bytes.data(), static_cast<ULONG>(bytes.size()), BCRYPT_USE_SYSTEM_PREFERRED_RNG), "Secure random generation failed"); }
void aes_open(Algorithm& alg, Key& key, Bytes& raw, bool gcm) {
    nt(BCryptOpenAlgorithmProvider(&alg.h, BCRYPT_AES_ALGORITHM, nullptr, 0), "AES unavailable");
    const auto mode = gcm ? BCRYPT_CHAIN_MODE_GCM : BCRYPT_CHAIN_MODE_CBC;
    nt(BCryptSetProperty(alg.h, BCRYPT_CHAINING_MODE, reinterpret_cast<PUCHAR>(const_cast<wchar_t*>(mode)), static_cast<ULONG>((wcslen(mode) + 1) * sizeof(wchar_t)), 0), "AES mode unavailable");
    nt(BCryptGenerateSymmetricKey(alg.h, &key.h, nullptr, 0, raw.data(), static_cast<ULONG>(raw.size()), 0), "AES key creation failed");
}
void unwrap(const Bytes& wrapped, Secret& key, bool v2) {
    DATA_BLOB in{static_cast<DWORD>(wrapped.size()), const_cast<BYTE*>(wrapped.data())};
    auto extra = entropy(); LocalBlob out;
    require(CryptUnprotectData(&in, nullptr, v2 ? &extra : nullptr, nullptr, nullptr, CRYPTPROTECT_UI_FORBIDDEN, &out.data) != FALSE, "Save cannot be decrypted by this Windows user or is damaged");
    require(out.data.cbData == 32, "Invalid protected key");
    key.bytes.assign(out.data.pbData, out.data.pbData + out.data.cbData);
}
void decrypt(const Bytes& data, Secret& plain) {
    require(data.size() >= 14, "Truncated encrypted save");
    const bool v2 = std::memcmp(data.data(), magic, 8) == 0;
    const bool v1 = std::memcmp(data.data(), "BBCRSAV1", 8) == 0;
    require((v2 && data[8] == 2) || (v1 && data[8] == 1), "Unsupported encrypted save format");
    require(data[9] == 1, "Unsupported save protection scope");
    const size_t wrapped_len = get32(data, 10);
    require(wrapped_len > 0 && wrapped_len <= max_wrapped, "Invalid protected key length");
    const size_t key_offset = v2 ? 30 : 14;
    const size_t header_len = key_offset + wrapped_len + (v2 ? 0 : 16);
    const size_t tag_len = v2 ? 16 : 32;
    require(data.size() >= header_len + tag_len, "Truncated encrypted save payload");
    const size_t cipher_len = data.size() - header_len - tag_len;
    require(cipher_len <= max_plain + 16, "Save payload is oversized");
    Bytes wrapped(data.begin() + key_offset, data.begin() + key_offset + wrapped_len);
    Secret raw; unwrap(wrapped, raw, v2);
    Algorithm alg; Key key; aes_open(alg, key, raw.bytes, v2);
    ULONG actual{}; plain.bytes.resize(cipher_len + 16);
    if (v2) {
        require(get32(data, 14) == cipher_len && cipher_len <= max_plain, "Save payload length mismatch");
        BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO auth; BCRYPT_INIT_AUTH_MODE_INFO(auth);
        auth.pbNonce = const_cast<PUCHAR>(data.data() + 18); auth.cbNonce = 12;
        auth.pbAuthData = const_cast<PUCHAR>(data.data()); auth.cbAuthData = static_cast<ULONG>(header_len);
        auth.pbTag = const_cast<PUCHAR>(data.data() + header_len + cipher_len); auth.cbTag = 16;
        nt(BCryptDecrypt(key.h, const_cast<PUCHAR>(data.data() + header_len), static_cast<ULONG>(cipher_len), &auth, nullptr, 0, plain.bytes.data(), static_cast<ULONG>(plain.bytes.size()), &actual, 0), "Save authentication failed");
    } else {
        // Read-only compatibility with the earlier local PowerShell prototype.
        Algorithm hash; nt(BCryptOpenAlgorithmProvider(&hash.h, BCRYPT_SHA256_ALGORITHM, nullptr, BCRYPT_ALG_HANDLE_HMAC_FLAG), "HMAC unavailable");
        Bytes expected(32);
        nt(BCryptHash(hash.h, raw.bytes.data(), 32, const_cast<PUCHAR>(data.data()), static_cast<ULONG>(data.size() - 32), expected.data(), 32), "HMAC failed");
        unsigned difference = 0;
        for (size_t i = 0; i < 32; ++i) difference |= expected[i] ^ data[data.size() - 32 + i];
        require(difference == 0 && cipher_len > 0 && cipher_len % 16 == 0, "Save authentication failed");
        Bytes iv(data.begin() + 14 + wrapped_len, data.begin() + header_len);
        nt(BCryptDecrypt(key.h, const_cast<PUCHAR>(data.data() + header_len), static_cast<ULONG>(cipher_len), nullptr, iv.data(), 16, plain.bytes.data(), static_cast<ULONG>(plain.bytes.size()), &actual, BCRYPT_BLOCK_PADDING), "Legacy save decryption failed");
    }
    // Wipe unused decrypted padding before shortening the allocation.
    SecureZeroMemory(plain.bytes.data() + actual, plain.bytes.size() - actual); plain.bytes.resize(actual);
    text_valid(std::string_view(reinterpret_cast<const char*>(plain.bytes.data()), plain.bytes.size()));
}
Bytes encrypt(std::string_view text) {
    text_valid(text); Secret raw(32); random(raw.bytes);
    auto extra = entropy(); DATA_BLOB in{32, raw.bytes.data()}; LocalBlob wrapped;
    require(CryptProtectData(&in, L"BBCRForGM user save", &extra, nullptr, nullptr, CRYPTPROTECT_UI_FORBIDDEN, &wrapped.data) != FALSE, "Windows user key protection failed");
    require(wrapped.data.cbData <= max_wrapped, "Protected key is oversized");
    Bytes result(magic, magic + 8); result.push_back(2); result.push_back(1);
    u32(result, wrapped.data.cbData); u32(result, text.size());
    Bytes nonce(12); random(nonce); result.insert(result.end(), nonce.begin(), nonce.end());
    result.insert(result.end(), wrapped.data.pbData, wrapped.data.pbData + wrapped.data.cbData);
    const size_t header_len = result.size(); result.resize(header_len + text.size() + 16);
    Algorithm alg; Key key; aes_open(alg, key, raw.bytes, true);
    BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO auth; BCRYPT_INIT_AUTH_MODE_INFO(auth);
    auth.pbNonce = result.data() + 18; auth.cbNonce = 12;
    auth.pbAuthData = result.data(); auth.cbAuthData = static_cast<ULONG>(header_len);
    auth.pbTag = result.data() + header_len + text.size(); auth.cbTag = 16;
    ULONG actual{};
    nt(BCryptEncrypt(key.h, reinterpret_cast<PUCHAR>(const_cast<char*>(text.data())), static_cast<ULONG>(text.size()), &auth, nullptr, 0, result.data() + header_len, static_cast<ULONG>(text.size()), &actual, 0), "Save encryption failed");
    require(actual == text.size(), "Encrypted payload length mismatch");
    return result;
}
void atomic_save(const std::wstring& path, const Bytes& data, std::string_view text) {
    // No plaintext temporary files. Keep the previous save until verification succeeds.
    Bytes id(16); random(id); std::wstring tmp = path + L".tmp.";
    for (auto value : id) { tmp += L"0123456789abcdef"[value >> 4]; tmp += L"0123456789abcdef"[value & 15]; }
    File file(CreateFileW(tmp.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_NEW, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH, nullptr));
    require(file.h != INVALID_HANDLE_VALUE, "Cannot create encrypted save temporary file");
    try {
        DWORD actual{};
        require(WriteFile(file.h, data.data(), static_cast<DWORD>(data.size()), &actual, nullptr) && actual == data.size(), "Cannot write encrypted save");
        require(FlushFileBuffers(file.h) != FALSE, "Cannot flush encrypted save"); file.close();
        Secret check; decrypt(read_file(tmp), check);
        require(check.bytes.size() == text.size() && std::memcmp(check.bytes.data(), text.data(), text.size()) == 0, "Encrypted save read-back verification failed");
        if (exists(path)) require(ReplaceFileW(path.c_str(), tmp.c_str(), nullptr, 0, nullptr, nullptr) != FALSE, "Cannot atomically replace save; original retained");
        else require(MoveFileExW(tmp.c_str(), path.c_str(), MOVEFILE_WRITE_THROUGH) != FALSE, "Cannot commit new encrypted save");
    } catch (...) { file.close(); DeleteFileW(tmp.c_str()); throw; }
}
}

std::string bbcr_save_crypto_version() { return "BBCRSAV2 / Windows CurrentUser DPAPI / AES-256-GCM"; }
std::int32_t bbcr_save_crypto_status() { return status; }
std::string bbcr_save_crypto_error() { return last_error; }
std::string bbcr_save_crypto_read(std::string_view path) {
    begin();
    try {
        const auto name = wide(path);
        if (!exists(name)) { status = 0; return {}; }
        Secret plain; decrypt(read_file(name), plain); status = 1;
        return std::string(reinterpret_cast<const char*>(plain.bytes.data()), plain.bytes.size());
    } catch (const std::exception& e) { failed(e); return {}; }
}
std::int32_t bbcr_save_crypto_write(std::string_view path, std::string_view text) {
    begin();
    try {
        const auto name = wide(path); text_valid(text);
        File lock(CreateFileW((name + L".lock").c_str(), GENERIC_READ | GENERIC_WRITE, 0, nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_DELETE_ON_CLOSE, nullptr));
        require(lock.h != INVALID_HANDLE_VALUE, "Save is busy or directory is unavailable");
        if (exists(name)) { Secret previous; decrypt(read_file(name), previous); }
        atomic_save(name, encrypt(text), text); status = 1; return 1;
    } catch (const std::exception& e) { failed(e); return 0; }
}
