# About

The python_requires feature is a very convenient way to share files and code between different recipes.

See:
- https://manu343726.github.io/2018-11-17-conan-common-recipes/
- https://docs.conan.io/en/latest/extending/python_requires.html

# Usage

```python
from conans import python_requires

# ...

basis_plugin_helper = python_requires("basis_plugin_helper/VERSION_HERE@conan/stable")

class my_conan_project(basis_plugin_helper.CMakePackage):
    # ...
```

## Build

```bash
export VERBOSE=1
export CONAN_REVISIONS_ENABLED=1
export CONAN_VERBOSE_TRACEBACK=1
export CONAN_PRINT_RUN_COMMANDS=1
export CONAN_LOGGING_LEVEL=10

cmake -E time \
  conan create . conan/stable

# clean build cache
conan remove "*" --build --force
```
