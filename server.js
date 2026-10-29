// Health endpoint so Flux keeps the container alive; the miner runs alongside.
// /debug reports what the bootstrap actually saw, which is the only way to
// inspect the container from outside (Orbit exposes no exec API).
const http = require('http');
const fs = require('fs');
const {execSync} = require('child_process');
const PORT = process.env.PORT || 3000;

function sh(cmd) {
  try { return execSync(cmd, {timeout: 10000}).toString().trim(); } catch (e) { return 'ERR: ' + (e.message || '').slice(0, 200); }
}

function tail(file, n) {
  try {
    const b = fs.readFileSync(file, 'utf8').split('\n');
    return b.slice(-n).join('\n').slice(-3000);
  } catch (e) { return 'ERR: ' + e.message; }
}

http.createServer((req, res) => {
  const url = (req.url || '/').split('?')[0];
  res.writeHead(200, {'Content-Type': 'application/json'});

  if (url === '/debug') {
    return res.end(JSON.stringify({
      ok: true,
      env: {
        wallet: (process.env.BNT_WALLET || '').slice(0, 12) + '…',
        worker: process.env.BNT_WORKER || null,
        pool: process.env.BNT_POOL || null,
        threads: process.env.BNT_THREADS || null,
        git_repo: process.env.GIT_REPO_URL || null,
      },
      seine_bin: sh('ls -la /tmp/seine/seine 2>&1 | head -2'),
      seine_size: sh('stat -c %s /tmp/seine/seine 2>/dev/null || echo 0'),
      procs: sh('ps aux | grep "[s]eine" | head -5'),
      proc_count: sh('ps aux | grep -c "[s]eine" || true'),
      seine_log: tail('/tmp/seine/seine.log', 25),
      bootstrap_log: tail('/tmp/seine/bootstrap.log', 25),
      uptime: sh('uptime'),
    }, null, 1));
  }

  if (url === '/restart-miner') {
    sh('bash /app/start.sh > /tmp/seine/bootstrap.log 2>&1 &');
    return res.end(JSON.stringify({ok: true, restarted: true}));
  }

  let miner = '';
  try { miner = execSync('ps aux | grep -c "[s]eine" || true').toString().trim(); } catch (e) {}
  res.end(JSON.stringify({ok: true, miner_procs: miner, ts: Date.now()}));
}).listen(PORT, () => console.log('health on ' + PORT));
