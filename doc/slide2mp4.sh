#!/bin/bash

    slide="$1"

    ffmpeg -y -i "${slide%.slide}.png" -i "${slide%.slide}.wav" "${slide%.slide}.mp4" > /dev/null
