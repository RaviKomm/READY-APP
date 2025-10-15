#!/usr/bin/env bash
CONTAINER=$(docker ps --filter "name=api" --format "{{.Names}}" | head -n1)
if [ -z "$CONTAINER" ]; then
  echo "No running API container found."
  exit 1
fi
URL="http://localhost:8000/ready"
docker restart $CONTAINER >/dev/null
START=$(date +%s.%N)
while true; do
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" $URL || echo 000)
  if [ "$HTTP" = "200" ]; then
    END=$(date +%s.%N)
    DIFF=$(python - <<PY
print(float("${END}")-float("${START}"))
PY
)
    echo "RTO (restart -> ready): ${DIFF} seconds"
    break
  fi
  sleep 0.2
done
