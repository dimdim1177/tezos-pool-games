#!/bin/bash

    slide="$1"
    sed ':a;N;$!ba;s/[:.\r]\+\?\n/. /g;s/https\?:\S\+//g;s/ *\.[- .]\+/. /g;s/\// /g' "$slide" > "${slide%.slide}.speech"
