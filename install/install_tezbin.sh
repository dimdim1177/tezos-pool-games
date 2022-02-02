#!/bin/bash

    # Download Tezos binaries
    rootdir=$(realpath "$(dirname $0)/..")
    tezbin="$rootdir/tezbin"
    for bin in "tezos-client" "tezos-signer" ; do
        if [ ! -e "$tezbin/$bin" ] ; then
            mkdir -p "$tezbin"
            wget -O "$tezbin/$bin" "https://github.com/serokell/tezos-packaging/releases/download/v11.1-1/$bin"
            chmod +x "$tezbin/$bin"
        fi
    done
