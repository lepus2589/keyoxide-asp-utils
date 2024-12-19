#!/bin/bash

# MIT License
# 
# Copyright (c) 2024 Tim Kaune

# Input: Ed25519 private key file in PEM format

ASP_HEADER_JWK_X="$( \
    openssl pkey -in "$1" -pubout -outform DER | \
    # extract fwk.x
    tail -c +13 | \
    head -c 32 | \
    basenc -w 0 --base64url | \
    tr -d '=' \
)"

ASP_HEADER_KID="$( \
    echo -n -E "{\"crv\":\"Ed25519\",\"kty\":\"OKP\",\"x\":\"${ASP_HEADER_JWK_X}\"}" | \
    sha512sum | \
    # strip filename
    cut -d " " -f 1 | \
    xxd -r -p | \
    head -c 16 | \
    basenc -w 0 --base32 | \
    tr -d '=' \
)"

cat <<EOF
{
    "typ": "JWT",
    "kid": "${ASP_HEADER_KID}",
    "jwk": {
        "kty": "OKP",
        "use": "sig",
        "crv": "Ed25519",
        "x": "${ASP_HEADER_JWK_X}"
    },
    "alg": "EdDSA"
}
EOF
