#!/bin/bash

if [ "$#" -lt 4 ]; then
    echo "Usage: $0 network sender verify script_name [sig] [sig_params...]"
    exit 1
fi

NETWORK=$1
SENDER=$2
VERIFY=$3
SCRIPT=$4

# Check if the SIG which is $5 is provided and if it is then include SIG_PARAMS too
if [[ "$5" != "" && "$5" != -* ]]; then
  SIG=$5
  shift 5
  SIG_PARAMS=("$@")
fi

# forge command
COMMAND="forge script \"$SCRIPT\" --broadcast -i 1 -f \"$NETWORK\" --sender \"$SENDER\""

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
