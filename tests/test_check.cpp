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

constexpr int expect_pass_val = 5;
constexpr int expect_fail_val = expect_pass_val + 1;


namespace {

constexpr int foo_1(int x) {
  abu::base::check(abu::base::ignore, x <= expect_pass_val);
  return x;
}

constexpr int foo_2(int x) {
  abu::base::check(abu::base::assume, x <= expect_pass_val);
  return x;
}

constexpr int foo_3(int x) {
  abu::base::check(abu::base::verify, x <= expect_pass_val);
  return x;
}

template <auto Func, auto... Args>
constexpr int wrapper() {
  (void)Func(Args...);
  return 0;
}

}

template <auto Func, auto... Args>
concept FailsConstexpr = requires {
  typename std::integral_constant<int, wrapper<Func, Args...>()>;
};

static_assert(FailsConstexpr<foo_1, expect_pass_val>);
static_assert(FailsConstexpr<foo_2, expect_pass_val>);
static_assert(FailsConstexpr<foo_3, expect_pass_val>);
static_assert(!FailsConstexpr<foo_1, expect_fail_val>);
static_assert(!FailsConstexpr<foo_2, expect_fail_val>);
static_assert(!FailsConstexpr<foo_3, expect_fail_val>);

TEST(base, ignore) {
  abu::base::check(abu::base::ignore, true);
  abu::base::check(abu::base::ignore, true, "With a message");
  abu::base::check(abu::base::ignore, false, "With a message");
}

TEST(base, assume) {
  abu::base::check(abu::base::assume, true);
  abu::base::check(abu::base::assume, true, "With a message");

  // This is actually UB...
  // base::check(abu::base::ignore, false, "With a message");
}

TEST(base, verify) {
  abu::base::check(abu::base::verify, true);
  abu::base::check(abu::base::verify, "With a message");

  EXPECT_DEATH(abu::base::check(abu::base::verify, false), "");
  EXPECT_DEATH(abu::base::check(abu::base::verify, false, "With a message"),
               "With a message");
  // Invoking base::assume<validated>(false) is UB
}
