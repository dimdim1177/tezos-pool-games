#!/bin/bash

    # Debian/Ubuntu only script
    if ! "$(dirname $0)/debian_ubuntu.sh" ; then exit 1 ; fi

    # List of packages for install
    install=""

    # Request install NodeJS
    if [ ! -e /usr/bin/nodejs ] ; then install="$install nodejs" ; fi

    # Request install npm
    if [ ! -e /usr/bin/npm ] ; then install="$install npm" ; fi

    # Install packages and update npm
    if [ "" != "$install" ] ; then
        sudo apt -y install $install && sudo npm -g update npm
    fi

    # Install yarn
    if [ ! -e /usr/local/bin/yarn ] ; then
        sudo npm -g install yarn
    fi
