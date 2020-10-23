from conans import ConanFile, CMake, tools, AutoToolsBuildEnvironment, RunEnvironment, python_requires
from conans.errors import ConanInvalidConfiguration, ConanException
from conans.tools import os_info
import os, re, stat, fnmatch, platform, glob, traceback, shutil
from functools import total_ordering
from conans.tools import collect_libs
from conans.tools import OSInfo
from basis_plugin_helper.headeronly import package_headers
from basis_plugin_helper.require_scm import RequireScm

# if you using python less than 3 use from distutils import strtobool
from distutils.util import strtobool

# conan runs the methods in this order:
# config_options(),
# configure(),
# requirements(),
# package_id(),
# build_requirements(),
# build_id(),
# system_requirements(),
# source(),
# imports(),
# build(),
# package(),
# package_info()

class CMakePackage(ConanFile, RequireScm):
    plugin_options = {
        "shared": [True, False],
        "debug": [True, False],
        "enable_ubsan": [True, False],
        "enable_asan": [True, False],
        "enable_msan": [True, False],
        "enable_tsan": [True, False],
        "enable_valgrind": [True, False]
    }

    plugin_default_options = {
        "shared": "True",
        "debug": "False",
        "enable_ubsan": "False",
        "enable_asan": "False",
        "enable_msan": "False",
        "enable_tsan": "False",
        "enable_valgrind": "False",
        # boost
        "boost:no_rtti": "False",
        "boost:no_exceptions": "True",
        "boost:without_python": "True",
        "boost:without_coroutine": "True",
        "boost:without_stacktrace": "True",
        "boost:without_math": "True",
        "boost:without_wave": "True",
        "boost:without_contract": "True",
        "boost:without_locale": "True",
        "boost:without_random": "True",
        "boost:without_regex": "True",
        "boost:without_mpi": "True",
        "boost:without_timer": "True",
        "boost:without_thread": "True",
        "boost:without_chrono": "True",
        "boost:without_atomic": "True",
        "boost:without_system": "True",
        "boost:without_program_options": "True",
        "boost:without_serialization": "True",
        "boost:without_log": "True",
        "boost:without_type_erasure": "True",
        "boost:without_test": "True",
        "boost:without_graph": "True",
        "boost:without_graph_parallel": "True",
        "boost:without_iostreams": "True",
        "boost:without_context": "True",
        "boost:without_fiber": "True",
        "boost:without_filesystem": "True",
        "boost:without_date_time": "True",
        "boost:without_exception": "True",
        "boost:without_container": "True",
        # FakeIt
        "FakeIt:integration": "catch",
        # openssl
        "openssl:shared": "True",
        # chromium_base
        "chromium_base:use_alloc_shim": "True",
        # chromium_tcmalloc
        "chromium_tcmalloc:use_alloc_shim": "True",
        # flexlib
        "flexlib:shared": False,
        "flexlib:enable_clang_from_conan": "False",
        # flextool
        "flextool:enable_clang_from_conan": "False",
    }

    # NOTE: no cmake_find_package due to custom FindXXX.cmake
    plugin_generators = "cmake", "cmake_paths", "virtualenv"

    # Custom attributes for Bincrafters recipe conventions
    plugin_source_subfolder = "."
    plugin_build_subfolder = "."

    # If the source code is going to be in the same repo as the Conan recipe,
    # there is no need to define a `source` method. The source folder can be
    # defined like this
    plugin_exports_sources = ("LICENSE", "VERSION", "*.md", "include/*", "src/*",
                       "cmake/*", "examples/*", "CMakeLists.txt", "tests/*", "benchmarks/*",
                       "scripts/*", "tools/*", "codegen/*", "assets/*",
                       "docs/*", "licenses/*", "conf/*", "patches/*", "resources/*",
                       "submodules/*", "thirdparty/*", "third-party/*",
                       "third_party/*", "version.hpp.in")

    plugin_settings = "os_build", "os", "arch", "compiler", "build_type", "arch_build"

    # installs clang 10 from conan
    def _is_llvm_tools_enabled(self):
      return self._environ_option("ENABLE_LLVM_TOOLS", default = 'false')

    def _is_lwyu_enabled(self):
      return self._environ_option("ENABLE_LWYU", default = 'false')

    def _is_coverage_enabled(self):
      return self._environ_option("USE_COVERAGE", default = 'false')

    def _is_docs_enabled(self):
      return self._environ_option("BUILD_DOXY_DOC", default = 'false')

    def _is_benchmark_enabled(self):
      return self._environ_option("ENABLE_BENCHMARK", default = 'false')

    def _is_ccache_enabled(self):
      return self._environ_option("USE_CCACHE", default = 'false')

    def _is_cppcheck_enabled(self):
      return self._environ_option("ENABLE_CPPCHECK", default = 'false')

    def _is_clang_tidy_enabled(self):
      return self._environ_option("ENABLE_CLANG_TIDY", default = 'false')

    def _is_clang_format_enabled(self):
      return self._environ_option("ENABLE_CLANG_FORMAT", default = 'false')

    def _is_uncrustify_enabled(self):
      return self._environ_option("ENABLE_UNCRUSTIFY", default = 'false')

    def _is_iwyu_enabled(self):
      return self._environ_option("ENABLE_IWYU", default = 'false')

    def _is_cppclean_enabled(self):
      return self._environ_option("ENABLE_CPPCLEAN", default = 'false')

    def _is_lto_enabled(self):
      return self._environ_option("ENABLE_LTO", default = 'false')

    # sets cmake variables required to use clang 10 from conan
    def _is_compile_with_llvm_tools_enabled(self):
      return self._environ_option("COMPILE_WITH_LLVM_TOOLS", default = 'false')

    def _verbose_makefile(self):
        return os.environ.get('CONAN_' + self.name.upper() + '_VERBOSE_MAKEFILE') is not None

    def plugin_configure(self):
        lower_build_type = str(self.settings.build_type).lower()

        if lower_build_type != "release" and not self._is_llvm_tools_enabled():
            self.output.warn('enable llvm_tools for Debug builds')

        if self._is_iwyu_enabled() and (not self._is_llvm_tools_enabled() or not self.options['llvm_tools'].include_what_you_use):
            raise ConanInvalidConfiguration("iwyu requires llvm_tools enabled and -o llvm_tools:include_what_you_use=True")

        if self._is_compile_with_llvm_tools_enabled() and not self._is_llvm_tools_enabled():
            raise ConanInvalidConfiguration("to compile with llvm_tools you must be enable llvm_tools")

        if self.options.enable_valgrind:
            self.options["basis"].enable_valgrind = True
            self.options["chromium_base"].enable_valgrind = True

        if self.options.enable_ubsan \
           or self.options.enable_asan \
           or self.options.enable_msan \
           or self.options.enable_tsan:
            if not self._is_llvm_tools_enabled():
                raise ConanInvalidConfiguration("sanitizers require llvm_tools")

        if self.options.shared and \
           (self.options.enable_valgrind \
            or self.options.enable_ubsan \
            or self.options.enable_asan \
            or self.options.enable_msan \
            or self.options.enable_tsan):
                raise ConanInvalidConfiguration("sanitizers require static linking Disable BUILD_SHARED_LIBS.")

        if self.options.enable_ubsan \
           or self.options.enable_asan \
           or self.options.enable_msan \
           or self.options.enable_tsan:
            if not self.options["boost"].no_exceptions:
                raise ConanInvalidConfiguration("sanitizers require boost without exceptions")

        if self.options.enable_ubsan:
            self.options["basis"].enable_ubsan = True
            self.options["chromium_base"].enable_ubsan = True
            self.options["chromium_libxml"].enable_ubsan = True
            self.options["boost"].enable_ubsan = True
            self.options["corrade"].enable_ubsan = True
            if self._is_tests_enabled():
              self.options["conan_gtest"].enable_ubsan = True

        if self.options.enable_asan:
            self.options["basis"].enable_asan = True
            self.options["chromium_base"].enable_asan = True
            self.options["chromium_libxml"].enable_asan = True
            self.options["boost"].enable_asan = True
            self.options["corrade"].enable_asan = True
            if self._is_tests_enabled():
              self.options["conan_gtest"].enable_asan = True

        if self.options.enable_msan:
            self.options["basis"].enable_msan = True
            self.options["chromium_base"].enable_msan = True
            self.options["chromium_libxml"].enable_msan = True
            self.options["boost"].enable_msan = True
            self.options["corrade"].enable_msan = True
            if self._is_tests_enabled():
              self.options["conan_gtest"].enable_msan = True

        if self.options.enable_tsan:
            self.options["basis"].enable_tsan = True
            self.options["chromium_base"].enable_tsan = True
            self.options["chromium_libxml"].enable_tsan = True
            self.options["boost"].enable_tsan = True
            self.options["corrade"].enable_tsan = True
            if self._is_tests_enabled():
              self.options["conan_gtest"].enable_tsan = True

    def plugin_build_requirements(self):
        self.build_requires("cmake_platform_detection/master@conan/stable")
        self.build_requires("cmake_build_options/master@conan/stable")
        self.build_requires("cmake_helper_utils/master@conan/stable")
        self.build_requires("basis_plugin_helper/[~=0.0]@conan/stable")

        if self.options.enable_tsan \
            or self.options.enable_msan \
            or self.options.enable_asan \
            or self.options.enable_ubsan:
          self.build_requires("cmake_sanitizers/master@conan/stable")

        if self._is_cppcheck_enabled():
          self.build_requires("cppcheck_installer/1.90@conan/stable")

        # provides clang-tidy, clang-format, IWYU, scan-build, etc.
        if self._is_llvm_tools_enabled():
          self.build_requires("llvm_tools/master@conan/stable")

        if self._is_tests_enabled():
            self.requires("catch2/[>=2.1.0]@bincrafters/stable")
            self.requires("conan_gtest/release-1.10.0@conan/stable")
            self.build_requires("FakeIt/[>=2.0.5]@gasuketsu/stable")

    def plugin_requirements(self):
        self.requires("flextool/master@conan/stable")

        self.requires("flexlib/master@conan/stable")

        self.requires("flex_support_headers/master@conan/stable")

        self.requires("basis/master@conan/stable")

        self.requires("boost/1.71.0@dev/stable")

        self.requires("corrade/v2020.06@conan/stable")

        # \note dispatcher must be thread-safe,
        # so use entt after patch https://github.com/skypjack/entt/issues/449
        # see https://github.com/skypjack/entt/commit/74f3df83dbc9fc4b43b8cfb9d71ba02234bd5c4a
        self.requires("entt/3.4.0")

        self.requires("chromium_build_util/master@conan/stable")

        # see use_test_support option in base
        self.requires("chromium_libxml/master@conan/stable")

        self.requires("chromium_base/master@conan/stable")

    def _cmake_defs_from_options(self):
        defs = {}

        for name, value in self.options.values.as_list():
            defs[(self.name.upper() + '_' + name.upper()).replace('-', '_')] = value

        defs['CMAKE_VERBOSE_MAKEFILE'] = True

        if 'shared' in self.options:
            defs['CMAKE_BUILD_SHARED_LIBS'] = self.options.shared

        return defs

    # build-only option
    # see https://github.com/conan-io/conan/issues/6967
    # conan ignores changes in environ, so
    # use `conan remove` if you want to rebuild package
    def _environ_option(self, name, default = 'true'):
      env_val = default.lower() # default, must be lowercase!
      # allow both lowercase and uppercase
      if name.upper() in os.environ:
        env_val = os.getenv(name.upper())
      elif name.lower() in os.environ:
        env_val = os.getenv(name.lower())
      # strtobool:
      #   True values are y, yes, t, true, on and 1;
      #   False values are n, no, f, false, off and 0.
      #   Raises ValueError if val is anything else.
      #   see https://docs.python.org/3/distutils/apiref.html#distutils.util.strtobool
      return bool(strtobool(env_val))

    def _is_tests_enabled(self):
      return self._environ_option("ENABLE_TESTS", default = 'true')

    def add_cmake_option(self, cmake, var_name, value):
        value_str = "{}".format(value)
        var_value = "ON" if bool(strtobool(value_str.lower())) else "OFF"
        self.output.info('added cmake definition %s = %s' % (var_name, var_value))
        cmake.definitions[var_name] = var_value

    @property
    def _custom_cmake_defs(self):
        return getattr(self, 'custom_cmake_defs', {})

    def _parallel_build(self):
        return os.environ.get('CONAN_' + self.name.upper() + '_SINGLE_THREAD_BUILD') is None

    def plugin_cmake_definitions(self, cmake):
        cmake.definitions["CMAKE_TOOLCHAIN_FILE"] = 'conan_paths.cmake'

        cmake.definitions["ENABLE_VALGRIND"] = 'ON'
        if not self.options.enable_valgrind:
            cmake.definitions["ENABLE_VALGRIND"] = 'OFF'

        cmake.definitions["ENABLE_UBSAN"] = 'ON'
        if not self.options.enable_ubsan:
            cmake.definitions["ENABLE_UBSAN"] = 'OFF'

        cmake.definitions["ENABLE_ASAN"] = 'ON'
        if not self.options.enable_asan:
            cmake.definitions["ENABLE_ASAN"] = 'OFF'

        cmake.definitions["ENABLE_MSAN"] = 'ON'
        if not self.options.enable_msan:
            cmake.definitions["ENABLE_MSAN"] = 'OFF'

        cmake.definitions["ENABLE_TSAN"] = 'ON'
        if not self.options.enable_tsan:
            cmake.definitions["ENABLE_TSAN"] = 'OFF'

        cmake.definitions["CONAN_AUTO_INSTALL"] = 'OFF'

        if self.options.shared:
          self.output.info('Enabled BUILD_SHARED_LIBS')
          cmake.definitions["BUILD_SHARED_LIBS"] = "ON"
        else:
          self.output.info('Disabled BUILD_SHARED_LIBS')
          cmake.definitions["BUILD_SHARED_LIBS"] = "OFF"

        self.add_cmake_option(cmake, "ENABLE_TESTS", self._is_tests_enabled())

        self.add_cmake_option(cmake, "ENABLE_LWYU", self._is_lwyu_enabled())

        self.add_cmake_option(cmake, "USE_COVERAGE", self._is_coverage_enabled())

        self.add_cmake_option(cmake, "BUILD_DOXY_DOC", self._is_docs_enabled())

        self.add_cmake_option(cmake, "ENABLE_BENCHMARK", self._is_benchmark_enabled())

        self.add_cmake_option(cmake, "USE_CCACHE", self._is_ccache_enabled())

        self.add_cmake_option(cmake, "ENABLE_CPPCHECK", self._is_cppcheck_enabled())

        self.add_cmake_option(cmake, "ENABLE_CLANG_TIDY", self._is_clang_tidy_enabled())

        self.add_cmake_option(cmake, "ENABLE_CLANG_FORMAT", self._is_clang_format_enabled())

        self.add_cmake_option(cmake, "ENABLE_UNCRUSTIFY", self._is_uncrustify_enabled())

        self.add_cmake_option(cmake, "ENABLE_IWYU", self._is_iwyu_enabled())

        self.add_cmake_option(cmake, "ENABLE_CPPCLEAN", self._is_cppclean_enabled())

        self.add_cmake_option(cmake, "ENABLE_LTO", self._is_lto_enabled())

        self.add_cmake_option(cmake, "COMPILE_WITH_LLVM_TOOLS", self._is_compile_with_llvm_tools_enabled())

        return cmake

    def plugin_package(self):
        self.copy(pattern="LICENSE", dst="licenses", src=self.plugin_source_subfolder)

        # Local build
        # see https://docs.conan.io/en/latest/developing_packages/editable_packages.html
        if not self.in_local_cache:
            self.copy("conanfile.py", dst=".", keep_path=False)

    def plugin_build(self, cmake):
        if self.settings.compiler == 'gcc':
            cmake.definitions["CMAKE_C_COMPILER"] = "gcc-{}".format(
                self.settings.compiler.version)
            cmake.definitions["CMAKE_CXX_COMPILER"] = "g++-{}".format(
                self.settings.compiler.version)

        # The CMakeLists.txt file must be in `source_folder`
        cmake.configure(source_folder=self.plugin_source_subfolder)

        cpu_count = tools.cpu_count()
        self.output.info('Detected %s CPUs' % (cpu_count))

        # -j flag for parallel builds
        cmake.build(args=["--", "-j%s" % cpu_count])

        if self._is_tests_enabled():
          self.output.info('Running tests')
          cmake.build(args=["--target", \
            "{}_run_all_tests".format(self.name), \
            "--", "-j%s" % cpu_count])

    # Importing files copies files from the local store to your project.
    def plugin_imports(self):
        dest = os.getenv("CONAN_IMPORT_PATH", "bin")
        self.copy("license*", dst=dest, ignore_case=True)
        self.copy("*.dll", dst=dest, src="bin")
        self.copy("*.so*", dst=dest, src="bin")
        self.copy("*.pdb", dst=dest, src="lib")
        self.copy("*.dylib*", dst=dest, src="lib")
        self.copy("*.lib*", dst=dest, src="lib")
        self.copy("*.a*", dst=dest, src="lib")

    # package_info() method specifies the list of
    # the necessary libraries, defines and flags
    # for different build configurations for the consumers of the package.
    # This is necessary as there is no possible way to extract this information
    # from the CMake install automatically.
    # For instance, you need to specify the lib directories, etc.
    def plugin_package_info(self):
        self.cpp_info.includedirs = ["include"]
        self.cpp_info.libs = tools.collect_libs(self)
        self.cpp_info.libdirs = ["lib"]
        self.cpp_info.bindirs = ["bin"]
        self.env_info.LD_LIBRARY_PATH.append(
            os.path.join(self.package_folder, "lib"))
        self.env_info.PATH.append(os.path.join(self.package_folder, "bin"))
        for libpath in self.deps_cpp_info.lib_paths:
            self.env_info.LD_LIBRARY_PATH.append(libpath)
