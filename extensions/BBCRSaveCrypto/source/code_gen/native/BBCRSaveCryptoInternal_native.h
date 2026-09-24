// ##### extgen :: Auto-generated file do not edit!! #####

#pragma once
#include <cstdint>
#include <string_view>
#include <vector>
#include <array>
#include <optional>
#include "core/GMExtWire.h"

namespace gm_consts
{
}


namespace gm_enums
{
}


namespace gm_structs
{

}

namespace gm::wire::codec
{
}

namespace gm::wire::details
{
}

std::string bbcr_save_crypto_version();
std::int32_t bbcr_save_crypto_write(std::string_view path, std::string_view text);
std::string bbcr_save_crypto_read(std::string_view path);
std::int32_t bbcr_save_crypto_status();
std::string bbcr_save_crypto_error();
