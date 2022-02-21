#!/bin/bash

    name="$1"
    if [ "" == "$name" ] || [ "--help" == "$name" ] || [ "-h" == "$name" ] ; then
        echo "Usage: $(basename $0) NAME|ALL"
        echo "Compile 'contracts/NAME.ligo' or 'contracts/*.ligo' for ALL"
        echo "Compiled files saved to 'build/NAME.tz' and 'build/NAME.storage.tz' files"
        exit;
    fi
    if [ "ALL" == "$name" ] ; then name="*" ; fi

    project_dir="$(dirname $0)"
    contracts_dir="$project_dir/contracts"
    build_dir="$project_dir/build"

    echo "--- Search contracts $name in $contracts_dir ..."
    find "$contracts_dir" -maxdepth 1 -type f -name "$name.ligo" | while read contract_ligo ; do
        contract_name="$(basename $contract_ligo '.ligo')"
        contract_tz="$build_dir/$contract_name.tz"
        contract_log="$build_dir/$contract_name.log"
        echo "   --- Compile contract $contract_ligo to $contract_tz"
        if ligo compile contract "$contract_ligo" > "$contract_tz" 2> >(tee "$contract_log" >&2) ; then
            echo "   === OK"
        else 
            echo "   === FAIL compile contract $contract_name"
        fi
        # Remove empty log
        if [ ! -s "$contract_log" ] ; then rm "$contract_log" ; fi
        config_ligo="$contracts_dir/$contract_name/config.ligo"
        storage_ligo="$contracts_dir/$contract_name/initial_storage.ligo"
        if [ -e "$storage_ligo" ] ; then
            storage_tz="$build_dir/$contract_name.storage.tz"
            storage_log="$build_dir/$contract_name.storage.log"
            echo "   --- Compile contract $contract_name storage $storage_ligo to $storage_tz"
            if [ -e "$config_ligo" ] ; then config="$(cat $config_ligo)" ; else config="" ; fi
            owner_address=$($project_dir/tezbin/tezos-client show address owner 2>/dev/null| grep "^Hash:"|grep -E -o "[^ ]+$")
            admin_address=$($project_dir/tezbin/tezos-client show address admin 2>/dev/null| grep "^Hash:"|grep -E -o "[^ ]+$")
            # Cut comments, else ligo failed with magic errors
            storage=$(echo -e "$config\n\n$(cat $storage_ligo)" | sed 's/\/\/.*//g' | sed 's/\[\@inline\].*//g')
            # Fill OWNER_ADDRESS and ADMIN_ADDRESS in contract
            storage=$(echo "$storage" | sed "s/OWNER_ADDRESS/$owner_address/g" | sed "s/ADMIN_ADDRESS/$admin_address/g")
            if ligo compile storage "$contract_ligo" "$storage" > "$storage_tz" 2> >(tee "$storage_log" >&2) ; then
                echo "   === OK"
            else 
                echo "   === FAIL compile storage"
            fi
            # Remove empty log
            if [ ! -s "$storage_log" ] ; then rm "$storage_log" ; fi
        else
            echo "   Warning: Not found contract $contract_name storage $storage_ligo"
        fi
    done
    echo "=== contracts"
