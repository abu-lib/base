// Copyright 2021 Francois Chabot
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef ABU_BASE_SOURCE_LOCATION_H_INCLUDED
#define ABU_BASE_SOURCE_LOCATION_H_INCLUDED

#include <cstdint>

#if __has_include(<source_location>)
#include <source_location>
#endif

namespace abu::base {

#ifdef __cpp_lib_source_location
using source_location = std::source_location;
#else
struct source_location {
  constexpr std::uint_least32_t line() const noexcept {
    return 0;
  }
  constexpr std::uint_least32_t column() const noexcept {
    return 0;
  };
  constexpr const char* file_name() const noexcept {
    return "";
  }
  constexpr const char* function_name() const noexcept {
    return "";
  }

  static constexpr source_location current() noexcept {
    return {};
  }
};
#endif

}  // namespace abu::base

#endif