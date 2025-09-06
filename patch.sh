set -e

SCRIPT_DIR=$(dirname "$0")

patch -p2 -i "${SCRIPT_DIR}/ScePaf.patch";
patch -p1 -i "${SCRIPT_DIR}/ScePaf-appsettings.patch";
