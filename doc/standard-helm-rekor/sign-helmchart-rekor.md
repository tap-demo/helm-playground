# Adding Transparency as a security layer

Assuming you have a helmchart that has been signed using the `helm --sign` method, the attached provenance file `mypackagedchart.tgz.prov` is used for verification. 

It contains some helm-specific metadata, the sha fingerprint of the chart and the PGP signature.

In theory, some bad actor could tamper with both the chart and the provenance file (so they match again):

While this may be an eloborate attack vector, it is not impossible.

As an additional layer of security, the signed helmchart (well, not the chart itself, but all the metadata, the signature, the sha fingerprint) can be uploaded to the rekor transparency log, that is part of your Trusted Artifact Signer deployment.

This tamper-proof ledger uses [Trillian](https://transparency.dev/), an open source verifiable log that is an implementation of a [Merkle-tree](https://en.wikipedia.org/wiki/Merkle_tree).

## The helm-sigstore plugin

Since Red Hat Trusted Artifact Signer is the Red Hat built and supported version of the Sigstore project, we can use the [helm-sigstore plugin](https://github.com/sigstore/helm-sigstore/tree/main) to add this security layer.

###  Prerequisites

Before we casn start using it, we need to install the plugin:

``` 
$ helm plugin install https://github.com/sigstore/helm-sigstore
Installing helm sigstore plugin
Downloading https://github.com/sigstore/helm-sigstore/releases/download/v0.2.0/helm-sigstore-linux-amd64
helm-sigstore installed into /home/mnagel/.local/share/helm/plugins/helm-sigstore/helm-sigstore

```

## Uploading a signed and packaged helm chart

Since all the details of the signature are stored in the provenance file, this needs to be present for uploading the information to rekor (we're using the signed chart from [Signing a helm chart, according to the helm docs](../standard-helm/sign-helmchart.md) )

``` 
$ ll
total 8
drwxr-xr-x. 1 mnagel mnagel   94 Jun 28 12:39 signed-chart
-rw-r--r--. 1 mnagel mnagel 3970 Jun 28 12:42 signed-chart-0.1.0.tgz
-rw-r--r--. 1 mnagel mnagel  915 Jun 28 12:42 signed-chart-0.1.0.tgz.prov

```

Now we can upload it to our rekor instance  

*__NOTE__* By default, the plugin will upload the entry to the public good instance at https://rekor.sigstore.dev - to use the rekor instance provided by Trusted Artifact Signer, we need to provide the --rekor-server parameter or a REKOR_SERVER environment variable. Given that we have [initialized our environment](../cosign-init/init.md), we can use the systax below:

```
$ helm sigstore upload signed-chart-0.1.0.tgz --rekor-server $SIGSTORE_REKOR_URL

Created Helm entry at index 47, available at: https://rekor-server-trusted-artifact-signer.apps.cluster-v6v8c.sandbox617.opentlc.com/api/v1/log/entries/5b403967758051d4ffa28f0ce26882d14b760af1b68b857df9fe8df40ef9ee864097e23add4fd891
```

If we want to investigate what has being stored, we can simply `curl` the rekor URL provided above it and pretty-print it via `jq`

``` 
curl -s https://rekor-server-trusted-artifact-signer.apps.cluster-v6v8c.sandbox617.opentlc.com/api/v1/log/entries/5b403967758051d4ffa28f0ce26882d14b760af1b68b857df9fe8df40ef9ee864097e23add4fd891 | jq


```

## What about added security?

### Verifying against rekor

Now that we have an entry in the tamper-proof ledger, we can verify if a given helm chart has an entry in the ledger and if the chart that we have is genuine (i.e. hasn't been modified between the time it has been signed, uploaded to rekor and now):

```
$ helm sigstore verify signed-chart-0.1.0.tgz --rekor-server $SIGSTORE_REKOR_URL
Chart Verified Successfully From Helm entry:

Rekor Server: https://rekor-server-trusted-artifact-signer.apps.cluster-v6v8c.sandbox617.opentlc.com
Rekor Index: 47
Rekor UUID: 5b403967758051d4ffa28f0ce26882d14b760af1b68b857df9fe8df40ef9ee864097e23add4fd891

```
This not only finds the entry in the ledger but also compares and verifies characteristics, such as public key, Chart hash and signature between the Rekor entry and the signed chart.



### Searching for the chart in rekor
We can also search and thus check (without validation) if a given signed chart has an entry in the rekor log: 

```
$ helm sigstore search signed-chart-0.1.0.tgz --rekor-server $SIGSTORE_REKOR_URL 
The Following Records were Found

Rekor Server: https://rekor-server-trusted-artifact-signer.apps.cluster-v6v8c.sandbox617.opentlc.com
Rekor UUID: 5b403967758051d4ffa28f0ce26882d14b760af1b68b857df9fe8df40ef9ee864097e23add4fd891

```

### Searching for the chart using the rekor cli

We can also inspect the chart entry using the `rekor-cli` commandline tool:

In the above example, rekor told us it stored the entry at index 47, and UUID `5b403967758051d4ffa28f0ce26882d14b760af1b68b857df9fe8df40ef9ee864097e23add4fd891` so we can find and inspect it using

```
rekor-cli get --log-index 47
```
or
```
rekor-cli get --uuid 5b403967758051d4ffa28f0ce26882d14b760af1b68b857df9fe8df40ef9ee864097e23add4fd891
```

With the rekor cli, you can also search the transparency log for all entries by a given email associated with a signing event:

``` 
$ rekor-cli search --email mnagel@redhat.com
Found matching entries (listed by UUID):
5b403967758051d4ffa28f0ce26882d14b760af1b68b857df9fe8df40ef9ee864097e23add4fd891

```
Similary, searching for an entry about a given artifact is possible:

```
$ rekor-cli search --artifact signed-chart-0.1.0.tgz
Found matching entries (listed by UUID):
5b403967758051d4ffa28f0ce26882d14b760af1b68b857df9fe8df40ef9ee864097e23add4fd891
```

With the UUID, it can be easily retrieved and inspected:

```
$ rekor-cli get --uuid 5b403967758051d4ffa28f0ce26882d14b760af1b68b857df9fe8df40ef9ee864097e23add4fd891
LogID: bd3a7a08de404b5665861ccdf7132a04f4a08db666872890944a1a4dcf1227e5
Index: 47
IntegratedTime: 2024-06-28T13:17:51Z
UUID: 5b403967758051d4ffa28f0ce26882d14b760af1b68b857df9fe8df40ef9ee864097e23add4fd891
Body: {
  "HelmObj": {
    "chart": {
      "hash": {
        "algorithm": "sha256",
        "value": "2b5b6b688dbe88ef6149aab63a32620e8164e8f4c6a430a5bbb81cece915518e"
      },
      "provenance": {
        "signature": {
          "content": " [...]
```
