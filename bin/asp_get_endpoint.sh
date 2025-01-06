#!/bin/bash

# MIT License
# 
# Copyright (c) 2025 Tim Kaune

# $1 argument: File path to ASP header JSON file

err_echo() {
    1>&2 echo -e "$@";
}

check_command() {
    command -v "$@" >/dev/null 2>&1
}

if ! check_command 'grep'; then
    err_echo "Cannot find 'grep'. Please install it."
    exit 1
elif ! check_command 'cat'; then
    err_echo "Cannot find GNU Core Utils. Please install them."
    exit 1
fi

if [[ -z "$1" ]]; then
    err_echo "Usage: asp_get_endpoint.sh <path to header JSON>"
    exit 1
elif ! [[ -f "$1" ]]; then
    err_echo "ASP header file '$1' does not exist."
    exit 1
fi

ASP_KID="$(grep -o -e '"kid": ".*"' "$1")"
ASP_KID="${ASP_KID:8:$((${#ASP_KID} - 8 - 1))}"

cat <<<"/.well-known/aspe/id/${ASP_KID}"
