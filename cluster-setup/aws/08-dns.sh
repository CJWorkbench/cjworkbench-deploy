echo -n "Waiting for frontend-ingress to get a hostname... " >&2
while ! kubectl get ingress frontend-ingress -ojsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>&1; do
  sleep 1
done
echo  # kubectl prints the name, not a newline

load_balancer_hostname="$(kubectl get ingress frontend-ingress -ojsonpath='{.status.loadBalancer.ingress[0].hostname}')"

hosted_zone_id="$(aws route53 list-hosted-zones --query "HostedZones[?Name=='$DOMAIN_NAME.'].Id" --output text)"
cloudfront_zone_id="Z2FDTNDATAQYW2"  # always, across all AWS
alb_us_east_1_zone_id="Z35SXDOTRQ7X7K"  # https://docs.aws.amazon.com/general/latest/gr/elb.html
cloudfront_dns_name="$(aws cloudfront list-distributions | jq -r ".DistributionList.Items[] | select(.Origins.Items[0].DomainName == \"static.$DOMAIN_NAME.s3.amazonaws.com\") | .DomainName")"
read -r -d '' change_batch <<EOF
  {
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "static.$DOMAIN_NAME.",
          "Type": "A",
          "AliasTarget": {
            "HostedZoneId": "$cloudfront_zone_id",
            "DNSName": "$cloudfront_dns_name",
            "EvaluateTargetHealth": false
          }
        }
      },
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "static.$DOMAIN_NAME.",
          "Type": "AAAA",
          "AliasTarget": {
            "HostedZoneId": "$cloudfront_zone_id",
            "DNSName": "$cloudfront_dns_name",
            "EvaluateTargetHealth": false
          }
        }
      },
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "app.$DOMAIN_NAME.",
          "Type": "A",
          "AliasTarget": {
            "HostedZoneId": "$alb_us_east_1_zone_id",
            "DNSName": "$load_balancer_hostname",
            "EvaluateTargetHealth": false
          }
        }
      },
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "upload.$DOMAIN_NAME.",
          "Type": "A",
          "AliasTarget": {
            "HostedZoneId": "$alb_us_east_1_zone_id",
            "DNSName": "$load_balancer_hostname",
            "EvaluateTargetHealth": false
          }
        }
      }
    ]
  }
EOF
aws route53 change-resource-record-sets \
  --hosted-zone-id "$hosted_zone_id" \
  --change-batch "$change_batch"
