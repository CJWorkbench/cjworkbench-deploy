Relies on these secrets in the default namespace:

* `cjw-smtp-config`: `HOST`, `USER`, `PASSWORD`, `PORT`, `USE_TLS`, `FROM`
* `cjw-secret-key`: `value`
* `postgres-cjworkbench-credentials`: with `database`, `host`, `username` and `password` literals.
* [optional] `frontend-intercom-secret`: `IDENTITY_VERIFICATION_SECRET`
* [optional] `cjw-facebook-secret`: `client_id`, `secret`
* [optional] `google-oauth-secret`: `json` from Google's `client_secret.json`: `web` sub-object with `{client_id,client_secret}` values
* [optional] `intercom-oauth-secret`: `json` with `client_id` and `client_secret`
* [optional] `twitter-oauth-secret`: `json` with `key` and `secret`
* [optional] `cjw-stripe-secret` with `STRIPE_API_KEY`, `STRIPE_PUBLIC_API_KEY`, `STRIPE_WEBHOOK_SIGNING_SECRET`

Deriving kustomizations must add:

* `workbench-config` with a `domainName` literal. (The app is served at `app.domainName`.)
* `acm-ssl-certs` with literlas `app` and `upload`, each an ARN identifying an AWS-managed SSL certificate

Deriving kustomizations must *also* add a big, ugly block, because EKS relies on annotations instead of configmaps:

```yaml
vars:
- name: DOMAIN_NAME
  objref:
    apiVersion: v1
    kind: ConfigMap
    name: workbench-config
  fieldref:
    fieldpath: data.domainName
- name: APP_CERT_ARN
  objref:
    apiVersion: v1
    kind: ConfigMap
    name: acm-ssl-certs
  fieldref:
    fieldpath: data.app
- name: UPLOAD_CERT_ARN
  objref:
    apiVersion: v1
    kind: ConfigMap
    name: acm-ssl-certs
  fieldref:
    fieldpath: data.upload
```
