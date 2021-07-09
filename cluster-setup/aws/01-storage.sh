aws s3 mb s3://user-files.$DOMAIN_NAME
aws s3 mb s3://static.$DOMAIN_NAME
aws s3 mb s3://stored-objects.$DOMAIN_NAME
aws s3 mb s3://external-modules.$DOMAIN_NAME
aws s3 mb s3://cached-render-results.$DOMAIN_NAME
aws s3 mb s3://upload.$DOMAIN_NAME

# Uploads expire after 1d
echo '{"Rules":[{"Expiration":{"Days":1},"Prefix":"","Status":"Enabled","AbortIncompleteMultipartUpload":{"DaysAfterInitiation":1}}]}' \
  > 1d-lifecycle.json
aws s3api put-bucket-lifecycle-configuration \
  --bucket upload.$DOMAIN_NAME \
  --lifecycle-configuration file://$DIR/1d-lifecycle.json
rm -f 1d-lifecycle.json

# Static-files server
# Public-access...
aws s3api put-bucket-acl \
  --bucket static.$DOMAIN_NAME \
  --acl public-read
# ... CORS...
aws s3api put-bucket-policy \
  --bucket static.$DOMAIN_NAME \
  --policy file://<(echo '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::static.'$DOMAIN_NAME'/*"}]}')
aws s3api put-bucket-cors \
  --bucket static.$DOMAIN_NAME \
  --cors-configuration '{"CORSRules":[{"AllowedOrigins":["*"],"AllowedMethods":["GET","HEAD"]}]}'
# ... SSL...
aws acm request-certificate \
  --domain-name static.$DOMAIN_NAME \
  --validation-method DNS
static_cert_arn="$(aws acm list-certificates | jq -r ".CertificateSummaryList[] | select(.DomainName == \"static.$DOMAIN_NAME\") | .CertificateArn")"
echo "Go to https://console.aws.amazon.com/acm/home to generate the Route 53 record for '$static_cert_arn' ('static.$DOMAIN_NAME') ... and then wait up to 30min...."
aws acm wait certificate-validated \
  --certificate-arn "$static_cert_arn"
# ... CDN...
read -r -d '' cloudfront_distribution_config <<EOT
  {
    "Comment": "static.$DOMAIN_NAME",
    "Enabled": true,
    "CallerReference": "static.$DOMAIN_NAME",
    "Aliases": {
      "Quantity": 1,
      "Items": ["static.$DOMAIN_NAME"]
    },
    "Origins": {
      "Quantity": 1,
      "Items": [
        {
          "Id": "static.$DOMAIN_NAME.s3.amazonaws.com",
          "DomainName": "static.$DOMAIN_NAME.s3.amazonaws.com",
          "OriginPath": "",
          "S3OriginConfig": { "OriginAccessIdentity": "" }
        }
      ]
    },
    "ViewerCertificate": {
      "ACMCertificateArn": "$static_cert_arn",
      "SSLSupportMethod": "sni-only"
    },
    "DefaultCacheBehavior": {
      "TargetOriginId": "static.$DOMAIN_NAME.s3.amazonaws.com",
      "ForwardedValues": {
        "QueryString": false,
        "Cookies": { "Forward": "none" },
        "Headers": { "Quantity": 0 },
        "QueryStringCacheKeys": { "Quantity": 0 }
      },
      "ViewerProtocolPolicy": "https-only",
      "MinTTL": 0,
      "DefaultTTL": 86400,
      "Compress": true
    }
  }
EOT
aws cloudfront create-distribution \
  --distribution-config "$cloudfront_distribution_config" \
  | jq  # avoid AWS's default pager
