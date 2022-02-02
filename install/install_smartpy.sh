#!/bin/bash

    # Install python3, if Debian/Ubuntu
    dir=$(dirname $0)
    "$dir/install_python.sh"

    # Download SmartPy and FA2 template
    rootdir=$(realpath "$dir/..")
    if [ ! -e "$rootdir/smartpy" ] ; then
        bash <(curl -s https://smartpy.io/cli/install.sh) --prefix "$rootdir/smartpy"
        wget -O "$rootdir/smartpy/templates/FA2.py" https://smartpy.io/templates/FA2.py
    fi

    # Add __init__ to SmartPy and symlink, for python editors
    if [ ! -e "$rootdir/venv/lib/python3.9/site-packages/smartpy" ] ; then
        echo "from smartpy.smartpy import *" > "$rootdir/smartpy/__init__.py"
        ln -s "../../../../smartpy" "$rootdir/venv/lib/python3.9/site-packages/smartpy"
    fi
