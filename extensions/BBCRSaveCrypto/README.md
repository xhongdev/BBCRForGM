# BBCRSaveCrypto

Windows x64 save extension. `source/save_crypto.gmidl` defines the API;
YoYoGames GM-ExtensionGenerator emits the bridge and extension declarations.
Implementation: `source/src/native/BBCRSaveCrypto_native.cpp`.
Regenerate/build with `python tools/build_crypto.py` from the project root.
Generated `code_gen`, GML bindings and root CMake files are not manually edited.

## API

- `bbcr_save_crypto_write(path, text)`: UTF-8 text to authenticated file, 1 success / 0 failure.
- `bbcr_save_crypto_read(path)`: decrypted UTF-8 text or empty string on missing/error.
- `bbcr_save_crypto_status()`: 1 success / 0 missing / -1 failure; check immediately after read.
- `bbcr_save_crypto_error()`: diagnostic for the last failed operation.
- `bbcr_save_crypto_version()`: implementation/format description.

The primitive native functions are exported directly by generated wrappers, so
the GameMaker ExtensionCore runtime is not required. All exceptions are handled
inside the implementation. Paths support UTF-8, including non-ASCII Windows names.
Use the GML save layer for application-level validation and migration.

## Version 2 Format

All integers are unsigned little-endian. Offsets:

| Offset | Contents |
| --- | --- |
| 0 | ASCII `BBCRSAV2` (8 bytes) |
| 8 | version 2 (1 byte) |
| 9 | CurrentUser scope 1 (1 byte) |
| 10 | DPAPI-wrapped key length (4 bytes) |
| 14 | ciphertext length (4 bytes) |
| 18 | random nonce (12 bytes) |
| 30 | DPAPI-wrapped random AES key |
| after key | AES-256-GCM ciphertext |
| after ciphertext | GCM tag (16 bytes) |

AAD is the complete header through the wrapped key. Windows system RNG produces
each new 32-byte key and 12-byte nonce. DPAPI uses CurrentUser, UI_FORBIDDEN and
the public application-specific entropy label `BBCRForGM/save/v2/current-user`.
This label is domain separation, not a secret. Payload limit is 1 MiB; wrapped
key limit is 16 KiB. Authentication completes before plaintext is returned.
The earlier local v1 AES-CBC/HMAC format is accepted only for reading.

Writes use a same-directory encrypted temporary file, flush/read-back/decrypt
verification, then `ReplaceFileW` or `MoveFileExW`. An unreadable existing file
is never replaced. Errors retain the old file and remove temporary output.
No plaintext temporary files are created. INI plaintext exists in application
memory while the game is running; keys/native temporary plaintext are wiped on
scope exit, but GML strings and generated return-string storage are not secure
memory containers.

No cross-device recovery, anti-rollback counter or multi-session merge is
implemented. This protects stored data, not data from the same logged-in user
or from a modified executable.
