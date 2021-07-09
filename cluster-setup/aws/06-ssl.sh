aws acm request-certificate \
  --domain-name app.$DOMAIN_NAME \
  --validation-method DNS
app_cert_arn="$(aws acm list-certificates | jq -r ".CertificateSummaryList[] | select(.DomainName == \"app.$DOMAIN_NAME\") | .CertificateArn")"

aws acm request-certificate \
  --domain-name upload.$DOMAIN_NAME \
  --validation-method DNS
upload_cert_arn="$(aws acm list-certificates | jq -r ".CertificateSummaryList[] | select(.DomainName == \"upload.$DOMAIN_NAME\") | .CertificateArn")"

echo "1. Go to https://console.aws.amazon.com/acm/home" >&2
echo "2. Generate the Route 53 record for '$app_cert_arn' ('app.$DOMAIN_NAME')" >&2
echo "3. Generate the Route 53 record for '$upload_cert_arn' ('upload.$DOMAIN_NAME')" >&2
echo "4. Wait (up to 30min)..." >&2

aws acm wait certificate-validated \
  --certificate-arn "$app_cert_arn"
echo "app.$DOMAIN_NAME done!" >&2

aws acm wait certificate-validated \
  --certificate-arn "$upload_cert_arn"
echo "upload.$DOMAIN_NAME done!" >&2

kubectl create configmap acm-ssl-certs \
  --from-literal=app="$app_cert_arn" \
  --from-literal=upload="$upload_cert_arn"
