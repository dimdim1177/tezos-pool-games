#!/bin/bash

    # Install python3, if Debian/Ubuntu
    dir=$(dirname $0)
    "$dir/install_python.sh"

    # Install pytezos
    rootdir=$(realpath "$dir/..")
    if [ ! -e "$rootdir/venv/lib/python3.9/site-packages/pytezos" ] ; then
        source  "$rootdir/venv/bin/activate" && pip3 install pytezos && deactivate
    fi
