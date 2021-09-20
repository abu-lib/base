# Abu Base

[![CI](https://github.com/abu-lib/base/actions/workflows/ci.yml/badge.svg)](https://github.com/abu-lib/base/actions/workflows/ci.yml)

This is part of the [Abu](http://github.com/abu-lib/abu) meta-project.

Common utilities used by all abu libraries

## check

Replaces assert with:

- More granularity.
- More guarantees.
  - Code is never stripped out, just optimized away.
  - Checks are always performed during constexpr evaluation.
- More performance: Disabled checks can be turned into compiler hints.

### Usage

```cpp
namespace abu::debug {
  struct ignore_tag_t {};
  struct assume_tag_t {};
  struct verify_tag_t {};

  static constexpr ignore_tag_t ignore;
  static constexpr assume_tag_t assume;
  static constexpr verify_tag_t verify;

  template<typename BehaviorTag>
  constexpr void check(
    BehaviorTag,
    bool condition,
    std::string_view msg = "",
    const source_location& location = source_location::current()) noexcept;

  [[noreturn]] constexpr void unreachable() noexcept;
}
```

Note: Checks are always performed in manifestly constexpr contexts, regardless of the chosen behavior.

Unlike `assert()`, there is no one-size-fit-all behavior selection logic for 
`check()`. Different modules often want to use different logic to determine 
which checks to perform. 

For example, in a library, we will generally want to perform aggressive internal
assertions in testing builds, and maintain precondition checks for user debug builds.

As such, `check()` is not really meant to be invoked directly from code, but instead
contextually wrapped. A typical setup looks like this.

```cpp
// my_code/debug.h

// MY_CODE_ASSUMPTIONS is set to validate as a compiler flag in the appropriate builds.
#ifndef MY_CODE_ASSUMPTIONS
#define MY_CODE_ASSUMPTIONS assume
#endif

#ifndef MY_CODE_PRECONDITIONS
  #ifdef NDEBUG
    #define MY_CODE_PRECONDITIONS assume
  #else
    #define MY_CODE_PRECONDITIONS verify
  #endif
#endif

#include "abu/debug.h"

namespace my_code {

inline constexpr void assume(
    bool condition, 
    std::string_view msg={}
    abu::debug::source_location loc = abu::debug::source_location::current()) noexcept {
  return abu::debug::check(abu::debug::MY_CODE_ASSUMPTIONS, condition, msg, loc);
} 

inline constexpr void precondition(
    bool condition, 
    std::string_view msg={},
    abu::debug::source_location loc = abu::debug::source_location::current()) noexcept {
  return abu::debug::check(abu::debug::MY_CODE_PRECONDITIONS, condition, msg, loc);
} 
}
```

```cpp
// my_code/source.cpp
#include <string>
#include <variant>

#include "my_code/debug.h"

namespace my_code {
void int_to_float(std::variant<std::string, int, float>& v) {
    precondition(v.index() == 1, "v must be an int here");

    v = 12.5f;
    assume(v.index() == 2);
}
}
```

## CMake tooling

A typicial abu library project loosk like this:
```cmake
cmake_minimum_required(VERSION 3.16)
project(abu_<lib_name> VERSION 0.2.1)

# Boilerplate to access common build utilities
set(ABU_REPO_PREFIX https://github.com/abu-lib/ CACHE STRING "")
set(abu_base_ver 0.1.0)
if(NOT TARGET abu_base)
  message(STATUS "abu_base not found, fetching it from ${ABU_REPO_PREFIX}base.git")
    include(FetchContent)
  FetchContent_Declare(abu_base
    GIT_REPOSITORY ${ABU_REPO_PREFIX}base.git 
    GIT_TAG ${abu_base_ver}
  )
  FetchContent_MakeAvailable(abu_base)
endif()
# Boilerplate end


abu_add_library(
  DEPENDS
    base>=${abu_base_ver}
    mem>=0.3.2
  SRC
    src/some_code.cpp
  TESTS
    tests/some_kind_of_test.cpp
    tests/some_other_test.cpp
  BENCHMARKS
    benchmarks/some_benchmarks.cpp
    benchmarks/some_more_benchmarks.cpp
)

foreach(tgt ${PROJECT_NAME}_targets)
  target_link_libraries(${tgt} PUBLIC external_target)
endforeach()

target_compile_definitions(${PROJECT_NAME}_checked SOME_DEFINITION)
target_compile_definitions(${PROJECT_NAME}_checked_recur SOME_DEFINITION)
```

Notes:
- `${PROJECT_NAME}_targets` contains the list of created library targets
- Currently, three targets are produced
  - ${PROJECT_NAME}               : The library with assumptions
  - ${PROJECT_NAME}_checked       : The library with assumptions, depending on libraries without assumptions
  - ${PROJECT_NAME}_checked_recur : The library with assumptions, depending on libraries with assumptions
- Preconditions are always checked in debug builds, and never in release builds.
- Only the `>=` dependency operator is supported fort the time being. 
- `SRC`, `TESTS`, and `BENCHMARKS` are all optional.
- If `SRC` is ommited or empty, the targets will be `INTERFACE` libraries
- The project name is always `abu_<library_name>`.
- The project will be downloaded from `{ABU_REPO_PREFIX}<library_name>`
- For the time being 