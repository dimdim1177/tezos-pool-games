#!/bin/bash

    dir=$(dirname $0)
    "$dir/ligo2dox/ligo2dox.php" "$1" | "$dir/mlcomment/mlcomment.php" -l EN -n "///" -o "/**" -c "*/" dox -
