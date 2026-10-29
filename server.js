// Health endpoint so Flux keeps the container alive; the miner runs alongside.
const http = require('http');
const {execSync} = require('child_process');
const PORT = process.env.PORT || 3000;

http.createServer((req, res) => {
  let miner = '';
  try { miner = execSync('ps aux | grep -c "[s]eine" || true').toString().trim(); } catch (e) {}
  res.writeHead(200, {'Content-Type': 'application/json'});
  res.end(JSON.stringify({ok: true, miner_procs: miner, ts: Date.now()}));
}).listen(PORT, () => console.log('health on ' + PORT));
