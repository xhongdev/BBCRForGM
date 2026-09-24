// ##### extgen :: Auto-generated file do not edit!! #####

#include "BBCRSaveCryptoInternal_native.h"
#include "BBCRSaveCryptoInternal_exports.h"

using namespace gm_structs;
using namespace gm::wire::codec;

GMEXPORT char* __EXT_NATIVE__bbcr_save_crypto_version()
{
    static std::string __result;
    __result = bbcr_save_crypto_version();
    return (char*)__result.c_str();
}

GMEXPORT double __EXT_NATIVE__bbcr_save_crypto_write(char* path, char* text)
{
    auto&& __result = bbcr_save_crypto_write(path, text);
    return static_cast<double>(__result);
}

GMEXPORT char* __EXT_NATIVE__bbcr_save_crypto_read(char* path)
{
    static std::string __result;
    __result = bbcr_save_crypto_read(path);
    return (char*)__result.c_str();
}

GMEXPORT double __EXT_NATIVE__bbcr_save_crypto_status()
{
    auto&& __result = bbcr_save_crypto_status();
    return static_cast<double>(__result);
}

GMEXPORT char* __EXT_NATIVE__bbcr_save_crypto_error()
{
    static std::string __result;
    __result = bbcr_save_crypto_error();
    return (char*)__result.c_str();
}

