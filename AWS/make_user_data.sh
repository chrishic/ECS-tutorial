#!/bin/bash

USER_DATA_TEMPLATE="user_data.sh.tmpl"

die() {
    echo >&2 "=> ERROR: $@"
    exit 1
}

usage() { echo "Usage: $0 <CLUSTER_NUM>"; echo "=> Valid cluster num (1-4)" 1>&2; exit 1; }

if [ "$#" -ne 1 ]; then
    usage;
fi

CLUSTER_NUM=$(($1 + 0))

if [[ $CLUSTER_NUM -lt 1 || $CLUSTER_NUM -gt 4 ]]; then
    usage;
fi

CLUSTER_NAME="tutorial-$CLUSTER_NUM"

# Splice cluster name into user_data.sh template
cat $USER_DATA_TEMPLATE | sed -e 's@__CLUSTER_NAME__@'"$CLUSTER_NAME"'@' >> user_data.sh
