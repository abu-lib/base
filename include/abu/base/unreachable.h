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

#ifndef ABU_BASE_UNREACHABLE_H_INCLUDED
#define ABU_BASE_UNREACHABLE_H_INCLUDED

namespace abu::base {

// Indicates that code cannot be reached.
#ifdef _MSC_VER

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wlanguage-extension-token"
#endif

[[noreturn]] inline __forceinline void unreachable() noexcept {
  __assume(false);
}

#ifdef __clang__
#pragma clang diagnostic pop
#endif

#elif defined(__GNUC__)

[[noreturn]] inline void unreachable() noexcept __attribute__((always_inline));

[[noreturn]] inline void unreachable() noexcept {
  __builtin_unreachable();
}
#else
[[noreturn]] inline void unreachable() noexcept {}
#endif

}  // namespace abu::base

#endif