// Copyright 2021 Francois Chabot
//
// Licensed under the Apache License, Version 2.0 (the "License")
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

#ifndef ABU_BASE_CHECK_H_INCLUDED
#define ABU_BASE_CHECK_H_INCLUDED

#include <string_view>
#include <type_traits>

#include "abu/base/source_location.h"
#include "abu/base/unreachable.h"

namespace abu::base {

namespace details_ {

[[noreturn]] void handle_failed_check(std::string_view msg,
                                      std::uint_least32_t line,
                                      std::uint_least32_t column,
                                      const char* file_name,
                                      const char* function_name) noexcept;

}  // namespace details_

struct ignore_tag_t {};
struct assume_tag_t {};
struct verify_tag_t {};

static constexpr ignore_tag_t ignore;
static constexpr assume_tag_t assume;
static constexpr verify_tag_t verify;

namespace details_ {
inline void constexpr_check_failure() {
  // Invoking this function in constexpr code causes a usefull build error.
}
}  // namespace details_

constexpr void check(
    ignore_tag_t,
    bool condition,
    std::string_view = "",
    const source_location& = source_location::current()) noexcept {
  if (std::is_constant_evaluated() && !condition) {
    details_::constexpr_check_failure();
  }
}

constexpr void check(
    assume_tag_t,
    bool condition,
    std::string_view = "",
    const source_location& = source_location::current()) noexcept {
  if (std::is_constant_evaluated() && !condition) {
    details_::constexpr_check_failure();
  }

  if (!condition) {
    unreachable();
  }
}

constexpr void check(
    verify_tag_t,
    bool condition,
    std::string_view msg = "",
    const source_location& location = source_location::current()) noexcept {
  if (std::is_constant_evaluated() && !condition) {
    details_::constexpr_check_failure();
  }

  if (!condition) {
    details_::handle_failed_check(msg,
                                  location.line(),
                                  location.column(),
                                  location.file_name(),
                                  location.function_name());
  }
}
}  // namespace abu::base

#endif