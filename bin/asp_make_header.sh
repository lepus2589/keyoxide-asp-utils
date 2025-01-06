#!/bin/bash

# MIT License
# 
# Copyright (c) 2025 Tim Kaune

# $1 argument: File path to private key in PEM format

err_echo() {
    1>&2 echo -e "$@";
}

check_command() {
    command -v "$@" >/dev/null 2>&1
}

strip_padding() {
    tr -d '='
}

get_public_key() {
    local KEY_FILE_PATH="$1"

    openssl pkey -in "${KEY_FILE_PATH}" -pubout
}

get_public_key_info() {
    openssl pkey -pubin -noout -text
}

extract_ed25519_parameter() {
    openssl pkey -pubin -pubout -outform DER | \
    # extract fwk.x
    tail -c 32 | \
    basenc -w 0 --base64url | \
    strip_padding
}

calculate_ed25519_thumbprint() {
    local ASP_HEADER_JWK_X="$1"

    printf %s "{\"crv\":\"Ed25519\",\"kty\":\"OKP\",\"x\":\"${ASP_HEADER_JWK_X}\"}" | \
    sha512sum | \
    # strip filename from sha512sum output
    cut -d " " -f 1 | \
    # parse hex encoding to binary
    xxd -r -p | \
    head -c 16 | \
    basenc -w 0 --base32 | \
    strip_padding
}

extract_es256_x_parameter() {
    openssl pkey -pubin -pubout -outform DER | \
    # extract fwk.x
    tail -c 64 | \
    head -c 32 | \
    basenc -w 0 --base64url | \
    strip_padding
}

extract_es256_y_parameter() {
    openssl pkey -pubin -pubout -outform DER | \
    # extract fwk.y
    tail -c 32 | \
    basenc -w 0 --base64url | \
    strip_padding
}

calculate_es256_thumbprint() {
    local ASP_HEADER_JWK_X="$1"
    local ASP_HEADER_JWK_Y="$2"

    printf %s "{\"crv\":\"P-256\",\"kty\":\"EC\",\"x\":\"${ASP_HEADER_JWK_X}\",\"y\":\"${ASP_HEADER_JWK_Y}\"}" | \
    sha512sum | \
    # strip filename from sha512sum output
    cut -d " " -f 1 | \
    # parse hex encoding to binary
    xxd -r -p | \
    head -c 16 | \
    basenc -w 0 --base32 | \
    strip_padding
}

if ! check_command 'openssl'; then
    err_echo "Cannot find 'openssl'. Please install openssl client package."
    exit 1
elif ! check_command 'xxd'; then
    err_echo "Cannot find 'xxd'. Please install it."
    exit 1
elif ! check_command 'basenc'; then
    err_echo "Cannot find GNU Core Utils. Please install them."
    exit 1
fi

if [[ -z "$1" ]]; then
    err_echo "Usage: asp_make_header.sh <path to private key>"
    exit 1
elif ! [[ -f "$1" ]]; then
    err_echo "Key file '$1' does not exist."
    exit 1
fi

PUBLIC_KEY_PEM="$(get_public_key "$1")"
PUBLIC_KEY_INFO="$(cat <<<"${PUBLIC_KEY_PEM}" | get_public_key_info)"

shopt -s nocasematch

if [[ "${PUBLIC_KEY_INFO}" =~ Ed25519 ]]; then
    ASP_HEADER_JWK_X="$(cat <<<"${PUBLIC_KEY_PEM}" | extract_ed25519_parameter)"
    ASP_HEADER_KID="$(calculate_ed25519_thumbprint "${ASP_HEADER_JWK_X}")"

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
elif [[ "${PUBLIC_KEY_INFO}" =~ P-256 ]]; then
    ASP_HEADER_JWK_X="$(cat <<<"${PUBLIC_KEY_PEM}" | extract_es256_x_parameter)"
    ASP_HEADER_JWK_Y="$(cat <<<"${PUBLIC_KEY_PEM}" | extract_es256_y_parameter)"
    ASP_HEADER_KID="$(calculate_es256_thumbprint "${ASP_HEADER_JWK_X}" "${ASP_HEADER_JWK_Y}")"

    cat <<EOF
{
    "typ": "JWT",
    "kid": "${ASP_HEADER_KID}",
    "jwk": {
        "kty": "EC",
        "use": "sig",
        "crv": "P-256",
        "x": "${ASP_HEADER_JWK_X}",
        "y": "${ASP_HEADER_JWK_Y}"
    },
    "alg": "ES256"
}
EOF
else
    err_echo "Unsupported key type! ASPs only support EdDSA/Ed25519 and ES256/P-256 keys."
    exit 1
fi
