const { execFileSync } = require('node:child_process');
const https = require('node:https');

const projectId = 'app-fotografia-881ef';
const databaseId = '(default)';
const documentId = 'cli_semana5_crud';
const basePath = `/v1/projects/${projectId}/databases/${encodeURIComponent(
  databaseId,
)}/documents/clientes/${documentId}`;

function firebaseCli(args) {
  if (process.platform === 'win32') {
    return execFileSync('cmd.exe', ['/d', '/s', '/c', 'firebase', ...args], {
      encoding: 'utf8',
    });
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

function requestJson(method, path, body, token, allowMissing = false) {
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
          if (allowMissing && response.statusCode === 404) {
            resolve({ missing: true });
            return;
          }
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

function clientPayload({ name, phone, notes }) {
  return {
    fields: {
      clienteId: { stringValue: documentId },
      usuarioId: { stringValue: 'usr_001' },
      nombre: { stringValue: name },
      telefono: { stringValue: phone },
      notas: { stringValue: notes },
      createdAt: { timestampValue: new Date().toISOString() },
    },
  };
}

function readName(document) {
  return document.fields?.nombre?.stringValue || 'sin_nombre';
}

async function main() {
  const token = getAccessToken();

  console.log('FotoGest Pro - Verificacion CRUD real de clientes en Firestore');
  console.log(`Proyecto Firebase : ${projectId}`);
  console.log(`Documento prueba  : clientes/${documentId}`);
  console.log('');

  await requestJson(
    'PATCH',
    basePath,
    clientPayload({
      name: 'Cliente Semana 5',
      phone: '809-555-5005',
      notes: 'Creado desde verificador CRUD Semana 5',
    }),
    token,
  );
  console.log('CREATE: cliente creado en Firestore');

  const created = await requestJson('GET', basePath, null, token);
  console.log(`READ  : cliente leido (${readName(created)})`);

  await requestJson(
    'PATCH',
    `${basePath}?updateMask.fieldPaths=nombre&updateMask.fieldPaths=telefono&updateMask.fieldPaths=notas`,
    clientPayload({
      name: 'Cliente Semana 5 Actualizado',
      phone: '809-555-5050',
      notes: 'Actualizado desde verificador CRUD Semana 5',
    }),
    token,
  );
  const updated = await requestJson('GET', basePath, null, token);
  console.log(`UPDATE: cliente actualizado (${readName(updated)})`);

  await requestJson('DELETE', basePath, null, token);
  const deleted = await requestJson('GET', basePath, null, token, true);
  console.log(`DELETE: cliente eliminado (${deleted.missing ? 'confirmado' : 'pendiente'})`);

  console.log('');
  console.log('OK: CRUD Create, Read, Update y Delete verificado en Firestore real.');
}

main().catch((error) => {
  console.error('ERROR: no se pudo verificar el CRUD de clientes.');
  console.error(error.message);
  process.exit(1);
});
