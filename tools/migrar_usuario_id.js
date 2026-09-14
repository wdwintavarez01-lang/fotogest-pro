/**
 * FotoGest Pro - Migracion de propiedad de los datos.
 *
 * Reasigna el campo `usuarioId` de todos los documentos existentes al UID real
 * del usuario de Firebase Authentication, y completa el campo `montoAcordado`
 * de los eventos anteriores usando el precio actual de su servicio.
 *
 * El script inicia sesion con el mismo correo y contrasena que se usan en la
 * aplicacion, por lo que trabaja con los permisos de ese usuario.
 *
 * IMPORTANTE: ejecutar ANTES de publicar las reglas nuevas de Firestore. Las
 * reglas actuales permiten a cualquier usuario autenticado modificar los
 * documentos; las nuevas solo permiten modificar los propios, y los documentos
 * viejos todavia estan a nombre de `usr_001`.
 *
 * Uso:
 *   node tools/migrar_usuario_id.js --simular     (no escribe, solo muestra)
 *   node tools/migrar_usuario_id.js               (aplica los cambios)
 *
 * El correo y la contrasena se piden por pantalla al ejecutarlo.
 */

const https = require('node:https');
const readline = require('node:readline');

const projectId = 'app-fotografia-881ef';
const apiKey = 'AIzaSyBvo7wag40sV5E1NrOxZeif4xY-bErQL8g';
const databaseId = '(default)';
const collections = ['clientes', 'paquetes', 'eventos', 'ventas', 'pagos'];

const simular = process.argv.includes('--simular');

function preguntar(texto) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question(texto, (respuesta) => {
      rl.close();
      resolve(respuesta.trim());
    });
  });
}

function peticion(hostname, method, path, body, token) {
  const payload = body ? JSON.stringify(body) : undefined;

  return new Promise((resolve, reject) => {
    const request = https.request(
      {
        hostname,
        path,
        method,
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
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

async function iniciarSesion(email, password) {
  const respuesta = await peticion(
    'identitytoolkit.googleapis.com',
    'POST',
    `/v1/accounts:signInWithPassword?key=${apiKey}`,
    { email, password, returnSecureToken: true },
    null,
  );
  return { idToken: respuesta.idToken, uid: respuesta.localId };
}

function firestore(method, path, body, token) {
  return peticion('firestore.googleapis.com', method, path, body, token);
}

function numeroDe(campo) {
  if (!campo) return null;
  if ('doubleValue' in campo) return Number(campo.doubleValue);
  if ('integerValue' in campo) return Number(campo.integerValue);
  return null;
}

function textoDe(campo) {
  if (!campo) return '';
  if ('stringValue' in campo) return campo.stringValue;
  return '';
}

async function listarTodo(basePath, collection, token) {
  const documentos = [];
  let pageToken = '';

  do {
    const query = `pageSize=300${pageToken ? `&pageToken=${encodeURIComponent(pageToken)}` : ''}`;
    const respuesta = await firestore(
      'GET',
      `${basePath}/${collection}?${query}`,
      null,
      token,
    );
    documentos.push(...(respuesta.documents || []));
    pageToken = respuesta.nextPageToken || '';
  } while (pageToken);

  return documentos;
}

async function actualizarCampos(documentName, fields, token) {
  const mask = Object.keys(fields)
    .map((name) => `updateMask.fieldPaths=${encodeURIComponent(name)}`)
    .join('&');
  await firestore('PATCH', `/v1/${documentName}?${mask}`, { fields }, token);
}

async function main() {
  console.log('FotoGest Pro - Migracion de usuarioId');
  console.log(`Proyecto Firebase : ${projectId}`);
  console.log(`Modo              : ${simular ? 'SIMULACION (no escribe)' : 'ESCRITURA'}`);
  console.log('');
  console.log('Escribe el correo y la contrasena que usas en la aplicacion.');
  console.log('La contrasena se vera en pantalla mientras la escribes.');
  console.log('');

  const email = await preguntar('Correo      : ');
  const password = await preguntar('Contrasena  : ');
  console.log('');

  const { idToken, uid } = await iniciarSesion(email, password);
  console.log(`Sesion iniciada. UID destino: ${uid}`);
  console.log('');

  const basePath = `/v1/projects/${projectId}/databases/${encodeURIComponent(databaseId)}/documents`;

  // Precios de los servicios, para completar el monto acordado de los eventos.
  const paquetes = await listarTodo(basePath, 'paquetes', idToken);
  const precioPorPaquete = new Map();
  for (const documento of paquetes) {
    const id = documento.name.split('/').pop();
    const precio = numeroDe(documento.fields?.precio) ?? 0;
    precioPorPaquete.set(id, precio);
    const paqueteId = textoDe(documento.fields?.paqueteId);
    if (paqueteId) precioPorPaquete.set(paqueteId, precio);
  }

  let totalActualizados = 0;

  for (const collection of collections) {
    const documentos = await listarTodo(basePath, collection, idToken);
    let actualizados = 0;

    for (const documento of documentos) {
      const fields = {};
      const usuarioActual = textoDe(documento.fields?.usuarioId);

      if (usuarioActual !== uid) {
        fields.usuarioId = { stringValue: uid };
      }

      if (collection === 'eventos') {
        const montoActual = numeroDe(documento.fields?.montoAcordado);
        if (montoActual === null || montoActual <= 0) {
          const paqueteId = textoDe(documento.fields?.paqueteId);
          const precio = precioPorPaquete.get(paqueteId) ?? 0;
          fields.montoAcordado = { doubleValue: precio };
        }
      }

      if (Object.keys(fields).length === 0) continue;

      const id = documento.name.split('/').pop();
      const detalle = Object.keys(fields)
        .map((campo) =>
          campo === 'montoAcordado'
            ? `montoAcordado=${fields.montoAcordado.doubleValue}`
            : 'usuarioId',
        )
        .join(', ');
      console.log(`  ${collection}/${id} -> ${detalle}`);

      if (!simular) {
        await actualizarCampos(documento.name, fields, idToken);
      }
      actualizados += 1;
    }

    console.log(`${collection.padEnd(10)} documentos=${String(documentos.length).padEnd(3)} actualizados=${actualizados}`);
    totalActualizados += actualizados;
  }

  console.log('');
  if (simular) {
    console.log(`SIMULACION: se actualizarian ${totalActualizados} documentos.`);
    console.log('Vuelve a ejecutar sin --simular para aplicar los cambios.');
  } else {
    console.log(`OK: ${totalActualizados} documentos actualizados.`);
    console.log('Siguiente paso: firebase deploy --only firestore:rules');
    console.log('');
    console.log('Los documentos usr_001, usr_002 y usr_003 de la coleccion usuarios');
    console.log('quedan en desuso y pueden eliminarse desde Firebase Console.');
  }
}

main().catch((error) => {
  console.error('');
  console.error('ERROR: no se pudo completar la migracion.');
  console.error(error.message);
  if (error.message.includes('INVALID_LOGIN_CREDENTIALS') || error.message.includes('INVALID_PASSWORD')) {
    console.error('Revisa el correo y la contrasena de la aplicacion.');
  }
  if (error.message.includes('PERMISSION_DENIED')) {
    console.error('Las reglas nuevas ya estan publicadas y bloquean los documentos viejos.');
    console.error('Publica temporalmente las reglas anteriores, ejecuta la migracion');
    console.error('y vuelve a publicar las reglas nuevas.');
  }
  process.exit(1);
});
