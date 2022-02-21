#!/bin/bash

    name="$1"
    force="$2"
    if [ "" == "$name" ] || [ "--help" == "$name" ] || [ "-h" == "$name" ] ; then
        echo "Usage: $(basename $0) NAME|ALL [force]"
        echo "Deploy 'build/NAME.tz' inited by 'build/NAME.storage.tz' (or 'build/*.tz' for ALL)"
        echo "by account saved as 'owner' in tezos-client"
        exit;
    fi
    if [ "ALL" == "$name" ] ; then name="*" ; fi
    if [ "force" == "$force" ] ; then force=" --force" ; else force="" ; fi
    
    project_dir="$(dirname $0)"
    build_dir="$project_dir/build"

    echo "--- Search compiled contracts $name in $build_dir ..."
    find "$build_dir" -maxdepth 1 -type f -name "$name.tz" | while read contract_tz ; do
        if [[ $contract_tz == *.storage.tz ]] ; then continue ; fi
        contract_name="$(basename $contract_tz '.tz')"
        storage_tz="$build_dir/$contract_name.storage.tz"
        if [ ! -e "$storage_tz" ] ; then
            echo "Warning: Not found $storage_tz, can't deploy contract $contract_name"
            continue
        fi
        echo "   --- Deploy contract $contract_name ..."
        contract_address=$("$project_dir/tezbin/tezos-client" list known contracts 2>/dev/null | grep -E -o "^$contract_name: KT[^ ]+" | grep -E -o "KT[^ ]+$")
        if [ "" == "$force" ] && [ "$contract_address" != "" ] ; then
            echo "   === $contract_name already deployed to $contract_address"
            continue
        fi
        deploy_log="$build_dir/$contract_name.deploy.log"
        if "$project_dir/tezbin/tezos-client" originate contract "$contract_name" transferring 0 from owner running "$contract_tz" --init "$(cat $storage_tz)" --burn-cap 10.0 $force 2>&1 > >(tee "$deploy_log") ; then
            echo "   === OK"
        else 
            echo "   === FAIL deploy $contract_name"
        fi
        if [ ! -s "$deploy_log" ] ; then rm "$deploy_log" ; fi
    done
    echo "=== contracts"
