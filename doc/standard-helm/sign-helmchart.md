# Signing a helm chart, according to the helm docs.

## Preparation

According to the [official helm documentation](https://helm.sh/docs/topics/provenance/) you can sign a helm chart using

```
helm package --sign --key 'John Smith' --keyring path/to/keyring.secret mychart
```

but for that to work, we need a (legacy) gpg format keyring that contains the keys. 

Since we're not taking advantage of Trusted Artifact Signer in this case, you would need self-generated key or a key that has been provided to you from a centralized key management system. However, Trusted Artifact Signer with cosign offers a way around the need for centralized key management, key rotation, key revocation, etc.... (this is the [third](../helm-cosign/cosign-sign-helm.md) option).


You can check if you have gpg keys in your keyring by using
```
gpg --list-keys
```

If you don't have any, you need to create (or import) keys. 

To create a new public/private key pair in GPG, you can follow these steps:

### Step 1: Generate a New Key Pair

Open your terminal and use the following command to start the key generation process:

```
gpg --full-generate-key
```

### Step 2: Follow the Prompts

You will be prompted to enter various pieces of information to generate your key pair. Here’s what you typically need to provide:

1. **Key Type**: You can choose the kind of key you want. The default (`RSA and RSA`) is usually a good choice.
2. **Key Size**: Common sizes are 2048 or 4096 bits. Larger sizes are more secure but take longer to generate and use.
3. **Key Expiration**: You can set an expiration date for your key, or choose to have it never expire.
4. **User Information**: You will need to enter your name, email address, and an optional comment.
5. **Passphrase**: Choose a strong passphrase to protect your private key.

Here is an example of the sequence of prompts and responses:

```
$ gpg --full-generate-key
gpg (GnuPG) 2.4.4; Copyright (C) 2024 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Please select what kind of key you want:
   (1) RSA and RSA
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
   (9) ECC (sign and encrypt) *default*
  (10) ECC (sign only)
  (14) Existing key from card
Your selection? 1
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (3072) 
Requested keysize is 3072 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 1y
Key expires at Sat 28 Jun 2025 12:28:31 CEST
Is this correct? (y/N) y

GnuPG needs to construct a user ID to identify your key.

Real name: Markus Nagel
Email address: mnagel@redhat.com
Comment: 
You selected this USER-ID:
    "Markus Nagel <mnagel@redhat.com>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? o
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.

gpg: directory '/home/mnagel/.gnupg/openpgp-revocs.d' created
gpg: revocation certificate stored as '/home/mnagel/.gnupg/openpgp-revocs.d/0548DE59F37D46F32510C46CFF986D6212934A09.rev'
public and secret key created and signed.

pub   rsa3072 2024-06-28 [SC] [expires: 2025-06-28]
      0548DE59F37D46F32510C46CFF986D6212934A09
uid                      Markus Nagel <mnagel@redhat.com>
sub   rsa3072 2024-06-28 [E] [expires: 2025-06-28]


```

### Step 3: Generate the Key Pair

After confirming the information, GPG will generate the key pair. This might take some time depending on the key size and your system’s performance.

### Step 4: List Your Keys

To verify that your key has been generated, you can list all your keys with:

```
$ gpg --list-keys
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: next trustdb check due at 2025-06-28
/home/mnagel/.gnupg/pubring.kbx
-------------------------------
pub   rsa3072 2024-06-28 [SC] [expires: 2025-06-28]
      0548DE59F37D46F32510C46CFF986D6212934A09
uid           [ultimate] Markus Nagel <mnagel@redhat.com>
sub   rsa3072 2024-06-28 [E] [expires: 2025-06-28]

```

Since gpg v2 uses a newer format, for helm to work with it, it needs to be converted to the legacy format:

```
$ gpg --export >~/.gnupg/pubring.gpg
$ gpg --export-secret-keys >~/.gnupg/secring.gpg
```

## Signing your chart

Now that we have a keyring in OpenPGP format that helm recognizes, we can sign a chart:

```
$ helm create signed-chart
Creating signed-chart

$ helm package --sign --key 'Markus Nagel' --keyring ~/.gnupg/secring.gpg signed-chart/
Password for key "Markus Nagel <mnagel@redhat.com>" >  
Successfully packaged chart and saved it to: /home/mnagel/Documents/appServices/TSSC/computacenter/signed-chart-0.1.0.tgz

```

Note that you now have a provenance file that contains the sha fingerprint of the file as well as a signature.

```

$ ll
total 8
drwxr-xr-x. 1 mnagel mnagel   94 Jun 28 12:39 signed-chart
-rw-r--r--. 1 mnagel mnagel 3970 Jun 28 12:42 signed-chart-0.1.0.tgz
-rw-r--r--. 1 mnagel mnagel  915 Jun 28 12:42 signed-chart-0.1.0.tgz.prov


```

## Verifying your helm chart

*__Note__* The provenance file needs to be distributed (e.g. uploaded to a registry) together with the packaged chart, otherwise verification will fail.

```
$ helm verify signed-chart-0.1.0.tgz
Signed by: Markus Nagel <mnagel@redhat.com>
Using Key With Fingerprint: 0548DE59F37D46F32510C46CFF986D6212934A09
Chart Hash Verified: sha256:2b5b6b688dbe88ef6149aab63a32620e8164e8f4c6a430a5bbb81cece915518e


```
