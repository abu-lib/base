cmake_minimum_required(VERSION 3.16)
project(abu_base VERSION 0.1.2)

# Include the utilities needed by dependant projects
# This is not just for the sake of this file.
# everything in that .cmake is meant to also be used by individual libraries.
include(cmake/abu_lib.cmake)

abu_install_library_boilerplate()
enable_testing()

# CPP support library.
abu_add_library(
  SRC
    src/abu/base/check.cpp
  PUBLIC_HEADERS
    abu/base/check.h
    abu/base/source_location.h
    abu/base/unreachable.h
    abu/base.h
  TESTS
    tests/test_check.cpp
)

foreach(tgt ${abu_base_targets})
  target_compile_features(${tgt} PUBLIC cxx_std_20)
endforeach()