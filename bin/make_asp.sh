#!/bin/bash

# MIT License
# 
# Copyright (c) 2024 Tim Kaune

# $1 argument: File path to private key in PEM format
# $2 argument: File path to ASP header JSON file
# $3 argument: File path to ASP payload JSON file

strip_padding() {
    tr -d '='
}

base64url_encode() {
    basenc -w 0 --base64url
}

minify_json() {
    tr -d '\r\n' | \
    sed -r -e 's/(\[|\{|,)[ \t]+"/\1"/g' -e 's/":[ \t]/":/g' -e 's/[ \t]+(\]|\})/\1/g'
}

if [[ -z "$3" ]] || [[ -z "$2" ]] || [[ -z "$1" ]]; then
    echo "Usage: make_asp.sh <path to private key> <path to header JSON> <path to payload JSON>"
    exit 1
elif ! [[ -f "$1" ]]; then
    echo "Key file '$1' does not exist."
    exit 1
elif ! [[ -f "$2" ]]; then
    echo "ASP header file '$2' does not exist."
    exit 1
elif ! [[ -f "$3" ]]; then
    echo "ASP payload file '$3' does not exist."
    exit 1
fi

ASP_HEADER="$(cat <"$2")"
ASP_HEADER_ENC="$(minify_json <<<"${ASP_HEADER}" | base64url_encode | strip_padding)"
ASP_PAYLOAD_ENC="$(minify_json <"$3" | base64url_encode | strip_padding)"

ASP_ALG="$(cat <<<"${ASP_HEADER}" | grep -o -e '"alg": ".*"')"
ASP_ALG="${ASP_ALG:8: -1}"

if [[ "${ASP_ALG}" = "EdDSA" ]]; then
    printf %s "${ASP_HEADER_ENC}.${ASP_PAYLOAD_ENC}" >"./temp.signature.txt"

    ASP_SIGNATURE_ENC="$( \
        openssl pkeyutl -rawin -in "./temp.signature.txt" -sign -inkey "$1" | \
        base64url_encode | \
        strip_padding \
    )"

    rm "./temp.signature.txt"
elif [[ "${ASP_ALG}" = "ES256" ]]; then
    PARSED_ASN1DER_SIGNATURE="$( \
        printf %s "${ASP_HEADER_ENC}.${ASP_PAYLOAD_ENC}" | \
        # openssl creates the signature in ASN1 DER format
        openssl dgst -sha256 -sign "$1" -binary | \
        # parse it to get the r and s parameters of the signature
        openssl asn1parse -inform DER
    )"

    # get the hex string for r from the parsed ouput
    ECDSA_SIGNATURE_R="$( \
        cat <<<"${PARSED_ASN1DER_SIGNATURE}" | \
        tail -n 2 | \
        head -n 1 | \
        grep -o -e '[0-9A-F]*$'
    )"

    # add zero padding until 32Bytes are reached
    while [[ "${#ECDSA_SIGNATURE_R}" -lt 64 ]]; do
        ECDSA_SIGNATURE_R="0${ECDSA_SIGNATURE_R}"
    done

    # get the hex string for 2 from the parsed ouput
    ECDSA_SIGNATURE_S="$( \
        cat <<<"${PARSED_ASN1DER_SIGNATURE}" | \
        tail -n 1 | \
        grep -o -e '[0-9A-F]*$'
    )"

    # add zero padding until 32Bytes are reached
    while [[ "${#ECDSA_SIGNATURE_S}" -lt 64 ]]; do
        ECDSA_SIGNATURE_S="0${ECDSA_SIGNATURE_S}"
    done

    # create IEEE P1363 format signature from r and s
    ASP_SIGNATURE_ENC="$( \
        printf %s "${ECDSA_SIGNATURE_R}${ECDSA_SIGNATURE_S}" | \
        xxd -r -p | \
        base64url_encode | \
        strip_padding \
    )"
else
    echo "Unsupported sign algorithm! ASPs only support EdDSA and ES256."
    exit 1
fi

cat <<<"${ASP_HEADER_ENC}.${ASP_PAYLOAD_ENC}.${ASP_SIGNATURE_ENC}"
