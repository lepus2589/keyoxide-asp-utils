# Keyoxide Ariadne Signature Profile (ASP) Utils #

This project contains a few shell scripts to manually craft ASPs.

## Prerequesites ##

These bash scripts use the following programs:

- `bash` (obviously)
- `openssl`
- `xxd`
- `sed`
- `grep`
- GNU core utilities

Please make sure you install the relevant packages using your distribution's
package manager.

## ASP Structure ##

Your ASP is basically a special JSON Web Token (JWT). It's a long, random
looking string which consists of three parts. Each part is a base64 encoded
string and they are concatenated with single dots (`.`). The first part is the
ASP header, the second part is called ASP payload, and the third part contains
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
$ openssl genpkey -algorithm ED25519 -aes-256-cbc -out "./key/asp.key.pem"
```

Create the key for the ES256 signature type like this:

```shell
$ openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -aes-256-cbc -out "./key/asp.key.pem"
```

Both commands use AES256 symmetric encryption for the private key. You will be
prompted for a passphrase. Remember it well, otherwise, your key is lost and
cannot be recovered. Consider using a password manager. You should NOT remove
the `-aes-256-cbc` flag to create an unencrypted private key. Anybody who get's
access to this key file could maliciously manipulate your ASP.

[ariadne-signature-profile-0]: <https://ariadne.id/related/ariadne-signature-profile-0/>

## Test/Change Key Passphrase ##

You can test the current password with

```shell
$ openssl pkey -in ./key/asp.key.pem -pubout -text
```

You can change your private key's password later like this:

```shell
$ openssl pkey -in ./key/asp.key.pem -out ./key/asp.key.pem.new -aes-256-cbc
```

If the private key is password protected (as it should be), `openssl` will ask
for your password. Then you'll be prompted for the new password.

## Create ASP Header ##

Create the ASP header cleartext JSON file with:

```shell
$ ./bin/asp_make_header.sh "./key/asp.key.pem" > "./dist/asp_header.json"
```

This is a one-time operation. A cryptographic key will always produce the exact
same header JSON file. If the private key is password protected (as it should
be), `openssl` will ask for your password to extract the public part of the key.

You can inspect your `asp_header.json` in any text editor. It contains your
ASP's fingerprint (`kid`) as well as the public part of your key in JSON Web Key
(JWK) format. This is intended to and safe to publish! Don't modify the file
manually. If you do accidentally, recreate it with the above command.

## Create/Edit ASP Payload ##

1. If you don't already have an ASP payload JSON file, copy the ASP payload
   template file to the `dist` folder:

   ```shell
   $ cp ./src/asp_payload.template.json ./dist/asp_payload.json
   ```

2. Open `./dist/asp_payload.json` in your favorite editor. Enter or update your
   information in the respective fields. Delete the optional fields you don't
   need. Refer to the [Keyoxide Docs][service-providers] for claim formatting.

3. Add or update the expiration date of your ASP with

   ```shell
   $ ./bin/asp_expire.sh "./dist/asp_payload.json" "2025-01-01 00:00:00+00:00"
   ```

[service-providers]: <https://docs.keyoxide.org/service-providers/>

## Create ASP ##

When you're finished editing your ASP payload JSON, create your latest ASP with

```shell
$ mkdir -p "./dist/.well-known/aspe/id"
$ ./bin/asp_make.sh "./key/asp.key.pem" "./dist/asp_header.json" "./dist/asp_payload.json" > "./dist$(./bin/asp_get_endpoint.sh "./dist/asp_header.json")"
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
