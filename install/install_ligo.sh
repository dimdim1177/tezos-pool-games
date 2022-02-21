#!/bin/bash

    # Debian/Ubuntu only script
    dir=$(dirname $0)
    if ! "$dir/debian_ubuntu.sh" ; then exit 1 ; fi

    # Download and install LIGO package
    if [ "force" == "$1" ] || [ ! -e /usr/local/bin/ligo ] ; then
        wget -O "$dir/ligo.deb" "https://ligolang.org/deb/ligo.deb"
        sudo dpkg -i "$dir/ligo.deb"
        rm -f "$dir/ligo.deb"
        ligo version
    fi
