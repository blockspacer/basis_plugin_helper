# cmake utils

macro(set_common_plugin_options _PROJECT_NAME)
  if(NOT PROJECT_NAME)
    message(FATAL_ERROR
      "Project name must be specified!")
  endif(NOT PROJECT_NAME)

  set(PROJECT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

  string(TOLOWER "${CMAKE_BUILD_TYPE}" cmake_build_type_tolower)

  option(${_PROJECT_NAME}_BUILD_SHARED_LIBS
    "BUILD_SHARED_LIBS: Use .so/.dll" ${BUILD_SHARED_LIBS})

  if(BUILD_SHARED_LIBS AND (ENABLE_MSAN OR ENABLE_TSAN OR ENABLE_ASAN OR ENABLE_UBSAN))
    message(STATUS "sanitizers require static linking. Disable BUILD_SHARED_LIBS.")
  endif()

  # used by https://docs.conan.io/en/latest/developing_packages/workspaces.html
  get_filename_component(LOCAL_BUILD_ABSOLUTE_ROOT_PATH
    "${PACKAGE_basis_SRC}"
    ABSOLUTE)
  if(EXISTS "${LOCAL_BUILD_ABSOLUTE_ROOT_PATH}")
    # path to Find*.cmake file
    list(PREPEND CMAKE_MODULE_PATH "${LOCAL_BUILD_ABSOLUTE_ROOT_PATH}/cmake")
  endif()

  option(BUILD_DOXY_DOC
    "build doxygen documentation" OFF)

  option(ENABLE_LWYU
    "Enable CMAKE_LINK_WHAT_YOU_USE" OFF)
  if(ENABLE_LWYU)
    # Enable linker flags -r -u to create warnings for unused dependencies at link time.
    # Warning: Unused direct dependencies: '/usr/lib/libm.so.6' (required by std)
    # LWYU will modify the flags to ld to show any libraries
    # being linked into targets that are not contributing symbols
    # to the target being linked.
    # see https://cmake.org/cmake/help/latest/prop_tgt/LINK_WHAT_YOU_USE.html
    # NOTE: This is only applicable to executable and shared library targets
    set(CMAKE_LINK_WHAT_YOU_USE ON)
  endif(ENABLE_LWYU)

  option(ENABLE_TESTS "Enable tests" OFF)

  # see https://gitlab.kitware.com/cmake/community/wikis/FAQ#can-i-do-make-uninstall-with-cmake
  option(ENABLE_UNINSTALL
    "Enable uninstall (using install_manifest.txt)" OFF)

  option(ENABLE_CPPCHECK
    "Enable cppcheck" OFF)

  option(ENABLE_VALGRIND
    "Enable valgrind" OFF)

  option(ENABLE_CLANG_TIDY
    "Enable clang-tidy" OFF)

  option(ENABLE_CLANG_FORMAT
    "Enable clang-format" OFF)

  option(ENABLE_UNCRUSTIFY
    "Enable uncrustify" OFF)

  # Things that can catch OCLINT
  # http://oclint-docs.readthedocs.io/en/stable/rules/index.html
  # OCLINT command-line manual
  # https://oclint-docs.readthedocs.io/en/stable/manual/oclint.html
  option(ENABLE_OCLINT
    "Enable oclint" OFF)

  option(ENABLE_IWYU
    "Enable include-what-you-use" OFF)

  option(ENABLE_CPPCLEAN
    "Enable cppclean" OFF)

  option(ENABLE_LTO
    "Enable Link Time Optimization" OFF)

  option(USE_LD_GOLD
    "Use GNU gold linker" OFF)

  option(USE_CCACHE
    "Use CCACHE" OFF)

  option(USE_COVERAGE
    "Use CCACHE" OFF)

  # TODO: __do_global_dtors_aux, base::debug::CollectStackTrace
  option(ENABLE_VALGRIND_TESTS
    "Enable valgrind for unit tests" OFF)

  option(COMPILE_WITH_LLVM_TOOLS
    "Enable clang from llvm_tools (conan package)" OFF)

  # see https://github.com/Ericsson/codechecker/blob/master/tools/report-converter/README.md#undefined-behaviour-sanitizer
  # NOTE: Compile with -g and -fno-omit-frame-pointer
  # to get proper debug information in your binary.
  # NOTE: Run your program with environment variable UBSAN_OPTIONS=print_stacktrace=1.
  # see https://github.com/google/sanitizers/wiki/SanitizerCommonFlags
  option(ENABLE_UBSAN
    "Enable Undefined Behaviour Sanitizer" OFF)

  # see https://github.com/google/sanitizers/wiki/AddressSanitizerLeakSanitizer
  # see https://github.com/Ericsson/codechecker/blob/master/tools/report-converter/README.md#address-sanitizer
  # NOTE: Compile with -g and -fno-omit-frame-pointer
  # to get proper debug information in your binary.
  # NOTE: use ASAN_OPTIONS=detect_leaks=1 LSAN_OPTIONS=suppressions=suppr.txt
  # NOTE: You need the ASAN_OPTIONS=symbolize=1
  # to turn on resolving addresses in object code
  # to source code line numbers and filenames.
  # This option is implicit for Clang but it won't do any harm.
  # see https://github.com/google/sanitizers/wiki/SanitizerCommonFlags
  option(ENABLE_ASAN
    "Enable Address Sanitizer" OFF)

  # see https://github.com/Ericsson/codechecker/blob/master/tools/report-converter/README.md#memory-sanitizer
  # NOTE: Compile with -g and -fno-omit-frame-pointer
  # to get proper debug information in your binary.
  option(ENABLE_MSAN
    "Enable Memory Sanitizer" OFF)

  # see https://github.com/Ericsson/codechecker/blob/master/tools/report-converter/README.md#thread-sanitizer
  # NOTE: Compile with -g
  # to get proper debug information in your binary.
  option(ENABLE_TSAN
    "Enable Thread Sanitizer" OFF)

  set(ENABLE_CLING TRUE CACHE BOOL "ENABLE_CLING")
  message(STATUS "ENABLE_CLING=${ENABLE_CLING}")

  set(ENABLE_CLANG_FROM_CONAN FALSE CACHE BOOL "ENABLE_CLANG_FROM_CONAN")
  message(STATUS "ENABLE_CLANG_FROM_CONAN=${ENABLE_CLANG_FROM_CONAN}")

  if(ENABLE_CLANG_FROM_CONAN AND ENABLE_CLING)
    message(FATAL_ERROR
      "don't use both ENABLE_CLING and ENABLE_CLANG_FROM_CONAN at the same time. cling already provides clang libtooling")
  endif()

  set(CUSTOM_PLUGINS
      "${CMAKE_CURRENT_SOURCE_DIR}/custom_plugins.cmake"
      CACHE STRING
      "Path to custom plugins")
  message(STATUS "CUSTOM_PLUGINS=${CUSTOM_PLUGINS}")
  if(EXISTS ${CUSTOM_PLUGINS})
    include(${CUSTOM_PLUGINS})
  endif()
endmacro(set_common_plugin_options)

macro(set_common_plugin_modules)
  # CMake-provided scripts
  include(CPack)
  include(CTest)
  include(CheckCXXCompilerFlag)
  include(CheckSymbolExists)
  include(TestBigEndian)
  include(CheckIncludeFile)
  include(CheckLibraryExists)
  include(CMakePackageConfigHelpers)
  include(GNUInstallDirs)
  # Helper module for selecting option based on multiple values. Module help:
  # https://cmake.org/cmake/help/v3.10/module/CMakeDependentOption.html
  include(CMakeDependentOption)

  find_package(cmake_platform_detection REQUIRED)

  # populates variables with TRUE or FALSE:
  # PLATFORM_MOBILE | PLATFORM_WEB | PLATFORM_DESKTOP
  # | TARGET_EMSCRIPTEN | TARGET_LINUX | TARGET_WINDOWS | TARGET_MACOS
  # | TARGET_IOS | TARGET_ANDROID
  run_cmake_platform_detection() # from cmake_platform_detection (conan package)

  find_package(cmake_build_options REQUIRED)

  # set default cmake build type if CMAKE_BUILD_TYPE not set
  setup_default_build_type(RELEASE) # from cmake_build_options (conan package)

  # Limits possible values of CMAKE_BUILD_TYPE
  # Also populates variables with TRUE or FALSE:
  # RELEASE_BUILD | DEBUG_BUILD | PROFILE_BUILD
  # | MINSIZEREL_BUILD | RELWITHDEBINFO_BUILD | COVERAGE_BUILD
  # | DOCS_BUILD | TEST_BUILD
  setup_cmake_build_options(RELEASE DEBUG) # from cmake_build_options (conan package)

  message(STATUS "Compiler ${CMAKE_CXX_COMPILER}, version: ${CMAKE_CXX_COMPILER_VERSION}")

  set_project_version(${PROJECT_VERSION_MAJOR} ${PROJECT_VERSION_MINOR} ${PROJECT_VERSION_PATCH}) # from Utils.cmake

  # CMAKE_BUILD_TYPE must be not empty
  check_cmake_build_type_selected() # from Utils.cmake

  # beautify compiler output
  enable_colored_diagnostics() # from Utils.cmake

  # log cmake vars
  print_cmake_system_info() # from Utils.cmake

  # limit to known platforms
  check_supported_os() # from Utils.cmake

  find_package(cmake_helper_utils REQUIRED)

  # prefer ASCII for folder names
  force_latin_paths() # from cmake_helper_utils (conan package)

  # out dirs (CMAKE_*_OUTPUT_DIRECTORY) must be not empty
  validate_out_dirs() # from cmake_helper_utils (conan package)

  # In-source builds not allowed
  validate_out_source_build(WARNING) # from cmake_helper_utils (conan package)

  if(ENABLE_MSAN OR ENABLE_TSAN OR ENABLE_ASAN OR ENABLE_UBSAN)
    find_package(cmake_sanitizers REQUIRED)
  endif()

  if(ENABLE_MSAN)
    add_msan_flags()
  endif(ENABLE_MSAN)

  if(ENABLE_TSAN)
    add_tsan_flags()
  endif(ENABLE_TSAN)

  if(ENABLE_ASAN)
    add_asan_flags()
  endif(ENABLE_ASAN)

  if(ENABLE_UBSAN)
    add_ubsan_flags()
  endif(ENABLE_UBSAN)

  if(COMPILE_WITH_LLVM_TOOLS)
    # force change CMAKE_*_COMPILER and CMAKE_LINKER to clang from conan
    compile_with_llvm_tools() # from cmake_helper_utils (conan package)
  endif(COMPILE_WITH_LLVM_TOOLS)

  find_package(chromium_build_util REQUIRED)
  #
  if(TARGET chromium_build_util::chromium_build_util-static)
    set(build_util_LIB "chromium_build_util::chromium_build_util-static")
  else()
    message(FATAL_ERROR "not supported: using system provided chromium_build_util library")
  endif()

  find_package(chromium_base REQUIRED)
  if(NOT TARGET ${base_LIB})
    message(FATAL_ERROR "not supported: using system provided chromium_base library")
  endif()

  include(GNUInstallDirs)

  include(CMakePackageConfigHelpers)

  if (NOT DEFINED CMAKE_INSTALL_BINDIR)
    set(CMAKE_INSTALL_BINDIR "bin")
  endif()
  if (NOT DEFINED CMAKE_INSTALL_INCLUDEDIR)
    set(CMAKE_INSTALL_INCLUDEDIR "include")
  endif()
  if (NOT DEFINED CMAKE_INSTALL_LIBDIR)
    set(CMAKE_INSTALL_LIBDIR "lib")
  endif()

  # see https://doc.magnum.graphics/corrade/corrade-cmake.html#corrade-cmake-subproject
  find_package(Corrade REQUIRED PluginManager)

  if(NOT TARGET CONAN_PKG::corrade)
    message(FATAL_ERROR "Use corrade from conan")
  endif()

  find_package(basis REQUIRED)
  if(${basis_HEADER_DIR} STREQUAL "")
    message(FATAL_ERROR "unable to find basis_HEADER_DIR")
  endif()

  if(ENABLE_CLING)
    find_package(Cling REQUIRED)
  endif(ENABLE_CLING)

  # It is always easier to navigate in an IDE when projects are organized in folders.
  set_property(GLOBAL PROPERTY USE_FOLDERS ON)

  # NOTE: place after `find_package` calls
  set(COMMON_PLUGIN_LIBS
    ${base_LIB}
    ${build_util_LIB}
    ${basis_LIB}
    CONAN_PKG::boost
    CONAN_PKG::corrade
    Corrade::PluginManager
    ${USED_BOOST_LIBS}
    CONAN_PKG::entt
    CONAN_PKG::openssl
  )

  set(COMMON_PLUGIN_DEFINES
    # https://stackoverflow.com/a/30877725
    BOOST_SYSTEM_NO_DEPRECATED
    BOOST_ERROR_CODE_HEADER_ONLY
    BOOST_ASIO_STANDALONE=1
    BOOST_ASIO_HAS_MOVE=1
    # `type_index` requires `ENTT_MAYBE_ATOMIC` to be thread-safe.
    # `type_index` is used widely, for example in `registry` and `dispatcher`.
    # see github.com/skypjack/entt/issues/562
    ENTT_USE_ATOMIC=1
    DISABLE_DOCTEST=1 # TODO: DISABLE_DOCTEST
  )
endmacro(set_common_plugin_modules)

# $<INSTALL_INTERFACE:...> is exported using install(EXPORT)
# $<BUILD_INTERFACE:...> is exported using export(), or when the target is used by another target in the same buildsystem
macro(add_relative_include_dir TARGET TEST_LIB_NAME VISIBILITY_BUILD VISIBILITY_INSTALL NEW_ELEM)
  target_include_directories(${TARGET}
    ${VISIBILITY_BUILD} "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${NEW_ELEM}>"
    ${VISIBILITY_INSTALL} "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${CMAKE_INSTALL_INCLUDEDIR}/${NEW_ELEM}>"
  )
  target_include_directories( ${TEST_LIB_NAME} SYSTEM INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/${NEW_ELEM} )
endmacro(add_relative_include_dir)

macro(add_plugin_library _CONFIG_FILE_PATH _LIB_NAME _CORE_LIB_TYPE _SOURCES)
  if(NOT EXISTS ${_CONFIG_FILE_PATH})
    message(FATAL_ERROR "unable to find file: ${_CONFIG_FILE_PATH}")
  endif()

  if(${_CORE_LIB_TYPE} STREQUAL "STATIC")
    corrade_add_static_plugin(${_LIB_NAME}
      ${CMAKE_CURRENT_BINARY_DIR}
      ${_CONFIG_FILE_PATH}
      ${ARGN})
  elseif(${_CORE_LIB_TYPE} STREQUAL "SHARED")
    add_library(${_LIB_NAME} ${_CORE_LIB_TYPE}
      ${_SOURCES}
      ${ARGN}
    )
    target_compile_definitions(${_LIB_NAME} PRIVATE
      # see https://github.com/mosra/corrade/blob/af9d4216f07307a2dff471664eed1e50e180568b/modules/UseCorrade.cmake#L568
      CORRADE_DYNAMIC_PLUGIN=1
    )
  elseif(${_CORE_LIB_TYPE} STREQUAL "MODULE")
    message(FATAL_ERROR "add_plugin_library: unsupported library type")
  elseif(${_CORE_LIB_TYPE} STREQUAL "INTERFACE")
    message(FATAL_ERROR "add_plugin_library: unsupported library type")
  elseif(${_CORE_LIB_TYPE} STREQUAL "OBJECT")
    message(FATAL_ERROR "add_plugin_library: unsupported library type")
  else()
    message(FATAL_ERROR "add_plugin_library: unknown library type")
  endif()

  # Alias target be used outside of the project.
  add_library(${_LIB_NAME}::lib
    ALIAS ${_LIB_NAME})

  set_property(TARGET ${_LIB_NAME} PROPERTY CXX_STANDARD 17)

  if(TARGET_EMSCRIPTEN)
    # use PROPERTY CXX_STANDARD 17
  else()
    target_compile_features(${_LIB_NAME}
      PUBLIC cxx_auto_type
      PRIVATE cxx_variadic_templates)
  endif()

  # see https://cmake.org/cmake/help/v3.0/module/TestBigEndian.html
  test_big_endian(${_LIB_NAME}_IS_BIG_ENDIAN)
  if(${${_LIB_NAME}_IS_BIG_ENDIAN})
    target_compile_definitions(${_LIB_NAME} PUBLIC
      IS_BIG_ENDIAN=1
    )
  endif()

  if(NOT COMMON_PLUGIN_DEFINES)
    message(FATAL_ERROR "Either COMMON_PLUGIN_DEFINES is empty or not set")
  endif()
  target_compile_definitions(${_LIB_NAME} PUBLIC
    ${COMMON_PLUGIN_DEFINES}
  )

  set(DEBUG_LIBRARY_SUFFIX "")
  set_target_properties(${_LIB_NAME}
    PROPERTIES
      # ENABLE_EXPORTS for -rdynamic
      # i.e. export symbols from the executables
      # required for plugin system
      # see https://stackoverflow.com/a/8626922
      ENABLE_EXPORTS ON
      POSITION_INDEPENDENT_CODE ON
      ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}" # TODO: /lib
      LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}" # TODO: /lib
      RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}" # TODO: /bin
      OUTPUT_NAME "${_LIB_NAME}$<$<CONFIG:Debug>:${DEBUG_LIBRARY_SUFFIX}>"
      # Plugins don't have any prefix (e.g. 'lib' on Linux)
      PREFIX ""
      CXX_STANDARD 17
      CXX_EXTENSIONS OFF
      CMAKE_CXX_STANDARD_REQUIRED ON
  )

  # POSITION_INDEPENDENT_CODE for -fPIC
  set_property(TARGET ${_LIB_NAME}
    PROPERTY POSITION_INDEPENDENT_CODE ON)

  if(ENABLE_CLING)
    list(APPEND CLING_DEFINITIONS CLING_IS_ON=1)
    target_link_libraries(${_LIB_NAME} PUBLIC
      CONAN_PKG::cling_conan
    )

    get_target_property (cling_conan_IMPORTED_LOCATION
      CONAN_PKG::cling_conan INTERFACE_INCLUDE_DIRECTORIES)
    message( STATUS "cling_conan=${cling_conan_IMPORTED_LOCATION}" )
    target_include_directories( ${_LIB_NAME} PUBLIC
      ${cling_conan_IMPORTED_LOCATION} )

    if(MSVC)
      set_target_properties(${_LIB_NAME} PROPERTIES
        WINDOWS_EXPORT_ALL_SYMBOLS 1)
      set_property(
        TARGET ${_LIB_NAME}
        APPEND_STRING
        PROPERTY LINK_FLAGS
                 "/EXPORT:?setValueNoAlloc@internal@runtime@cling@@YAXPEAX00D_K@Z
                  /EXPORT:?setValueNoAlloc@internal@runtime@cling@@YAXPEAX00DM@Z
                  /EXPORT:cling_runtime_internal_throwIfInvalidPointer")
    endif()

    target_compile_definitions(${_LIB_NAME} PUBLIC
      CLING_IS_ON=1)
  endif(ENABLE_CLING)

  if(ENABLE_CLANG_FROM_CONAN)
    target_link_libraries( ${_LIB_NAME} PUBLIC
      CONAN_PKG::libclang
      CONAN_PKG::clang_tooling
      CONAN_PKG::clang_tooling_core
      CONAN_PKG::llvm_support
    )
  endif(ENABLE_CLANG_FROM_CONAN)

  ## ---------------------------- Link Time Optimization -------------------------------- ##
  if(ENABLE_LTO)
    # Check for LTO support (needs to be after project(...) )
    find_lto(CXX)

    # enable lto if available for non-debug configurations
    target_enable_lto(${_LIB_NAME} optimized)
  else(ENABLE_LTO)
    if(cmake_build_type_tolower MATCHES "release" )
      message(WARNING "Enable LTO in Release builds")
    endif()
  endif(ENABLE_LTO)

  list(APPEND ClangErrorFlags
    -Werror=thread-safety
    -Werror=thread-safety-analysis
  )

  list(APPEND GCCAndClangErrorFlags
    -Werror=float-equal
    -Werror=missing-braces
    -Werror=init-self
    -Werror=logical-op
    -Werror=write-strings
    -Werror=address
    -Werror=array-bounds
    -Werror=char-subscripts
    -Werror=enum-compare
    -Werror=implicit-int
    -Werror=empty-body
    -Werror=main
    -Werror=aggressive-loop-optimizations
    -Werror=nonnull
    -Werror=parentheses
    -Werror=pointer-sign
    -Werror=return-type
    -Werror=sequence-point
    -Werror=uninitialized
    -Werror=volatile-register-var
    -Werror=ignored-qualifiers
    -Werror=missing-parameter-type
    -Werror=old-style-declaration
    -Werror=sign-compare
    -Werror=conditional-uninitialized
    -Werror=date-time
    -Werror=switch
  )

  list(APPEND GCCAndClangWarningFlags
    -Wrange-loop-analysis
    -Wvla
    -Wswitch
    -Wformat-security
    -Wredundant-decls
    -Wunused-variable
    -Wdate-time
    -Wconditional-uninitialized
    -Wsign-compare
    -Wsuggest-override
    -Wunused-parameter
    -Wself-assign
    -Wunused-local-typedef
    -Wimplicit-fallthrough
    -Wdeprecated-copy
    # disable warning: designated initializers are a C99 feature
    -Wno-c99-extensions
    -Wno-error=c99-extensions
    # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
    -Wduplicated-cond
    # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
    -Wduplicated-branches
    # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
    -Wlogical-op
    # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
    -Wrestrict
    # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
    -Wnull-dereference
    # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
    -Wold-style-cast
    # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
    -Wuseless-cast
    # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
    -Wjump-misses-init
    # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
    -Wdouble-promotion
    # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
    -Wshadow
    # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
    -Wformat=2
  )

  # -ftrapv generates traps for signed overflow on addition, subtraction, multiplication operations
  # see https://clang.llvm.org/docs/ClangCommandLineReference.html#cmdoption-clang-ftrapv
  # NOTE: ftrapv affects performance, so use only in debug builds
  if (cmake_build_type_tolower MATCHES "debug" )
    check_cxx_compiler_flag(-ftrapv CC_HAS_FTRAPV)
    if(CC_HAS_FTRAPV)
      target_compile_options(${_LIB_NAME} PRIVATE
        # NOTE: SIGABRT to be raised
        # that will normally abort your program on overflow
        -ftrapv
      )
    endif()
  endif()

  target_compile_options(${_LIB_NAME} PRIVATE
    # NOTE: explicitly select the "C++ Core Check Lifetime Rules" (or "Microsoft All Rules") in order to enable the lifetime checks.
    # see https://devblogs.microsoft.com/cppblog/c-core-guidelines-checker-in-visual-studio-2017/
    # see https://www.modernescpp.com/index.php/c-core-guidelines-lifetime-safety
    $<$<CXX_COMPILER_ID:MSVC>:
      /W3 # Set warning level
      /Wall
      /analyze
    >
    # see https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
    $<$<CXX_COMPILER_ID:GNU>:
      ${GCCAndClangErrorFlags}
      ${GCCAndClangWarningFlags}
      -Wall
      -W
      -Wextra
      -Wpedantic
      -Wdeprecated-register
      -Wnon-virtual-dtor
    >
    $<$<CXX_COMPILER_ID:Clang>:
      ${GCCAndClangErrorFlags}
      ${GCCAndClangWarningFlags}
      ${ClangErrorFlags}
      # see https://pspdfkit.com/blog/2020/the-cpp-lifetime-profile/
      # TODO: only special branch of Clang currently https://github.com/mgehre/llvm-project
      #-Wlifetime
      # see http://clang.llvm.org/docs/ThreadSafetyAnalysis.html
      # see https://github.com/isocpp/CppCoreGuidelines/blob/master/docs/Lifetime.pdf
      -Wthread-safety-analysis
      -Wall
      -W
      -Wextra
      -Wpedantic
      -Wdeprecated-register
      -Wnon-virtual-dtor
      # Negative requirements are an experimental feature
      # which will produce many warnings in existing code
      -Wno-thread-safety-negative
    >
  )

  # # Helper that can set default warning flags for you
  target_set_warnings( # from cmake_helper_utils (conan package)
    ${_LIB_NAME}
    ENABLE ALL
    DISABLE Annoying)

  if(ENABLE_VALGRIND)
    check_valgrind_config()

    if(cmake_build_type_tolower MATCHES "release" )
      message(WARNING "Disable valgrind in Release builds")
    endif()
  endif()

  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_run_cppcheck
  cppcheck_enabler(
    PATHS
      # to use cppcheck_installer from conan
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
      # to use from cmake subfolder
      ${CMAKE_SOURCE_DIR}/cmake
      ${CMAKE_CURRENT_SOURCE_DIR}/cmake
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    IS_ENABLED
      ${ENABLE_CPPCHECK}
    CHECK_TARGETS
      ${_LIB_NAME}
    EXTRA_OPTIONS
      # check all #ifdef
      #--force
      #-j6 # thread count
      --language=c++
      # inconclusive = more checks
      # NOTE: There are false positives with this option.
      --inconclusive
      --enable=all
      #--enable=warning,performance,portability,information,missingInclude
      # Give path to ignore. Give several -i parameters to ignore several paths.
      -igenerated
      --std=c++20
      # include
      -I${basis_HEADER_DIR}
      # ignore
      -i${basis_HEADER_DIR}
      # include
      #-I${cling_includes}
      # ignore
      #-i${cling_includes}
      # include
      #-I${clang_includes}
      # ignore
      #-i${clang_includes}
      # include
      -I${corrade_includes}
      # ignore
      -i${corrade_includes}
      # corrade support
      -DDOXYGEN_GENERATING_OUTPUT=1
      # include
      -I${entt_includes}
      -DNDEBUG
      --max-configs=100
      ${cppcheck_linux_defines}
      # undef
      -USTARBOARD
      # undef
      -UCOBALT
      # less info in console
      #--quiet
      # missingIncludeSystem:
      # Cppcheck does not need standard library headers
      # to get proper results.
      #--suppress=missingIncludeSystem
      # preprocessorErrorDirective:
      # support for
      # __has_include(<boost/filesystem.hpp>)
      #--suppress=preprocessorErrorDirective
    HTML_REPORT TRUE
    VERBOSE
    REQUIRED
  )

  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_clang_tidy
  clang_tidy_enabler(
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    IS_ENABLED
      ${ENABLE_CLANG_TIDY}
    CHECK_TARGETS
      ${_LIB_NAME}
    EXTRA_OPTIONS
      # TODO: use file .clang-tidy, similar to
      # https://github.com/mapbox/protozero/blob/ed6ba50979acf97b9c5300ae88a20d8b8b6c2fc4/.clang-tidy
      # https://fuchsia.googlesource.com/fuchsia/+/f7851796155f50b57d5ebd26a43ef49f5d5bdee4/.clang-tidy
      # https://github.com/jar-git/cmake-template/blob/master/.clang-tidy
      #
      # see clang-tidy --list-checks -checks='*' | grep "modernize"
      # see list of clang-tidy checks:
      # https://clang.llvm.org/extra/clang-tidy/checks/list.html
      #
      #  Disabled checks:
      #
      #  bugprone-signed-char-misuse
      #    Lots of warnings in varint.hpp otherwise.
      #
      #  cert-dcl21-cpp
      #    It is unclear whether this is still a good recommendation in modern C++.
      #
      #  cert-err58-cpp
      #    Due to the Catch2 test framework.
      #
      #  cert-err60-cpp
      #    Reports std::runtime_error as broken which we can't do anything about.
      #
      #  cppcoreguidelines-avoid-c-arrays
      #  hicpp-avoid-c-arrays
      #  modernize-avoid-c-arrays
      #    Makes sense for some array, but especially for char arrays using
      #    std::array isn't a good solution.
      #
      #  cppcoreguidelines-avoid-magic-numbers
      #  readability-magic-numbers
      #    Good idea, but it goes too far to force this everywhere.
      #
      #  cppcoreguidelines-macro-usage
      #    There are cases where macros are simply needed.
      #
      #  cppcoreguidelines-pro-bounds-array-to-pointer-decay
      #    Limited use and many false positives including for all asserts.
      #
      #  cppcoreguidelines-pro-bounds-pointer-arithmetic
      #    This is a low-level library, it needs to do pointer arithmetic.
      #
      #  cppcoreguidelines-pro-type-reinterpret-cast
      #    This is a low-level library, it needs to do reinterpret-casts.
      #
      #  fuchsia-*
      #    Much too strict.
      #
      #  google-runtime-references
      #    This is just a matter of preference, and we can't change the interfaces
      #    now anyways.
      #
      #  hicpp-no-array-decay
      #    Limited use and many false positives including for all asserts.
      #
      #  modernize-use-trailing-return-type
      #    We are not quite that modern.
      #    We do not want to rewrite code like so:
      #    int main(int argc, char* argv[])
      #    ~~~~
      #    auto                            -> int
      #
      #  readability-implicit-bool-conversion
      #    Not necessarily more readable.
      #
      -checks=*,-bugprone-signed-char-misuse,-cert-dcl21-cpp,-cert-err58-cpp,-cert-err60-cpp,-cppcoreguidelines-avoid-c-arrays,-cppcoreguidelines-avoid-magic-numbers,-cppcoreguidelines-macro-usage,-cppcoreguidelines-pro-bounds-pointer-arithmetic,-cppcoreguidelines-pro-bounds-array-to-pointer-decay,-cppcoreguidelines-pro-type-reinterpret-cast,-fuchsia-*,-google-runtime-references,-hicpp-avoid-c-arrays,-hicpp-no-array-decay,-hicpp-vararg,-modernize-avoid-c-arrays,-modernize-use-trailing-return-type,-readability-implicit-bool-conversion,-readability-magic-numbers
      #-config="{CheckOptions: [ {key: readability-identifier-naming.ClassCase, value: CamelCase} ]}"
      -extra-arg=-std=c++17
      -extra-arg=-Qunused-arguments
      # To suppress compiler diagnostic messages
      # from third-party headers just use -isystem
      # instead of -I to include those headers.
      #-extra-arg=-nostdinc
      #-extra-arg=-nostdinc++
      -extra-arg=-DBOOST_SYSTEM_NO_DEPRECATED
      -extra-arg=-DBOOST_ERROR_CODE_HEADER_ONLY
      #List of files with line ranges to filter the
      #    warnings. Can be used together with
      #    -header-filter. The format of the list is a JSON
      #    array of objects:
      #      [
      #        {"name":"file1.cpp","lines":[[1,3],[5,7]]},
      #        {"name":"file2.h"}
      #      ]
      #-line-filter=\"[\
      #  {\"name\":\"path/to/file.cpp\"},\
      #  {\"name\":\"path/to/file.h\"}\
      #  ]\"
      # -header-filter is a whitelist not a blacklist.
      #-header-filter="^((?!/usr/|thirdparty|third_party|/cocos2d-x/external/|/cocos/scripting/).)*$"
      #-header-filter=flextool/*
      -header-filter=${CMAKE_CURRENT_SOURCE_DIR}
      -warnings-as-errors=cppcoreguidelines-avoid-goto
    VERBOSE
    REQUIRED
  )

  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_cppclean
  cppclean_enabler(
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    #NO_SYSTEM_ENVIRONMENT_PATH
    #NO_CMAKE_SYSTEM_PATH
    IS_ENABLED
      ${ENABLE_CPPCLEAN}
    CHECK_TARGETS
      ${_LIB_NAME}
    EXTRA_OPTIONS
      --include-path ${CMAKE_CURRENT_SOURCE_DIR}/include
      #--include-path-non-system ${CMAKE_CURRENT_SOURCE_DIR}/include
      --verbose
      --exclude "*generated*"
      #-extra-arg=-std=c++17
      #-extra-arg=-Qunused-arguments
      #-extra-arg=-DBOOST_SYSTEM_NO_DEPRECATED
      #-extra-arg=-DBOOST_ERROR_CODE_HEADER_ONLY
    VERBOSE
    REQUIRED
  )

  # fixes oclint: error: violations exceed threshold
  # see https://stackoverflow.com/a/30151220
  set(oclintMaxPriority 15000)

  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_oclint
  oclint_enabler(
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    #NO_SYSTEM_ENVIRONMENT_PATH
    #NO_CMAKE_SYSTEM_PATH
    IS_ENABLED
      ${ENABLE_OCLINT}
    CHECK_TARGETS
      ${_LIB_NAME}
    EXTRA_OPTIONS
      # OCLINT command-line manual
      # https://oclint-docs.readthedocs.io/en/stable/manual/oclint.html
      -extra-arg=-std=c++17
      -extra-arg=-Qunused-arguments
      # To suppress compiler diagnostic messages
      # from third-party headers just use -isystem
      # instead of -I to include those headers.
      #-extra-arg=-nostdinc
      #-extra-arg=-nostdinc++
      -extra-arg=-DBOOST_SYSTEM_NO_DEPRECATED
      -extra-arg=-DBOOST_ERROR_CODE_HEADER_ONLY
      # Enable Clang Static Analyzer,
      # and integrate results into OCLint report
      -enable-clang-static-analyzer
      # Compile every source, and analyze across global contexts
      # (depends on number of source files,
      # could results in high memory load)
      # -enable-global-analysis
      # Write output to <path>
      -o=${CMAKE_CURRENT_BINARY_DIR}/report.html
      -report-type html
      # Build path is used to read a compile command database.
      #-p=${CMAKE_CURRENT_BINARY_DIR}
      # Add directory to rule loading path
      #-R=${CMAKE_CURRENT_SOURCE_DIR}
      # Disable the anonymous analytics
      -no-analytics
      #-rc=<parameter>=<value>       - Override the default behavior of rules
      #-report-type=<name>           - Change output report type
      #-rule=<rule name>             - Explicitly pick rules
      # ignore system headers
      #-e /usr/*
      # ignore third-party lib
      #-e corrade/*
      # disable compiler errors and compiler warnings in my report
      #-extra-arg=-Wno-everything
      -stats
      -max-priority-1=${oclintMaxPriority}
      -max-priority-2=${oclintMaxPriority}
      -max-priority-3=${oclintMaxPriority}
      # see list of rules at
      # https://oclint-docs.readthedocs.io/en/stable/rules/
      #-disable-rule GotoStatement
      # Cyclomatic complexity of a method
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc CYCLOMATIC_COMPLEXITY=15
      # Number of lines for a C class or Objective-C interface, category, protocol, and implementation
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc LONG_CLASS=500
      # limit num. of characters in line
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc LONG_LINE=500
      # Number of lines for a method or function
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc LONG_METHOD=50
      # limit num. of characters in varibale name
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc LONG_VARIABLE_NAME=100
      # Number of lines for the if block that would prefer an early exists
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc MAXIMUM_IF_LENGTH=15
      # Count of case statements in a switch statement
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc MINIMUM_CASES_IN_SWITCH=3
      # NPath complexity of a method
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc NPATH_COMPLEXITY=20
      # Number of non-commenting source statements of a method
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc NCSS_METHOD=30
      # Depth of a block or compound statement
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc NESTED_BLOCK_DEPTH=6
      # Number of characters for a variable name
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc SHORT_VARIABLE_NAME=3
      # Number of fields of a class
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc TOO_MANY_FIELDS=50
      # Number of methods of a class
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc TOO_MANY_METHODS=50
      # Number of parameters of a method
      # see http://docs.oclint.org/en/stable/howto/thresholds.html#available-thresholds
      -rc TOO_MANY_PARAMETERS=10
    VERBOSE
    REQUIRED
  )

  # include-what-you-use mappings file
  # Mappings file format:
  #   { include: [ '@"mutt/.*"', private, '"mutt/mutt.h"', public ] },
  #   { include: [ '@"conn/.*"', private, '"conn/conn.h"', public ] },
  set(IWYU_IMP "${CMAKE_CURRENT_SOURCE_DIR}/cmake/iwyu/iwyu.imp")
  if(NOT EXISTS ${IWYU_IMP})
    message(FATAL_ERROR "Unable to find file: ${IWYU_IMP}")
  endif(NOT EXISTS ${IWYU_IMP})

  if(ENABLE_IWYU)
    message(STATUS
      "CONAN_LLVM_TOOLS_ROOT: ${CONAN_LLVM_TOOLS_ROOT}")
    # NOTE: you can create symlink to fix issue
    if(NOT EXISTS "${CONAN_LLVM_TOOLS_ROOT}/include")
      message(FATAL_ERROR "Unable to find file: ${CONAN_LLVM_TOOLS_ROOT}/include")
    endif()
  endif(ENABLE_IWYU)

  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_iwyu
  iwyu_enabler(
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    IS_ENABLED
      ${ENABLE_IWYU}
    CHECK_TARGETS
      ${_LIB_NAME}
    EXTRA_OPTIONS
      -std=c++17
      # Get llvm version that iwyu depends on:
      # strings /usr/bin/iwyu | grep LLVM
      # Then install required llvm version:
      # apt-get install clang-10 clang-tools-10 clang-10-doc libclang-common-10-dev
      # Use the proper include directory,
      # for clang-* it would be /usr/lib/llvm-*/lib/clang/*/include/.
      # locate stddef.h | sed -ne '/^\/usr/p'
      # see https://github.com/include-what-you-use/include-what-you-use/issues/679
      #-nostdinc++
      #-nodefaultlibs
      # NOTE: you can get `clang_8.0.0` like so:
      # curl -SL http://releases.llvm.org/8.0.0/clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz | tar -xJC .
      # mv clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-18.04 clang_8.0.0
      # mv clang_8.0.0 /usr/local
      #-isystem/usr/lib/llvm-10/lib/clang/10.0.0/include/
      -nostdinc++
      -nodefaultlibs
      # see https://github.com/include-what-you-use/include-what-you-use/issues/802
      -isystem${CONAN_LLVM_TOOLS_ROOT}/include/c++/v1/
      -isystem${CONAN_LLVM_TOOLS_ROOT}/lib/clang/10.0.1/include/
      # -Xiwyu --transitive_includes_only
      # pch_in_code: The file has an important header first
      # -Xiwyu --pch_in_code
      # no_comments: Do not add notes to the output
      -Xiwyu --no_comments
      -Xiwyu --no_default_mappings
      # mapping_file: lookup file
      -Xiwyu --mapping_file=${IWYU_IMP}
      # see https://github.com/include-what-you-use/include-what-you-use/issues/760
      -Wno-unknown-warning-option
      -Wno-error
      # when sorting includes, place quoted ones first.
      -Xiwyu --quoted_includes_first
      # suggests the more concise syntax introduced in C++17
      -Xiwyu --cxx17ns
      # max_line_length: maximum line length for includes.
      # Note that this only affects comments and alignment thereof,
      # the maximum line length can still be exceeded
      # with long file names (default: 80).
      -Xiwyu --max_line_length=180
      #-Xiwyu --check_also=${CMAKE_CURRENT_SOURCE_DIR}/src/*
      #-Xiwyu --check_also=${CMAKE_CURRENT_SOURCE_DIR}/src/*/*
      #-Xiwyu --check_also=${CMAKE_CURRENT_SOURCE_DIR}/src/*/*/*
      #-Xiwyu --check_also=${CMAKE_CURRENT_SOURCE_DIR}/src/*/*/*/*
    #VERBOSE
    REQUIRED
    CHECK_TARGETS_DEPEND
  )

  set(EXTRA_CLANG_FORMAT_FILES
    # place here files what need to be to be formatted
  )

  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_clang_format
  clang_format_enabler(
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    IS_ENABLED
      ${ENABLE_CLANG_FORMAT}
    CHECK_TARGETS
      ${_LIB_NAME}
    EXTRA_OPTIONS
      # ferror-limit:
      # Used only with --dry-run or -n
      --ferror-limit=9999
      # Use -style=file to load style configuration from
      # .clang-format file located in one of the parent
      # directories of the source file (or current
      # directory for stdin).
      -style=file
      #  The -i option indicates to apply the formatting options
      # to the files in-place, rather than spitting out
      # the formatted version of the files to the command line.
      -i
      ${EXTRA_CLANG_FORMAT_FILES}
    VERBOSE
    REQUIRED
  )

  set(EXTRA_UNCRUSTIFY_FILES
    # place here files what need to be to be formatted
  )

  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_uncrustify
  uncrustify_enabler(
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    IS_ENABLED
      ${ENABLE_UNCRUSTIFY}
    CHECK_TARGETS
      ${_LIB_NAME}
    EXTRA_OPTIONS
      --no-backup
      -c ${CMAKE_CURRENT_SOURCE_DIR}/uncrustify.cfg
      ${EXTRA_UNCRUSTIFY_FILES}
    VERBOSE
    REQUIRED
  )

  if(ENABLE_MSAN OR ENABLE_TSAN OR ENABLE_ASAN OR ENABLE_UBSAN)
    # use llvm_tools from conan
    find_program_helper(llvm-symbolizer
      PATHS
        #${CONAN_BIN_DIRS}
        ${CONAN_BIN_DIRS_LLVM_TOOLS}
      NO_SYSTEM_ENVIRONMENT_PATH
      NO_CMAKE_SYSTEM_PATH
      ${ARGUMENTS_UNPARSED_ARGUMENTS}
      REQUIRED
      OUT_VAR LLVM_SYMBOLIZER_PROGRAM
      VERBOSE TRUE
    )

    check_sanitizer_options(
      ENABLE_TSAN ${ENABLE_TSAN}
      ENABLE_ASAN ${ENABLE_ASAN}
      ENABLE_MSAN ${ENABLE_MSAN}
      ENABLE_UBSAN ${ENABLE_UBSAN}
      LLVM_SYMBOLIZER_PROGRAM ${LLVM_SYMBOLIZER_PROGRAM}
    )
  endif()

  if(ENABLE_MSAN)
    message(STATUS "enabling MSAN on ${_LIB_NAME}")
    add_msan_static_link(${_LIB_NAME})
    add_msan_definitions(${_LIB_NAME})
    add_msan_flags()
  endif(ENABLE_MSAN)

  if(ENABLE_TSAN)
    message(STATUS "enabling TSAN on ${_LIB_NAME}")
    add_tsan_static_link(${_LIB_NAME})
    add_tsan_definitions(${_LIB_NAME})
    add_tsan_flags()
  endif(ENABLE_TSAN)

  if(ENABLE_ASAN)
    message(STATUS "enabling ASAN on ${_LIB_NAME}")
    add_asan_static_link(${_LIB_NAME})
    add_asan_definitions(${_LIB_NAME})
    add_asan_flags()
  endif(ENABLE_ASAN)

  if(ENABLE_UBSAN)
    message(STATUS "enabling UBSAN on ${_LIB_NAME}")
    add_ubsan_static_link(${_LIB_NAME})
    add_ubsan_definitions(${_LIB_NAME})
    add_ubsan_flags()
  endif(ENABLE_UBSAN)

  ## ---------------------------- gold linker -------------------------------- ##
  # add_gold_linker
  if(USE_LD_GOLD)
    add_gold_linker() # from cmake_helper_utils (conan package)
  endif(USE_LD_GOLD)

  ## ---------------------------- ccache -------------------------------- ##
  if(USE_CCACHE)
    add_ccache()
    target_ccache_summary(${LIB_NAME}) # from cmake_helper_utils (conan package)
  endif(USE_CCACHE)

  ## ---------------------------- coverage -------------------------------- ##
  if(USE_COVERAGE)
    add_coverage() # from cmake_helper_utils (conan package)
  endif(USE_COVERAGE)

  ## ---------------------------- RULE_MESSAGES property --------------------------------
  # More logging when compiling.
  # RULE_MESSAGES: Specify whether to report a message for each make rule.
  # This property specifies whether Makefile generators
  # should add a progress message describing what each build rule does.
  # If the property is not set the default is ON.
  # Set the property to OFF to disable granular messages
  # and report only as each target completes.
  # This is intended to allow scripted builds
  # to avoid the build time cost of detailed reports.
  # If a CMAKE_RULE_MESSAGES cache entry exists its value
  # initializes the value of this property.
  # Non-Makefile generators currently ignore this property.
  set_target_properties(
    ${LIB_NAME} PROPERTIES
    # disable to avoid the build time cost of detailed reports
    RULE_MESSAGES ON
  )
endmacro(add_plugin_library)

macro(copy_to_bin_dirs _SRC_CONF _DEST_FILE_NAME)
  # for builds with conan workspace
  if(EXISTS "${_SRC_CONF}")
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
              ${_SRC_CONF}
              ${CMAKE_BINARY_DIR}/${_DEST_FILE_NAME}
    )

    # for builds without conan
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
              ${_SRC_CONF}
              ${CMAKE_CURRENT_BINARY_DIR}/${_DEST_FILE_NAME}
    )
  else()
    message(FATAL_ERROR "unable to find file: ${_SRC_CONF}")
  endif()
