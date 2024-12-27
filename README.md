# Keyoxide Ariadne Signature Profile (ASP) Utils #

This project contains a few shell scripts to manually craft ASPs.

## Prerequesites ##

These shell scripts use the `openssl` program as well as some of the GNU core
utilities. Please make sure you install the relevant packages using your
distribution's package manager.

## ASP Structure ##

Your ASP is basically a special JSON Web Token (JWT). It's a long, random
looking string which consists of three parts. Each part is a base64 encoded
string and they are concatenated with single dots (`.`). The first part is the
ASP header, the second part is called ASP payload, and the third part cointains
the digital signature over the first two parts using a cryptographic key.

## Key Creation ##

To craft an ASP, you first need a cryptographic key. The [Ariadne Signature
Profile Specification][ariadne-signature-profile-0] allows only two types
signature algorithms:

- EdDSA with curve Ed25519
- ES256 with curve P-256.

To use either signature type, you need a key with the corresponding algorithm
and curve. Create the key for the EdDSA signature type like this:

```shell
$ openssl genpkey -algorithm ED25519 -aes-256-cbc -out ./key/asp.key.pem
```

Create the key for the ES256 signature type like this:

```shell
$ openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -aes-256-cbc -out ./key/asp.key.pem
```

Both commands use AES256 symmetric encryption for the private key. You will be
prompted for a passphrase. Remember it well, otherwise, your key is lost and
cannot be recovered. Consider using a password manager. You should NOT remove
the `-aes-256-cbc` flag to create an unencrypted private key. Anybody who get's
access to this key file could maliciously manipulate your ASP.

[ariadne-signature-profile-0]: <https://ariadne.id/related/ariadne-signature-profile-0/>

## Create ASP Header ##

Create the ASP header cleartext JSON file with:

```shell
$ ./bin/make_asp_header.sh ./key/asp.key.pem > ./dist/asp_header.json
```

If the private key is password protected (as it should be), `openssl` will ask
for your password to extract the public part of the key.

You can inspect your `asp_header.json` in any text editor. It contains your
ASP's fingerprint (`kid`) as well as the public part of your key in JSON Web Key
(JWK) format. This is intended to and safe to publish!

## Create/Edit ASP Payload ##

Copy the ASP payload template file to the `dist` folder:

```shell
$ cp ./src/asp_payload.template.json ./dist/asp_payload.json
```

Open `./dist/asp_payload.json` in your favorite editor. Enter your information
in the respective fields. Delete the optional fields you don't need. Refer to
the [Keyoxide Docs][service-providers] for claim formatting.

[service-providers]: <https://docs.keyoxide.org/service-providers/>

## Create ASP ##

When you're finished editing your ASP payload JSON, create your latest ASP with

```shell
$ mkdir -p ./dist/.well-known/aspe/id
$ ./bin/make_asp.sh ./key/asp.key.pem ./dist/asp_header.json ./dist/asp_payload.json > "./dist$(./bin/asp_get_endpoint.sh ./dist/asp_header.json)"
```

If the private key is password protected (as it should be), `openssl` will ask
for your password to create the signature.

## Upload ASP ##

Publish your ASP on your own website by uploading the `./dist/.well-known`
folder to the root folder of your website. You can deploy it to GitHub pages,
for example.

## Check ASP ##

Print your ASP's URI with

```shell
$ ./bin/asp_get_uri.sh ./dist/asp_header.json domain.tld
aspe:<domain.tld>:<ASP fingerprint>
```

Go to [keyoxide.org](https://keyoxide.org/) and paste the URI in the search
field. Keyoxide should find and parse your profile.
