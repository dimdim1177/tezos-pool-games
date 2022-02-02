#!/bin/bash

    # Check Debian/Ubuntu
    os=$(lsb_release -is)
    if [ "Debian" != "$os" ] && [ "Ubuntu" != "$os" ] ; then
        echo "Debian/Ubuntu only script"
        exit 1
    fi