endmacro(copy_to_bin_dirs)

macro(set_plugin_tools _LIB_NAME)
  list(APPEND CMAKE_PROGRAM_PATH ${CONAN_BIN_DIRS})
  link_directories(${CONAN_LIB_DIRS})
  #
  message(STATUS "searching for flextool...")
  find_package(flextool MODULE REQUIRED)
  #
  # used by https://docs.conan.io/en/latest/developing_packages/workspaces.html
  if(TARGET flextool OR TARGET flextool::exe)
    get_property(flextool_location TARGET flextool PROPERTY RUNTIME_OUTPUT_DIRECTORY)
    message (STATUS "flextool_location == ${flextool_location}")
    set(flextool "${flextool_location}/flextool")
    message (STATUS "flextool == ${flextool}")
  else()
    find_program(flextool flextool NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
    message(STATUS "find_program for flextool ${flextool}")
  endif()
  if(NOT flextool OR ${flextool} STREQUAL "")
    message(FATAL_ERROR "flextool not found ${flextool}")
  endif()
  #
  set(cling_includes
    ${CONAN_CLING_CONAN_ROOT}/include
  )
  message(STATUS "cling_includes=${cling_includes}")
  set(clang_includes
    ${CONAN_CLING_CONAN_ROOT}/lib/clang/5.0.0/include
  )
  message(STATUS "clang_includes=${clang_includes}")
  #
  find_package(flex_support_headers REQUIRED)
  if(${flex_support_headers_HEADER_FILE} STREQUAL "")
    message(FATAL_ERROR "unable to find flex_support_headers_HEADER_FILE=${flex_support_headers_HEADER_FILE}")
  endif()
  #
  set(chromium_base_headers
    ${CONAN_CHROMIUM_BASE_ROOT}/include
  )
  message(STATUS "chromium_base_headers=${chromium_base_headers}")
  set(chromium_build_util_headers
    ${CONAN_CHROMIUM_BUILD_UTIL_ROOT}/include/chromium
  )
  message(STATUS "chromium_build_util_headers=${chromium_build_util_headers}")
  set(flextool_input_files
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/code_generation/main.cc
  )
  set(flextool_outdir ${CMAKE_BINARY_DIR})
  message(STATUS "flextool_outdir=${flextool_outdir}")
  #
  get_property(${_LIB_NAME}_location TARGET "${_LIB_NAME}" PROPERTY LIBRARY_OUTPUT_DIRECTORY)
  set(${_LIB_NAME}_file "${${_LIB_NAME}_location}/${_LIB_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}")
  message (STATUS "${_LIB_NAME} file == ${${_LIB_NAME}_file}")
endmacro(set_plugin_tools)

macro(generate_version_file _IN_FILE _OUT_FILE)
  configure_file(${_IN_FILE}
    ${_OUT_FILE})

  set_source_files_properties(${_OUT_FILE}
    PROPERTIES GENERATED 1)
endmacro(generate_version_file)

macro(copy_directory_to_target_file_dir _IN_DIR_PATH _OUT_DIR_NAME _TARGET_NAME)
  # copy new resources
  add_custom_command( TARGET ${_TARGET_NAME} PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
      ${_IN_DIR_PATH}
      $<TARGET_FILE_DIR:${_TARGET_NAME}>/${_OUT_DIR_NAME} )
endmacro(copy_directory_to_target_file_dir)
