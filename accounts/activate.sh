#!/bin/bash
    dir=$(dirname $0)
    "$dir/../tezbin/tezos-client" -E https://rpc.hangzhounet.teztnets.xyz config update
    find "$dir" -type f -name "*.json" | while read acc_json ; do
        acc=$(basename $acc_json .json)
        "$dir/../tezbin/tezos-client" activate account "$acc" with "$acc_json"
    done
