#!/bin/bash

# MIT License
# 
# Copyright (c) 2025 Tim Kaune

# $1 argument: File path to ASP payload JSON file
# $2 argument: expiration date in ISO8601 format

err_echo() {
    1>&2 echo -e "$@";
}

check_command() {
    command -v "$@" >/dev/null 2>&1
}

if ! check_command 'grep'; then
    err_echo "Cannot find 'grep'. Please install it."
    exit 1
elif ! check_command 'sed'; then
    err_echo "Cannot find 'sed'. Please install it."
    exit 1
elif ! check_command 'date'; then
    err_echo "Cannot find GNU Core Utils. Please install them."
    exit 1
fi

if [[ -z "$2" ]] || [[ -z "$1" ]]; then
    err_echo "Usage: asp_expire.sh <path to payload JSON> <expiration date>"
    exit 1
elif ! [[ -f "$1" ]]; then
    err_echo "ASP payload file '$1' does not exist."
    exit 1
fi

EXPIRATION_AS_EPOCH="$(date --date "$2" +"%s")"

EXP_REGEX='"exp": [0-9]*'
PROFILE_MATCH='"http://ariadne.id/type": "profile"'
EXP_REPLACE="\"exp\": ${EXPIRATION_AS_EPOCH}"

if grep -q -i "${EXP_REGEX}" "$1"; then
    sed -r -i'.old' -e "s/${EXP_REGEX}/${EXP_REPLACE}/" "$1"
else
    sed -r -i'.old' -e "s|${PROFILE_MATCH}|${PROFILE_MATCH},\n    ${EXP_REPLACE}|" "$1"
fi

rm "${1}.old"

echo "${EXP_REPLACE}"
