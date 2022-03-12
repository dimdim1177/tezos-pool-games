#!/bin/bash

    dir=$(dirname $0)

    install=""

    # Festival English
    if [ ! -e /usr/share/festival/voices/us/cmu_us_slt_arctic_hts ] ; then  install="$install festvox-us-slt-hts" ; fi

    # Festival Russian
    if [ ! -e /usr/share/festival/voices/russian/msu_ru_nsh_clunits ] ; then install="$install festvox-ru" ; fi

    # Imagemagick
    if [ ! -e /usr/bin/convert ] ; then  install="$install imagemagick" ; fi

    # FFMpeg
    if [ ! -e /usr/bin/ffmpeg ] ; then  install="$install ffmpeg" ; fi

    # Install packages
    if [ "" != "$install" ] ; then sudo apt -y install $install ; fi

    find "$dir/slides-en" -name "*.slide" -exec "$dir/slide2speech.sh" '{}' \;
    find "$dir/slides-en" -name "*.speech" -exec bash -c 'text2wave -eval "(voice_cmu_us_slt_arctic_hts)" -o "${1%.speech}.wav" "$1"' - '{}' \;
    find "$dir/slides-en" -name "*.slide" -exec "$dir/slide2png.sh" '{}' \;
    find "$dir/slides-en" -name "*.slide" -exec "$dir/slide2mp4.sh" '{}' \;
    ffmpeg -f concat -safe 0 -y -i <("$dir/slideslist.sh" "$dir/slides-en") -c copy "$dir/slides-en/video.mp4" > /dev/null

    find "$dir/slides-ru" -name "*.slide" -exec "$dir/slide2speech.sh" '{}' \;
    find "$dir/slides-ru" -name "*.speech" -exec bash -c 'text2wave -eval "(voice_msu_ru_nsh_clunits)" -o "${1%.speech}.wav" "$1"' - '{}' \;
    find "$dir/slides-ru" -name "*.slide" -exec "$dir/slide2png.sh" '{}' \;
    find "$dir/slides-ru" -name "*.slide" -exec "$dir/slide2mp4.sh" '{}' \;
    ffmpeg -f concat -safe 0 -y -i <("$dir/slideslist.sh" "$dir/slides-ru") -c copy "$dir/slides-ru/video.mp4" > /dev/null
