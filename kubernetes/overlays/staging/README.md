Relies on these secrets in the default namespace:

* `cjw-smtp-config`: `HOST`, `USER`, `PASSWORD`, `PORT`, `USE_TLS`
* `cjw-secret-key`: `value`
* `frontend-intercom-secret`: `IDENTITY_VERIFICATION_SECRET`
* `cjw-facebook-secret`: `client_id`, `secret`
* `google-oauth-secret`: `json` from Google's `client_secret.json`: `web` sub-object with `{client_id,client_secret}` values
* `intercom-oauth-secret`: `json` with `client_id` and `client_secret`
* `twitter-oauth-secret`: `json` with `key` and `secret`
* `cjw-stripe-secret` with `STRIPE_API_KEY`, `STRIPE_PUBLIC_API_KEY`, `STRIPE_WEBHOOK_SIGNING_SECRET`
* `gcs-s3-cron-sa-credentials`, `gcs-s3-fetcher-sa-credentials`, `gcs-s3-frontend-sa-credentials`, `gcs-s3-migrate-sa-credentials`, `gcs-s3-renderer-sa-credentials`: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`. See https://cloud.google.com/storage/docs/interoperability to get started on the road to "HMAC keys". (We use GCS's S3-compatibility API.)
* `rabbitmq-1-rabbitmq-secret`: `rabbitmq-pass`

Relies on these services in the default namespace:

* `tusd`
* `rabbitmq-1-rabbitmq-svc` with user `rabbit`, non-SSL, default vhost