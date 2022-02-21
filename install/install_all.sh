#!/bin/bash

    dir=$(dirname $0)
    "$dir/install_ligo.sh"
    "$dir/install_tezbin.sh"
    "$dir/install_python.sh"
    "$dir/install_pytezos.sh"
    "$dir/install_smartpy.sh"
    "$dir/install_node.sh"
