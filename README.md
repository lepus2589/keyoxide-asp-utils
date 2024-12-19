# Keyoxide Ariadne Signature Profile (ASP) Utils #

This project contains a few shell scripts to manually craft ASPs.

Create the ASP header JSON file with:

```shell
$ ./bin/make_asp_header.sh ./key/asp.key.pem > ./dist/asp_header.json
```

If the private key is password protected (as it should be), `openssl` will ask
for your password.

Create your latest ASP with

```shell
$ ./bin/make_asp.sh ./key/asp.key.pem ./dist/asp_header.json ./src/asp_payload.json > ./dist/asp.txt
```
