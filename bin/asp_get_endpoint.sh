#!/bin/bash

# MIT License
# 
# Copyright (c) 2024 Tim Kaune

# $1 argument: File path to ASP header JSON file

if [[ -z "$1" ]]; then
    echo "Usage: asp_get_endpoint.sh <path to header JSON>"
    exit 1
elif ! [[ -f "$1" ]]; then
    echo "ASP header file '$1' does not exist."
    exit 1
fi

ASP_KID="$(cat <"$1" | grep -o -e '"kid": ".*"')"
ASP_KID="${ASP_KID:8: -1}"

cat <<<"/.well-known/aspe/id/${ASP_KID}"
