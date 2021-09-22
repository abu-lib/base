include(FetchContent)

SET(ABU_COVERAGE OFF CACHE BOOL "Creates coverage report from tests")  
SET(ABU_TEST_ALL OFF CACHE BOOL "Build all abu test targets")
SET(ABU_HEADER_CHECKS OFF CACHE BOOL "Build abu header checks")

set(abu_base_cmake_location ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "")

function(abu_add_standard_compilation_flags_ TGT)
  if(MSVC)
    target_compile_options(${TGT} PRIVATE /WX /W4)
  else()
    target_compile_options(${TGT} PRIVATE -Wall -Werror -pedantic)
  endif()
endfunction()


function(abu_fetch_gbench_if_needed_)
  if (NOT TARGET benchmark::benchmark)
    find_package(benchmark 1.6 QUIET)
  endif()

  if (NOT TARGET benchmark::benchmark)
    message(STATUS "Fetching benchmark library from github repo")
    list(APPEND CMAKE_MESSAGE_INDENT "  ")
    FetchContent_Declare(
        googlebench
        GIT_REPOSITORY https://github.com/google/benchmark.git
        GIT_TAG        v1.6.0
      )
    set(BENCHMARK_ENABLE_TESTING OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googlebench)
    list(POP_BACK CMAKE_MESSAGE_INDENT)
  endif()
endfunction()

function(abu_fetch_gtest_if_needed_)

  if (NOT TARGET GTest::gtest_main)
    find_package(GTest 1.11 QUIET)
  endif()

  if (NOT TARGET GTest::gtest_main)
      message(STATUS "fetching GTest from github repo")
      list(APPEND CMAKE_MESSAGE_INDENT "  ")
      FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG        release-1.11.0
      )

      option(INSTALL_GTEST "Install gtest" OFF)
      set(INSTALL_GTEST OFF)
      FetchContent_MakeAvailable(googletest)
      list(POP_BACK CMAKE_MESSAGE_INDENT)
  endif()
endfunction()

function(abu_create_test_target)
  cmake_parse_arguments(ABU_CTT "" "LIB" "SRC" ${ARGN})

  set(TEST_TGT ${PROJECT_NAME}_tests)
        
  add_executable(${TEST_TGT}
    ${ABU_CTT_SRC}
  )

  target_link_libraries(${TEST_TGT} PRIVATE ${ABU_CTT_LIB})

  if(ABU_COVERAGE)
    target_compile_options(${TEST_TGT} PRIVATE --coverage)
    target_link_options(${TEST_TGT} PRIVATE --coverage)

    if (NOT TARGET abu_coverage_report)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/abu_coverage_report)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/abu_coverage_report/html)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/abu_coverage_report/sonarqube)
    add_custom_target(abu_coverage_report
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
      COMMAND 
        gcovr --gcov-executable gcov-11 -e .*gtest.* -e .*tests.* --sonarqube abu_coverage_report/sonarqube/coverage.xml --html abu_coverage_report/html/index.html --html-details -r ${CMAKE_SOURCE_DIR}
      COMMENT "Building coverage report"
    )
  endif()
  endif()

  target_link_libraries(${TEST_TGT} PRIVATE GTest::gtest GTest::gtest_main)
  abu_add_standard_compilation_flags_(${TEST_TGT})
  message(STATUS "registering test: ${TEST_TGT}" )
  add_test(${TEST_TGT} ${TEST_TGT})
endfunction()

# get_cmake_property(_variableNames VARIABLES)
# list (SORT _variableNames)
# foreach (_variableName ${_variableNames})
#     message(STATUS "${_variableName}=${${_variableName}}")
# endforeach()

