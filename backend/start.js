const { spawn, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ENV_PATH = path.join(__dirname, '.env');
const children = [];

function killAll() {
  children.forEach(c => {
    try { execSync(`taskkill /F /T /PID ${c.pid}`, { stdio: 'ignore' }); } catch {}
  });
  process.exit(0);
}
process.on('SIGINT',  killAll);
process.on('SIGTERM', killAll);

function updateEnv(url) {
  let content = fs.readFileSync(ENV_PATH, 'utf8');
  content = content.replace(/^BACKEND_URL=.*/m, `BACKEND_URL=${url}`);
  fs.writeFileSync(ENV_PATH, content);
  console.log(`✅ BACKEND_URL → ${url}`);
}

async function getNgrokUrl(retries = 20, delay = 1000) {
  for (let i = 0; i < retries; i++) {
    try {
      const res = await fetch('http://localhost:4040/api/tunnels');
      const data = await res.json();
      const tunnel = data.tunnels?.find(t => t.proto === 'https');
      if (tunnel?.public_url) return tunnel.public_url;
    } catch {}
    await new Promise(r => setTimeout(r, delay));
  }
  throw new Error('ngrok did not start within 20s');
}

function startTunnel() {
  return new Promise((resolve, reject) => {
    console.log('🔌 Starting ngrok tunnel...');

    const ng = spawn('ngrok', ['http', '3001'], {
      shell: true,
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    children.push(ng);
    ng.stdout.on('data', d => process.stdout.write(d));
    ng.stderr.on('data', d => process.stderr.write(d));
    ng.on('error', reject);

    setTimeout(async () => {
      try {
        const url = await getNgrokUrl();
        updateEnv(url);
        resolve();
      } catch (err) {
        reject(err);
      }
    }, 2000);
  });
}

function startBackend() {
  console.log('🚀 Starting backend...');
  const server = spawn('node', ['server.js'], {
    shell: true,
    stdio: 'inherit',
  });
  children.push(server);
  server.on('exit', (code) => process.exit(code ?? 0));
}

(async () => {
  try {
    await startTunnel();
    startBackend();
  } catch (err) {
    console.error('❌ Tunnel failed:', err.message);
    console.log('⚠️  Starting backend without tunnel...');
    startBackend();
  }
})();
