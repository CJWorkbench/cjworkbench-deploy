Relies on these secrets in the default namespace:

* `cjw-smtp-config`: `HOST`, `USER`, `PASSWORD`, `PORT`, `USE_TLS`, `FROM`
* `cjw-secret-key`: `value`
* `frontend-intercom-secret`: `IDENTITY_VERIFICATION_SECRET`
* `cjw-intercom-sink-intercom-secret`: `ACCESS_TOKEN`

Also, see `kustomize.yaml` for a list of config-map entries needed. (Overlays
set all these.)
