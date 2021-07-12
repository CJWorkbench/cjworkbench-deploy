echo "Waiting for cjw-smtp-config, with HOST, USER, PASSWORD, PORT, USE_TLS, FROM..." >&2
while ! kubectl get secret cjw-smtp-config 2>/dev/null; do
  sleep 2
done
