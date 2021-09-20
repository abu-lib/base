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

#include "abu/base.h"
#include "gtest/gtest.h"

using namespace abu;

constexpr int foo_1(int x) {
  abu::base::check(abu::base::ignore, x < 10);
  return x;
}

constexpr int foo_2(int x) {
  abu::base::check(abu::base::assume, x < 10);
  return x;
}

constexpr int foo_3(int x) {
  abu::base::check(abu::base::verify, x < 10);
  return x;
}

template <auto Func, auto... Args>
constexpr int wrapper() {
  (void)Func(Args...);
  return 0;
}

template <auto Func, auto... Args>
concept FailsConstexpr = requires {
  typename std::integral_constant<int, wrapper<Func, Args...>()>;
};

static_assert(FailsConstexpr<foo_1, 5>);
static_assert(FailsConstexpr<foo_2, 5>);
static_assert(FailsConstexpr<foo_3, 5>);
static_assert(!FailsConstexpr<foo_1, 12>);
static_assert(!FailsConstexpr<foo_2, 12>);
static_assert(!FailsConstexpr<foo_3, 12>);

TEST(base, ignore) {
  base::check(abu::base::ignore, true);
  base::check(abu::base::ignore, true, "With a message");
  base::check(abu::base::ignore, false, "With a message");
}

TEST(base, assume) {
  base::check(abu::base::assume, true);
  base::check(abu::base::assume, true, "With a message");

  // This is actually UB...
  // base::check(abu::base::ignore, false, "With a message");
}

TEST(base, verify) {
  base::check(abu::base::verify, true);
  base::check(abu::base::verify, "With a message");

  EXPECT_DEATH(base::check(abu::base::verify, false), "");
  EXPECT_DEATH(base::check(abu::base::verify, false, "With a message"),
               "With a message");
  // Invoking base::assume<validated>(false) is UB
}
