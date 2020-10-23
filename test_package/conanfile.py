from conans import ConanFile, python_requires

common = python_requires('basis_plugin_helper/0.0.1@conan/stable')

class ConanCommonRecipesTest(common.HeaderOnlyPackage):
    def test(self):
        pass
