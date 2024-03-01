#!/bin/bash

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 network verify script_name [sig] [sig_params...]"
    exit 1
fi

source .env

NETWORK=$1
VERIFY=$2
SCRIPT=$3

# Check if the SIG which is $4 is provided and if it is then include SIG_PARAMS too
if [[ "$4" != "" && "$5" != -* ]]; then
  SIG=$4
  shift 4
  SIG_PARAMS=("$@")
fi

# forge command
COMMAND="forge script \"$SCRIPT\" --broadcast -i 1 -f \"$NETWORK\" --sender \"$DEPLOYER_ADDRESS\""

if [ "$VERIFY" -eq 1 ]; then
    COMMAND="$COMMAND --verify"
fi

if [ ! -z "$SIG" ]; then
    COMMAND="$COMMAND -s \"$SIG\""
    if [ ! -z "${SIG_PARAMS[*]}" ]; then
        for PARAM in "${SIG_PARAMS[@]}"; do
            COMMAND="$COMMAND \"$PARAM\""
        done
    fi
fi

eval $COMMAND
