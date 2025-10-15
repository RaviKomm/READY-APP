#!/usr/bin/env bash
START=$(date +%s.%N)
docker compose --profile dev up --build -d
URL="http://localhost:8000/health"
while true; do
  if curl -sS --fail $URL >/dev/null 2>&1; then
    END=$(date +%s.%N)
    DIFF=$(python - <<PY
print(float("${END}")-float("${START}"))
PY
)
    echo "Time-to-healthy: ${DIFF} seconds"
    break
  fi
  sleep 0.2
done
