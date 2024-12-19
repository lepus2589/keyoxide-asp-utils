#!/bin/bash

# MIT License
# 
# Copyright (c) 2024 Tim Kaune

# Input: Ed25519 private key file in PEM format

minify_json() {
    tr -d '\r\n' | sed -r -e 's/(\[|\{|,)[ \t]+"/\1"/g' -e 's/":[ \t]/":/g' -e 's/[ \t]+(\]|\})/\1/g'
}

# $2 must be the ASP header JSON file
ASP_HEADER_ENC="$(minify_json < "$2" | basenc -w 0 --base64url | tr -d '=')"
# $3 must be the ASP payload JSON file
ASP_PAYLOAD_ENC="$(minify_json < "$3" | basenc -w 0 --base64url | tr -d '=')"

echo -n -E "${ASP_HEADER_ENC}.${ASP_PAYLOAD_ENC}" > "./temp.signature.txt"

ASP_SIGNATURE_ENC="$(openssl pkeyutl -rawin -in "./temp.signature.txt" -sign -inkey "$1" | basenc -w 0 --base64url | tr -d '=')"

rm "./temp.signature.txt"

echo "${ASP_HEADER_ENC}.${ASP_PAYLOAD_ENC}.${ASP_SIGNATURE_ENC}"
