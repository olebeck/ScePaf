# ScePaf stubs & headers

based on https://github.com/Princess-of-Sleeping/vitasdk-paf-component/
for use with cmake

how to use:
```cmake
include(FetchContent)
FetchContent_Declare(
    ScePaf_External
    URL https://github.com/olebeck/ScePaf/releases/download/continuous/ScePaf-1.0.0.zip
)
FetchContent_MakeAvailable(ScePaf_External)

add_executable(myapp
    mysrc.cpp
)

target_link_libraries(myapp PRIVATE ScePafCommon_stub)
```