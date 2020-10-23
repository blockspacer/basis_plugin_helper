from conans import ConanFile
from basis_plugin_helper.cmake import *
from basis_plugin_helper.headeronly import *
from basis_plugin_helper.require_scm import *

class ConanCommonRecipes(ConanFile):
    name = "basis_plugin_helper"
    version = "0.0.1"
    url = "https://gitlab.com/USERNAME/basis_plugin_helper"
    license = "MIT"
    description = "Common recipes for conan.io packages"
    exports = ("*.py", "Find*.cmake")
    exports_sources = ("LICENSE", "*.py", "*.md", "include/*", "src/*",
                       "cmake/*", "CMakeLists.txt", "tests/*", "benchmarks/*",
                       "scripts/*", "tools/*", "codegen/*", "assets/*",
                       "docs/*", "licenses/*", "patches/*", "resources/*",
                       "submodules/*", "thirdparty/*", "third-party/*",
                       "third_party/*", "base/*", "chromium/*")
    # NOTE: no cmake_find_package due to custom FindXXX.cmake
    generators = "cmake", "cmake_paths", "virtualenv"

    def package(self):
        self.output.info('Packaging package \'{}\''.format(self.name))

        self.copy("LICENSE", dst="licenses", src='.')
        self.copy(pattern="LICENSE", dst="licenses")
        self.copy(pattern="*.cmake", dst=os.path.join(self.package_folder, "cmake"), src='cmake')
        #self.copy(pattern="*.cmake", dst=self.package_folder, src='cmake')

        # Local build
        # see https://docs.conan.io/en/latest/developing_packages/editable_packages.html
        if not self.in_local_cache:
            self.copy("conanfile.py", dst=".", keep_path=False)

    # Importing files copies files from the local store to your project.
    def imports(self):
        dest = os.getenv("CONAN_IMPORT_PATH", "bin")
        self.copy("license*", dst=dest, ignore_case=True)
        self.copy("*.dll", dst=dest, src="bin")
        self.copy("*.so", dst=dest, src="bin")
        self.copy("*.dylib*", dst=dest, src="lib")
        self.copy("*.lib*", dst=dest, src="lib")
        self.copy("*.a*", dst=dest, src="lib")
        self.copy("assets", dst=dest, src="assets")

    def package_id(self):
        pass

    def configure(self):
        pass

    def build_requirements(self):
        pass

    def requirements(self):
        pass

    def build(self):
        pass

    def package_info(self):
        # Additional CMAKE_MODULE_PATH based on builddirs
        self.cpp_info.builddirs.append(\
          os.path.join(self.package_folder, "cmake"))

        self.info.header_only()
