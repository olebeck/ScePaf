set -e
patch -p2 -i "${CMAKE_CURRENT_LIST_DIR}/ScePaf.patch";
patch -p1 -i "${CMAKE_CURRENT_LIST_DIR}/ScePaf-appsettings.patch";
