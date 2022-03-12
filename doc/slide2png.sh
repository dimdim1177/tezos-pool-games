#!/bin/bash

    slide="$1"

    convert -size 1920x1080 xc:white -pointsize 60 -fill black -draw "text 100,150 '$(cat $slide)'" "${slide%.slide}.png"
