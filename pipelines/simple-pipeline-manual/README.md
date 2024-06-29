# Simple Pipeline

This is a simple pipeline that needs to be manually created (see below, deploy the *.yaml files to your namespace, configure a webhook in gitlab).

While this could be automated with the help of RHDH/Backstage template, this is an example to play with and understand the basic concepts.


## Deploy

1) Clone this repository to your desktop and go to this directory (that contains the pipeline definition)

2) Log in to your OpenShift Cluster and create a namespace that you want to deploy the pipeline to.

3) check if the ./deploy.sh is executable and run it 

4) Check the EventListener route endpoint (you need that for the gitlab webhook)

```
$ oc get route gitlab-webhook -o jsonpath='https://{.spec.host}'

https://gitlab-webhook-test-pipeline.apps.cluster-v6v8c.sandbox617.opentlc.com
```

5) Add this to your repo's webhook configuration - the simple pipeline doesn't check for the secret. If you'd like to add that, you need to add an entry to the EventListener's Interceptor

```
      interceptors:
        - ref:
            name: cel
          params:
            - name: filter
              value: "header.match('X-Gitlab-Token', '$(secretRef.gitlab-webhook-secret.secretToken)')"
``` 

and create a matching secret that contains the token

```
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-webhook-secret
type: Opaque
stringData:
  secretToken: your-secret-token

```
