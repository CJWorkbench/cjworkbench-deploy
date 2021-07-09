kubectl create secret generic cjw-secret-key \
  --from-literal=key="$DJANGO_SECRET_KEY"

kubectl create secret generic cjw-intercom \
  --from-literal=app_id="$INTERCOM_APP_ID" \
  --from-literal=identity_verification_secret="$INTERCOM_IDENTITY_VERIFICATION_SECRET"
