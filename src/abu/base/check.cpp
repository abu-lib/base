// Copyright 2021 Francois Chabot

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <cstdlib>
#include <iostream>

#include "abu/base.h"

namespace abu::base::details_ {

[[noreturn]] void handle_failed_check(std::string_view msg,
                                      std::uint_least32_t line,
                                      std::uint_least32_t column,
                                      const char* file_name,
                                      const char* function_name) noexcept {
  std::cerr << file_name << ":" << line << ":" << column << ": "
            << function_name << ": " << msg << '\n';
  std::abort();
}
}  // namespace abu::base::details_
