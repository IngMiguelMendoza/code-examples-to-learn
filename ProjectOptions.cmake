include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(code_examples_to_learn_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(code_examples_to_learn_setup_options)
  option(code_examples_to_learn_ENABLE_HARDENING "Enable hardening" ON)
  option(code_examples_to_learn_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    code_examples_to_learn_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    code_examples_to_learn_ENABLE_HARDENING
    OFF)

  code_examples_to_learn_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR code_examples_to_learn_PACKAGING_MAINTAINER_MODE)
    option(code_examples_to_learn_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(code_examples_to_learn_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(code_examples_to_learn_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(code_examples_to_learn_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(code_examples_to_learn_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(code_examples_to_learn_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(code_examples_to_learn_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(code_examples_to_learn_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(code_examples_to_learn_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(code_examples_to_learn_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(code_examples_to_learn_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(code_examples_to_learn_ENABLE_PCH "Enable precompiled headers" OFF)
    option(code_examples_to_learn_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(code_examples_to_learn_ENABLE_IPO "Enable IPO/LTO" ON)
    option(code_examples_to_learn_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(code_examples_to_learn_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(code_examples_to_learn_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(code_examples_to_learn_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(code_examples_to_learn_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(code_examples_to_learn_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(code_examples_to_learn_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(code_examples_to_learn_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(code_examples_to_learn_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(code_examples_to_learn_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(code_examples_to_learn_ENABLE_PCH "Enable precompiled headers" OFF)
    option(code_examples_to_learn_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      code_examples_to_learn_ENABLE_IPO
      code_examples_to_learn_WARNINGS_AS_ERRORS
      code_examples_to_learn_ENABLE_USER_LINKER
      code_examples_to_learn_ENABLE_SANITIZER_ADDRESS
      code_examples_to_learn_ENABLE_SANITIZER_LEAK
      code_examples_to_learn_ENABLE_SANITIZER_UNDEFINED
      code_examples_to_learn_ENABLE_SANITIZER_THREAD
      code_examples_to_learn_ENABLE_SANITIZER_MEMORY
      code_examples_to_learn_ENABLE_UNITY_BUILD
      code_examples_to_learn_ENABLE_CLANG_TIDY
      code_examples_to_learn_ENABLE_CPPCHECK
      code_examples_to_learn_ENABLE_COVERAGE
      code_examples_to_learn_ENABLE_PCH
      code_examples_to_learn_ENABLE_CACHE)
  endif()

  code_examples_to_learn_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (code_examples_to_learn_ENABLE_SANITIZER_ADDRESS OR code_examples_to_learn_ENABLE_SANITIZER_THREAD OR code_examples_to_learn_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(code_examples_to_learn_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(code_examples_to_learn_global_options)
  if(code_examples_to_learn_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    code_examples_to_learn_enable_ipo()
  endif()

  code_examples_to_learn_supports_sanitizers()

  if(code_examples_to_learn_ENABLE_HARDENING AND code_examples_to_learn_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR code_examples_to_learn_ENABLE_SANITIZER_UNDEFINED
       OR code_examples_to_learn_ENABLE_SANITIZER_ADDRESS
       OR code_examples_to_learn_ENABLE_SANITIZER_THREAD
       OR code_examples_to_learn_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${code_examples_to_learn_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${code_examples_to_learn_ENABLE_SANITIZER_UNDEFINED}")
    code_examples_to_learn_enable_hardening(code_examples_to_learn_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(code_examples_to_learn_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(code_examples_to_learn_warnings INTERFACE)
  add_library(code_examples_to_learn_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  code_examples_to_learn_set_project_warnings(
    code_examples_to_learn_warnings
    ${code_examples_to_learn_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(code_examples_to_learn_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    code_examples_to_learn_configure_linker(code_examples_to_learn_options)
  endif()

  include(cmake/Sanitizers.cmake)
  code_examples_to_learn_enable_sanitizers(
    code_examples_to_learn_options
    ${code_examples_to_learn_ENABLE_SANITIZER_ADDRESS}
    ${code_examples_to_learn_ENABLE_SANITIZER_LEAK}
    ${code_examples_to_learn_ENABLE_SANITIZER_UNDEFINED}
    ${code_examples_to_learn_ENABLE_SANITIZER_THREAD}
    ${code_examples_to_learn_ENABLE_SANITIZER_MEMORY})

  set_target_properties(code_examples_to_learn_options PROPERTIES UNITY_BUILD ${code_examples_to_learn_ENABLE_UNITY_BUILD})

  if(code_examples_to_learn_ENABLE_PCH)
    target_precompile_headers(
      code_examples_to_learn_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(code_examples_to_learn_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    code_examples_to_learn_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(code_examples_to_learn_ENABLE_CLANG_TIDY)
    code_examples_to_learn_enable_clang_tidy(code_examples_to_learn_options ${code_examples_to_learn_WARNINGS_AS_ERRORS})
  endif()

  if(code_examples_to_learn_ENABLE_CPPCHECK)
    code_examples_to_learn_enable_cppcheck(${code_examples_to_learn_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(code_examples_to_learn_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    code_examples_to_learn_enable_coverage(code_examples_to_learn_options)
  endif()

  if(code_examples_to_learn_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(code_examples_to_learn_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(code_examples_to_learn_ENABLE_HARDENING AND NOT code_examples_to_learn_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR code_examples_to_learn_ENABLE_SANITIZER_UNDEFINED
       OR code_examples_to_learn_ENABLE_SANITIZER_ADDRESS
       OR code_examples_to_learn_ENABLE_SANITIZER_THREAD
       OR code_examples_to_learn_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    code_examples_to_learn_enable_hardening(code_examples_to_learn_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
