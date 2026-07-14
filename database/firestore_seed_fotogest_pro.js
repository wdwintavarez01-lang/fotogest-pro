/**
 * FotoGest Pro - Seed de Firestore
 *
 * Uso:
 * 1. Crear un proyecto Firebase y habilitar Firestore.
 * 2. Descargar una clave de cuenta de servicio desde Firebase Console.
 * 3. Instalar dependencia: npm install firebase-admin
 * 4. Ejecutar:
 *    GOOGLE_APPLICATION_CREDENTIALS="ruta/a/service-account.json" node database/firestore_seed_fotogest_pro.js
 */

const admin = require('firebase-admin');
const seedData = require('./firestore_seed_data.json');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function seedCollection(collectionName, documents, idField) {
  const batch = db.batch();

  for (const document of documents) {
    const documentId = document[idField];
    const ref = db.collection(collectionName).doc(documentId);
    batch.set(ref, document, { merge: true });
  }

  await batch.commit();
  console.log(`OK ${collectionName}: ${documents.length} documentos insertados`);
}

async function main() {
  await seedCollection('usuarios', seedData.usuarios, 'usuarioId');
  await seedCollection('clientes', seedData.clientes, 'clienteId');
  await seedCollection('paquetes', seedData.paquetes, 'paqueteId');
  await seedCollection('eventos', seedData.eventos, 'eventoId');
  await seedCollection('ventas', seedData.ventas, 'ventaId');
  await seedCollection('pagos', seedData.pagos, 'pagoId');

  console.log('OK seed Firestore completado para FotoGest Pro');
}

main().catch((error) => {
  console.error('ERROR al sembrar Firestore:', error);
  process.exit(1);
});
