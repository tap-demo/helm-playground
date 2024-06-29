# Working with helm and OCI registries (Quay as an example)

With the introduction of the OCI standrdization effort, support for more than just simple docker images has been introduced into almost all registries.

Red Hat Quay not only supports [helm charts as OCI compliant types](https://docs.redhat.com/en/documentation/red_hat_quay/3.8/html/use_red_hat_quay/oci-intro#oci-intro) but also cosign signatures, attestations, SBOM files and many more.

When using OCI compliant artifacts, we can use cosign with these artifacts similarly to using it with container images:

- We don't have to deal with signature files locally
- cosign signs an image/artifact in the registry and automatically uploads the signature and attaches it.
- cosign's other features (uploading the signing event to rekor) also happens automatically.


Let's see how this works in a [keyless](cosign-sign-helm-oci-keyless.md) fashion and with [long-lived keys](./cosign-sign-helm-oci-keys.md).

In both cases, we need to login to our OCI registry with helm and cosign. 

__*Note*__ Both helm and cosign use the docker-config-style configuration, however both in different place by default. Hence, logging in to your regsitry e.g. via docker or podman will satisfy cosign, but not helm.

Podman / Docker / Cosign default location and structure:

```
$ cat /home/mnagel/.docker/config.json
{
	"auths": {
		"quay-v6v8c.apps.cluster-v6v8c.sandbox617.opentlc.com": {
			"auth": "cXVheWFkbWluOk1URXpOVFUz"
		}
	}
}
```

helm default location and structure:

```
$ cat /home/mnagel/.config/helm/registry/config.json
{
	"auths": {
		"https://quay-v6v8c.apps.cluster-v6v8c.sandbox617.opentlc.com": {
			"auth": "cXVheWFkbWluOk1URXpOVFUz"
		}
	}
}
```

So, for helm we could use the `--registry-config` parameter to point to docker config when interacting with registries, or add an alias such as 

```
alias helm='helm --registry-config /path/to/your/config.json'
```
if we wanted to, but this goes beyond this tutorial. For sake of simplicity, we can login twice for now.

In our playground, we have the `quayadmin` user with password `MTEzNTU3` (don't try, both environment and the password are löong gone when you read this ;-) )

1) Login via podman, docker or cosign


```
$ docker login quay-v6v8c.apps.cluster-v6v8c.sandbox617.opentlc.com
Username: quayadmin
Password: 
WARNING! Your password will be stored unencrypted in /home/mnagel/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credential-stores

Login Succeeded

```

2) helm login 

```
$ helm registry login quay-v6v8c.apps.cluster-v6v8c.sandbox617.opentlc.com
Username: quayadmin
Password: 
Login Succeeded
```

Now both helm and cosign have access to the container (OCI) registry and we can proceed [keyless](cosign-sign-helm-oci-keyless.md) or with [long-lived keys](./cosign-sign-helm-oci-keys.md).

