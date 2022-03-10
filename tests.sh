#!/bin/bash

    name="$1"
    if [ "" == "$name" ] || [ "--help" == "$name" ] || [ "-h" == "$name" ] ; then
        echo "Usage: $(basename $0) NAME|ALL"
        echo "Execute tests 'tests/NAME.ligo' or 'tests/*.ligo' for ALL"
        echo "Logs saved to 'build/NAME.test.log' files"
        exit;
    fi
    if [ "ALL" == "$name" ] ; then name="*" ; fi

    project_dir="$(dirname $0)"
    tests_dir="$project_dir/tests"
    build_dir="$project_dir/build"

    RED='\e[0;31m'
    NOCOLOR='\e[0m'

    echo "--- Search tests $name in $tests_dir ..."
    find "$tests_dir" -maxdepth 1 -type f -name "$name.ligo" | while read test_ligo ; do
        test_name="$(basename $test_ligo '.ligo')"
        test_log="$build_dir/$test_name.test.log"
        echo "   --- Test $test_name"
        log=$(ligo run test "$test_ligo" 2>&1)
        echo "$log" > "$test_log"
        echo -e "${log//exited with value false/"${RED}exited with value false${NOCOLOR}"}"
        if echo "$log" | grep "exited with value false" >/dev/null ; then
            echo "   === FAIL test $test_name"
        else
            echo "   === OK"
        fi
    done
    echo "=== tests"
