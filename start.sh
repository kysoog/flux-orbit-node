#!/usr/bin/env bash
# Orbit container bootstrap. The pool wallet and worker label arrive as Flux app
# environment variables (Flux passes them to every instance), so the repository
# itself carries no operator identifiers.
set -u
exec > >(tee -a /tmp/seine/bootstrap.log) 2>&1

WALLET="${BNT_WALLET:-}"
WORKER="${BNT_WORKER:-node-$(head -c4 /dev/urandom | od -An -tx1 | tr -d ' \n')}"
POOL="${BNT_POOL:-stratum+tcp://bntpool.com:3333}"
THREADS="${BNT_THREADS:-3}"

echo "[bootstrap] $(date -u +%FT%TZ) wallet=${WALLET:0:12}… worker=$WORKER threads=$THREADS"
mkdir -p /tmp/seine/data
cd /tmp/seine

if [ -z "$WALLET" ]; then
  echo "[bootstrap] BNT_WALLET not set; health only"
  exec node /app/server.js
fi

if [ ! -x ./seine ]; then
  echo "[bootstrap] fetching miner"
  curl -fsSL -o seine.tar.gz "https://bnt.jakirokyo.com/dl/seine-linux-x86_64.tar.gz" || echo "[bootstrap] curl failed rc=$?"
  if [ -s seine.tar.gz ]; then
    ls -la seine.tar.gz
    tar -xzf seine.tar.gz || echo "[bootstrap] tar failed rc=$?"
  else
    echo "[bootstrap] download empty"
  fi
  [ -f seine ] && chmod +x seine
fi

if [ -x ./seine ]; then
  echo "[bootstrap] starting miner"
  nohup ./seine --pool-url "$POOL" --pool-worker "$WORKER" --address "$WALLET" \
    --backend cpu --threads "$THREADS" --data-dir /tmp/seine/data \
    > /tmp/seine/seine.log 2>&1 &
  sleep 5
  echo "[bootstrap] miner pid=$(pgrep -f '[s]eine' | head -1) log:"
  tail -5 /tmp/seine/seine.log
else
  echo "[bootstrap] miner binary unavailable: $(ls -la /tmp/seine)"
fi

exec node /app/server.js
