#!/bin/bash

    # Debian/Ubuntu only script
    dir=$(dirname $0)
    if ! "$dir/debian_ubuntu.sh" ; then exit 1 ; fi

    # List of packages for install
    install=""

    # Request install python3
    if [ ! -e /usr/bin/python3 ] ; then install="$install python3 python3-venv" ; fi

    # Request install pip3
    if [ ! -e /usr/bin/pip3 ] ; then install="$install pip3" ; fi

    # Install packages
    if [ "" != "$install" ] ; then sudo apt -y install $install ; fi

    # Install Virtual Environment
    rootdir=$(realpath "$dir/..")
    if [ ! -e "$rootdir/venv" ] ; then python3 -m venv "$rootdir/venv" ; fi

