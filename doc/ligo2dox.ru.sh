#!/bin/bash

    if [[ "$1" == *.ligo ]] ; then
        dir=$(dirname $0)
        "$dir/ligo2dox/ligo2dox.php" "$1" | "$dir/mlcomment/mlcomment.php" -l RU -n "///" -o "/**" -c "*/" dox -
    else
        cat "$1"
    fi
