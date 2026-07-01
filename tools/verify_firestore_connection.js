const { execFileSync } = require('node:child_process');
const https = require('node:https');

const projectId = 'app-fotografia-881ef';
const databaseId = '(default)';
const expectedCollections = ['usuarios', 'clientes', 'paquetes', 'eventos', 'pagos'];

function firebaseCli(args) {
  if (process.platform === 'win32') {
    return execFileSync('cmd.exe', ['/d', '/s', '/c', 'firebase', ...args], { encoding: 'utf8' });
  }

  return execFileSync('firebase', args, { encoding: 'utf8' });
}

function getAccessToken() {
  const auth = JSON.parse(firebaseCli(['login:list', '--json']));
  const account = auth.result?.[0];
  if (!account?.tokens?.access_token) {
    throw new Error('No hay sesion activa en Firebase CLI. Ejecuta: firebase login');
  }
  return account.tokens.access_token;
}

function requestJson(method, path, body, token) {
  const payload = body ? JSON.stringify(body) : undefined;

  return new Promise((resolve, reject) => {
    const request = https.request(
      {
        hostname: 'firestore.googleapis.com',
        path,
        method,
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
          ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
        },
      },
      (response) => {
        let data = '';
        response.on('data', (chunk) => {
          data += chunk;
        });
        response.on('end', () => {
          if (response.statusCode < 200 || response.statusCode >= 300) {
            reject(new Error(`${response.statusCode}: ${data}`));
            return;
          }
          resolve(data ? JSON.parse(data) : {});
        });
      },
    );

    request.on('error', reject);
    if (payload) request.write(payload);
    request.end();
  });
}

function fieldToText(value) {
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return value.integerValue;
  if ('doubleValue' in value) return String(value.doubleValue);
  if ('booleanValue' in value) return String(value.booleanValue);
  if ('timestampValue' in value) return value.timestampValue;
  return JSON.stringify(value);
}

async function main() {
  const token = getAccessToken();
  const basePath = `/v1/projects/${projectId}/databases/${encodeURIComponent(databaseId)}/documents`;

  const collectionResponse = await requestJson(
    'POST',
    `${basePath}:listCollectionIds`,
    {},
    token,
  );

  const visibleCollections = (collectionResponse.collectionIds || []).sort();

  console.log('FotoGest Pro - Conexion real a Firebase Cloud Firestore');
  console.log(`Proyecto Firebase : ${projectId}`);
  console.log(`Base de datos     : ${databaseId}`);
  console.log(`Console URL       : https://console.firebase.google.com/project/${projectId}/firestore/databases/-default-/data`);
  console.log('');
  console.log('Colecciones visibles:');
  console.log(visibleCollections.map((name) => `- ${name}`).join('\n'));
  console.log('');

  for (const collection of expectedCollections) {
    const response = await requestJson(
      'GET',
      `${basePath}/${collection}?pageSize=100`,
      null,
      token,
    );
    const documents = response.documents || [];
    const first = documents[0];
    const firstId = first?.name?.split('/').pop() || 'sin_documentos';
    const fields = first?.fields || {};
    const preview = Object.entries(fields)
      .slice(0, 4)
      .map(([key, value]) => `${key}=${fieldToText(value)}`)
      .join(' | ');

    console.log(`${collection.padEnd(10)} documentos=${String(documents.length).padEnd(2)} muestra=${firstId}`);
    if (preview) console.log(`  ${preview}`);
  }

  console.log('');
  console.log('OK: conexion real a Firestore verificada desde el entorno de desarrollo.');
}

main().catch((error) => {
  console.error('ERROR: no se pudo verificar Firestore.');
  console.error(error.message);
  process.exit(1);
});
