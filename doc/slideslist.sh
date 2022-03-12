#!/bin/bash

    path="$1"

    find "$path" | grep -E "[0-9]+\.mp4$" | sort | while read f ; do echo "file '$(realpath $f)'"; done
