# FindABICC cmake module

This module finds the abi-compliance-checker utility (https://github.com/lvc/abi-compliance-checker)
and define help function for auto create dump.

## Usage

1. Copy `FindABICC.cmake` to your project
2. Include it in `CMakeLists.txt`

```cmake
include(FindABICC.cmake)
```

```cmake
list(APPEND CMAKE_MODULE_PATH <path where it is>)
```

3. Use `find_package` command

```cmake
find_package(FindABICC)
```

4. Use `create_target_abi_dump` function

```cmake
create_target_abi_dump(MyLibraryTarget ALL)
````
