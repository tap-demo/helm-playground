# Key-based signing and verification

While keyless signing should be preferred (as it is one of the core features of Sigstore / Trusted Artifact Signer) and simplifies security and integrity significantly, it might not be suitable or possible in all cases.

Cosign also supports key-based signing and verification - but adds the transparency security layer (it stores the signing events in the tamper-proof rekor log for verification).

## Preparation

Before we can sign with long-lived keys, we need those keys, either via receiving them from a central key management instance, from a KMS (key management system, such as Hashicorp Vault, or generating them - optionally also storing them in a KMS).

1) For local use, key can be generated using 

```
cosign generate-key-pair
```

2) Since we're working in an OpenShift environment (even though sometimes locally) we can also use OpenShift/Kubernetes as KMS. The key pair and password will be stored in a Kubernetes secret in the current k8s context (so we need to login to our cluster of choice):

```
$ cosign generate-key-pair k8s://signing-secrets/cosign-signing-secret
Enter password for private key: 
Enter password for private key again: 
Successfully created secret cosign-signing-secret in namespace signing-secrets
Public key written to cosign.pub

```
(It can be any project, you could also store the secrets in the trusted-artifact-signer project, as long as the user has access to the project)

The public key (`cosign.pub`) is written to the local directory, but also part of the secret:

```
$ oc get secret/cosign-signing-secret -o yaml
apiVersion: v1
data:
  cosign.key: LS0tLS1CRUdJTiBFTkNSWVBURUQgU0lHU1RPUkUgUFJJVkFURSBLRVktLS0tLQpleUpyWkdZaU9uc2libUZ0WlNJNkluTmpjbmx3ZENJc0luQmhjbUZ0Y3lJNmV5Sk9Jam8yTlRVek5pd2ljaUk2Ck9Dd2ljQ0k2TVgwc0luTmhiSFFpT2lKVFNVOXVNR2RIY2xoUFVWbEtVWFpaYjBVMWRsRmphWGRFUm1ORFNUbGoKWm04MVJFMTRablkxZVcwNFBTSjlMQ0pqYVhCb1pYSWlPbnNpYm1GdFpTSTZJbTVoWTJ3dmMyVmpjbVYwWW05NApJaXdpYm05dVkyVWlPaUl2V2pVM01uRnNUSEpXUWtoTE1UbEtjbVV6TTJsVlpEYzBaR3hYSzNvM1lpSjlMQ0pqCmFYQm9aWEowWlhoMElqb2lkMmREWlVGb1pHdFhXSEYzTVdweU1XSmlZbTR4UkhoWVowVnpkVE5LWm1GR2RUQXoKUlRKVFQxWkJaa1IyTUVGcE1ucFRURlpYYmxGRGFraE9NRXR1ZVVsRlJFVlRhR2xNU21GblFreFVlR05YWTFKVApZVFo1VTNwbU16VlhVa0ZTTTIxeGVrc3pNbnBsUzFwU1RVdFJWV2xYYm5CSVNFTkNTV3RHWkhGVVdsYzVTa1V6ClJVUTVaRXMyTUV4QlNrUkRXbkZUZG1KUVNFUlFUMk0zVTJVNE5ubHhjU3RPUTFKRWRsaEdRMFYwV0VKdU9ETmsKUTFsMU9YQkdjV3R6VG04eWVqRjVNbXd3YmpKcmVFNTFZbEU5UFNKOQotLS0tLUVORCBFTkNSWVBURUQgU0lHU1RPUkUgUFJJVkFURSBLRVktLS0tLQo=
  cosign.password: cGFzc3dvcmQ=
  cosign.pub: LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUZrd0V3WUhLb1pJemowQ0FRWUlLb1pJemowREFRY0RRZ0FFSE9hSTBHZzJOd0xVYS9pZ2xmWWlwVXVvbDZtawpkYi9WejhKZ3gzbjduLy9zQm95Nk1VVWhISDZkbEluMTB2QUhwc3NlT1pmRnFrSk5TSERHNDJhckZRPT0KLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg==
immutable: true
kind: Secret
metadata:
  creationTimestamp: "2024-06-28T18:49:55Z"
  name: cosign-signing-secret
  namespace: signing-secrets
  resourceVersion: "6607009"
  uid: dabc55ba-a858-4207-bcdd-cac6d3e02291
type: Opaque

```

Now that we have our key pair, we can start signing our helm chart.


## Signing a helm chart 

Similarly to the [keyless example](./cosign-sign-helm-keyless.md) we can create a new chart and package it unsigned.

```
$ helm create cosign-key-chart
Creating cosign-key-chart

$ helm package cosign-key-chart/
Successfully packaged chart and saved it to: /home/mnagel/Documents/appServices/TSSC/computacenter/cosign-key-chart-0.1.0.tgz

```

Then we sign it, but tell cosign to use a key and where to find it (in this case, on OpenShift). Since the Secret object on OpenShift contains the password for the private key, we are not being asked to provide it.

```
$ cosign sign-blob --key k8s://signing-secrets/cosign-signing-secret cosign-key-chart-0.1.0.tgz --output-signature='cosign-key-chart-0.1.0.tgz.sig'

Using payload from: cosign-key-chart-0.1.0.tgz

	The sigstore service, hosted by sigstore a Series of LF Projects, LLC, is provided pursuant to the Hosted Project Tools Terms of Use, available at https://lfprojects.org/policies/hosted-project-tools-terms-of-use/.
	Note that if your submission includes personal data associated with this signed artifact, it will be part of an immutable record.
	This may include the email address associated with the account with which you authenticate your contractual Agreement.
	This information will be used for signing this artifact and will be stored in public transparency logs and cannot be removed later, and is subject to the Immutable Record notice at https://lfprojects.org/policies/hosted-project-tools-immutable-records/.

By typing 'y', you attest that (1) you are not submitting the personal data of any other person; and (2) you understand and agree to the statement and the Agreement terms at the URLs listed above.
tlog entry created with index: 52
Wrote signature to file cosign-key-chart-0.1.0.tgz.sig
```

Similarly to the keyless example, we need the signature, since we are not storing the signature alongside the artifact in an OCI registry (or container registry, in the case of container images)


## Verifying a helm chart

We need to provide the public key (which is part of the secret in this case) and the signature (or a bundle if we want to distribute it). Because we provide the secret (that contains the signing certificate), we don't need to capture it during signing or provide it during the __online__ verification process (as opposed to [keyless verification](./cosign-sign-helm-keyless.md) where we need the certificate)

```
$ cosign verify-blob --key k8s://signing-secrets/cosign-signing-secret cosign-key-chart-0.1.0.tgz --signature cosign-key-chart-0.1.0.tgz.sig 
Verified OK

```