function(abu_create_header_check_target)
  cmake_parse_arguments(ABU_HCT "" "" "PUBLIC_HEADERS" ${ARGN})
  
  set(SRC "")
  set(TMPL ${abu_base_cmake_location}/header_check.cpp.in)
    
  foreach(header ${ABU_HCT_PUBLIC_HEADERS})
    configure_file(${TMPL} ${CMAKE_BINARY_DIR}/abu_header_checks/${header}.cpp)
    LIST(APPEND SRC ${CMAKE_BINARY_DIR}/abu_header_checks/${header}.cpp)
  endforeach()

  add_library(${PROJECT_NAME}_header_checks ${SRC})
  abu_add_standard_compilation_flags_(${PROJECT_NAME}_header_checks)
  target_link_libraries(${PROJECT_NAME}_header_checks ${PROJECT_NAME})

endfunction()

function(abu_add_library)
  cmake_parse_arguments(ABU_AL "" "" "SRC;DEPENDS;TESTS;BENCHMARKS;PUBLIC_HEADERS" ${ARGN})

  if(NOT DEFINED ${PROJECT_NAME}_master_project)
    if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
        message(STATUS "${PROJECT_NAME} built as master project")
        set(${PROJECT_NAME}_master_project ON)
    else()
        set(${PROJECT_NAME}_master_project OFF)
    endif()
  endif()


  ###### Figure out the name and version of the library
  string(REGEX MATCH "^abu_([^@]+)$" PROJECT_NAME_MATCH ${PROJECT_NAME})
  if(NOT ${PROJECT_NAME_MATCH} STREQUAL ${PROJECT_NAME})
    message(FATAL_ERROR "abu library projects should be named \"abu_[name]\", ${PROJECT_NAME} is not.")
  endif()

  set(lib_name ${CMAKE_MATCH_1})

  set(lib abu_${lib_name})
  set(lib_c abu_${lib_name}_checked)
  set(lib_cr abu_${lib_name}_checked_recur)

  set(abu_${lib_name}_targets ${lib} ${lib_c} ${lib_cr} PARENT_SCOPE)

  message(STATUS "${lib} is @ ${PROJECT_VERSION}")

  set(abu_${lib_name}_VERSION ${PROJECT_VERSION} CACHE INTERNAL "")
  set(abu_${lib_name}_VERSION_MAJOR ${PROJECT_VERSION_MAJOR} CACHE INTERNAL "")
  set(abu_${lib_name}_VERSION_MINOR ${PROJECT_VERSION_MINOR} CACHE INTERNAL "")
  set(abu_${lib_name}_VERSION_PATCH ${PROJECT_VERSION_PATCH} CACHE INTERNAL "")
  set(abu_${lib_name}_VERSION_TWEAK ${PROJECT_VERSION_TWEAK} CACHE INTERNAL "")

  list(APPEND CMAKE_MESSAGE_INDENT "  ")

  ###### Build the library targets proper:
  if(ABU_AL_SRC)    
    set(mode PUBLIC)
    add_library(${lib} ${ABU_AL_SRC})
    add_library(${lib_c} ${ABU_AL_SRC})
    add_library(${lib_cr} ${ABU_AL_SRC})

    if(ABU_COVERAGE)
      target_compile_options(${lib} PRIVATE --coverage)
      target_compile_options(${lib_c} PRIVATE --coverage)
      target_compile_options(${lib_cr} PRIVATE --coverage)
      target_compile_definitions(${lib} PUBLIC ABU_COVERAGE)
      target_compile_definitions(${lib_c} PUBLIC ABU_COVERAGE)
      target_compile_definitions(${lib_cr} PUBLIC ABU_COVERAGE)
    endif()

    abu_add_standard_compilation_flags_(${lib})
    abu_add_standard_compilation_flags_(${lib_c})
    abu_add_standard_compilation_flags_(${lib_cr})
  else()
    set(mode INTERFACE)
    add_library(${lib} INTERFACE)
    add_library(${lib_c} INTERFACE)
    add_library(${lib_cr} INTERFACE)
  endif()

  add_library(abu::${lib_name} ALIAS ${lib})
  add_library(abu::checked::${lib_name} ALIAS ${lib_c})
  add_library(abu::checked_recur::${lib_name} ALIAS ${lib_cr})

  target_include_directories(${lib} ${mode} 
    "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
  )

  target_include_directories(${lib_c} ${mode} 
    "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
  )

  target_include_directories(${lib_cr} ${mode} 
    "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
  )

  # Add header checks if appropriate
  if(ABU_AL_PUBLIC_HEADERS AND ABU_HEADER_CHECKS)
    abu_create_header_check_target(PUBLIC_HEADERS ${ABU_AL_PUBLIC_HEADERS})
  endif()

  ###### Deal with dependencies  
  set(dep_list "")
  set(dep_list_cr "")

  foreach(DEP_STR ${ABU_AL_DEPENDS})
    string(REGEX MATCH "^([^@]+)>=([^@]+)$"
        DEP_MATCH ${DEP_STR})

    if(NOT ${DEP_MATCH} STREQUAL ${DEP_STR})
      message(SEND_ERROR "${DEP_STR} badly formatted abu dependency")
      continue()
    endif()

    set(dep_name ${CMAKE_MATCH_1})
    set(dep_version ${CMAKE_MATCH_2})

    set(dep_msg "needs ${dep_name} >= ${dep_version}:")

    set(dep_tgt abu_${dep_name})
    set(dep_tgt_c abu_${dep_name}_checked)
    set(dep_tgt_cr abu_${dep_name}_checked_recur)

    if(NOT TARGET ${dep_tgt})
      message(STATUS "${dep_msg} fetching from ${ABU_REPO_PREFIX}${dep_name}.git")
      FetchContent_Declare(${dep_tgt}
        GIT_REPOSITORY ${ABU_REPO_PREFIX}${dep_name}.git 
        GIT_TAG ${dep_version}
      )
      FetchContent_MakeAvailable(${dep_tgt})
    else()
      set(loaded_ver ${abu_${dep_name}_VERSION})
      message(STATUS "${dep_msg} found @ ${abu_${dep_name}_VERSION}")
      if(${loaded_ver} VERSION_LESS ${dep_version})
        message(FATAL_ERROR "bad abu dependency")
      endif()
    endif()

    LIST(APPEND dep_list ${dep_tgt})
    LIST(APPEND dep_list_cr ${dep_tgt_cr})
    
  endforeach()

  target_link_libraries(${lib} ${mode} ${dep_list})
  target_link_libraries(${lib_c} ${mode} ${dep_list})
  target_link_libraries(${lib_cr} ${mode} ${dep_list_cr})



  # Add the test target if appropriate
  if(ABU_AL_TESTS)
    if( ${${PROJECT_NAME}_master_project} OR ${ABU_TEST_ALL})
      set(test_default_value ON)
    else()
      set(test_default_value OFF)
    endif()
    set(${PROJECT_NAME}_build_tests ${test_default_value} CACHE BOOL "")

    if(${PROJECT_NAME}_build_tests)
      enable_testing()
      abu_fetch_gtest_if_needed_()

      abu_create_test_target(LIB ${lib_c} SRC ${ABU_AL_TESTS})
    endif()
  endif()

  # Add the benchmark target if appropriate
  if(ABU_AL_BENCHMARKS)
    SET(ABU_BENCHMARKS OFF CACHE BOOL "Benchmark abu libraries")
    if(ABU_BENCHMARKS)
      abu_fetch_gbench_if_needed_()

      add_executable(${PROJECT_NAME}_benchmarks
        ${ABU_AL_BENCHMARKS}
      )

      target_link_libraries(${PROJECT_NAME}_benchmarks PRIVATE abu::mem benchmark::benchmark)
      abu_add_standard_compilation_flags_(${PROJECT_NAME}_benchmarks)
    endif()
  endif()

  # Install targets
  if(ABU_INSTALL)
    install(
      DIRECTORY include/
      DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )

    install(TARGETS ${lib} ${lib_c} ${lib_cr}
      EXPORT abu
        RUNTIME DESTINATION ${ABU_INSTALL_BINDIR}
        ARCHIVE DESTINATION ${ABU_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${ABU_INSTALL_LIBDIR}
    )
  endif()
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endfunction()




