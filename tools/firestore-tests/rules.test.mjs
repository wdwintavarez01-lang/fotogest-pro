import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, getDoc, getDocs, collection, query, where, setDoc, updateDoc,
  deleteDoc, runTransaction, Timestamp, setLogLevel} from 'firebase/firestore';
setLogLevel('silent');
const env = await initializeTestEnvironment({projectId:'demo-fotogest',
  firestore:{host:'127.0.0.1', port:8085, rules:readFileSync(new URL('../../database/firestore.rules',import.meta.url),'utf8')}});
const now = Timestamp.now();
const meta = (uid='alice') => ({usuarioId:uid, revision:1, eliminado:false,
  createdAt:now, updatedAt:now, operacionId:'op_fixture_123456'});
const client = (id='c1',uid='alice') => ({...meta(uid),clienteId:id,nombre:'Cliente de prueba',telefono:'8095550000',notas:''});
const service = () => ({...meta(),paqueteId:'s1',nombre:'Retrato',descripcion:'',precio:100,activo:true});
const event = (id='e1') => ({...meta(),eventoId:id,clienteId:'c1',paqueteId:'s1',tipo:'Retrato',fechaHora:now,
  ubicacion:'Estudio',estado:'programado',montoAcordado:100,totalCentavos:10000,abonadoCentavos:0,totalAbonado:0});
const sale = () => ({...meta(),ventaId:'v1',clienteId:'c1',tipo:'impresion',descripcion:'Foto',cantidad:2,
  precioUnitario:50,precioUnitarioCentavos:5000,total:100,totalCentavos:10000,abonadoCentavos:0,totalAbonado:0,
  fechaVenta:now,estado:'pendiente',notas:''});
const payment = (id,amount=30,target='eventos/e1') => ({...meta(),pagoId:id,
  eventoId:target.startsWith('eventos/') ? target.split('/')[1] : '',
  ventaId:target.startsWith('ventas/') ? target.split('/')[1] : '',
  monto:amount,montoCentavos:Math.round(amount*100),metodo:'efectivo',fechaPago:now,nota:''});
const alice = env.authenticatedContext('alice').firestore();
const bob = env.authenticatedContext('bob').firestore();
const guest = env.unauthenticatedContext().firestore();
async function reset() {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    const db=ctx.firestore();
    for(const [path,data] of [['clientes/c1',client()],['clientes/c2',client('c2','bob')],
      ['paquetes/s1',service()],['eventos/e1',event()],['ventas/v1',sale()]]) await setDoc(doc(db,path),data);
  });
}
async function pay(db,id,amount=30,target='eventos/e1') {
  const p=payment(id,amount,target);
  return runTransaction(db,async tx=>{
    // Mismo protocolo de lectura que el repositorio Flutter.
    await tx.get(doc(db,'pagos',id));
    const ref=doc(db,target); const account=(await tx.get(ref)).data();
    const cents=account.abonadoCentavos+p.montoCentavos;
    tx.update(ref,{abonadoCentavos:cents,totalAbonado:cents/100,ultimoPagoId:id,revision:account.revision+1});
    tx.set(doc(db,'pagos',id),p);
  });
}
const cases = [
 ['R01 acceso anonimo bloqueado',()=>assertFails(getDoc(doc(guest,'clientes/c1')))],
 ['R02 otro propietario no puede leer',()=>assertFails(getDoc(doc(bob,'clientes/c1')))],
 ['R03 consulta filtrada permitida',()=>assertSucceeds(getDocs(query(collection(alice,'clientes'),where('usuarioId','==','alice'))))],
 ['R04 consulta sin filtro bloqueada',()=>assertFails(getDocs(collection(alice,'clientes')))],
 ['R05 cliente propio valido',()=>assertSucceeds(setDoc(doc(alice,'clientes/nuevo'),client('nuevo')))],
 ['R06 propietario ajeno al crear',()=>assertFails(setDoc(doc(alice,'clientes/nuevo'),client('nuevo','bob')))],
 ['R07 nombre corto rechazado',()=>assertFails(setDoc(doc(alice,'clientes/nuevo'),{...client('nuevo'),nombre:'ab'}))],
 ['R08 cambio de propietario rechazado',()=>assertFails(updateDoc(doc(alice,'clientes/c1'),{usuarioId:'bob',revision:2}))],
 ['R09 revision antigua rechazada',()=>assertFails(updateDoc(doc(alice,'clientes/c1'),{nombre:'Cambio',revision:1}))],
 ['R10 borrado fisico rechazado',()=>assertFails(deleteDoc(doc(alice,'clientes/c1')))],
 ['R11 borrado logico permitido',()=>assertSucceeds(updateDoc(doc(alice,'clientes/c1'),{eliminado:true,revision:2}))],
 ['R12 evento con referencia inexistente',()=>assertFails(setDoc(doc(alice,'eventos/e2'),{...event('e2'),clienteId:'ausente'}))],
 ['R13 evento con cliente ajeno',()=>assertFails(setDoc(doc(alice,'eventos/e2'),{...event('e2'),clienteId:'c2'}))],
 ['R14 evento valido',()=>assertSucceeds(setDoc(doc(alice,'eventos/e2'),event('e2')))],
 ['R15 venta con total adulterado',()=>assertFails(updateDoc(doc(alice,'ventas/v1'),{total:99,totalCentavos:9900,revision:2}))],
 ['R16 abono sin incrementar cuenta',()=>assertFails(setDoc(doc(alice,'pagos/p1'),payment('p1')))],
 ['R17 abono e incremento atomicos',()=>assertSucceeds(pay(alice,'p1'))],
 ['R18 sobrepago rechazado',()=>assertFails(pay(alice,'p1',101))],
 ['R19 importe negativo rechazado',()=>assertFails(pay(alice,'p1',-1))],
 ['R20 pago con dos destinos rechazado',async()=>assertFails(setDoc(doc(alice,'pagos/p1'),{...payment('p1'),ventaId:'v1'}))],
 ['R21 cobros simultaneos respetan saldo',async()=>{
    const result=await Promise.allSettled([pay(alice,'p1',70),pay(alice,'p2',70)]);
    assert.equal(result.filter(x=>x.status==='fulfilled').length,1);
    const account=(await getDoc(doc(alice,'eventos/e1'))).data();
    assert.equal(account.abonadoCentavos,7000);
    assert.equal((await getDocs(query(collection(alice,'pagos'),where('usuarioId','==','alice')))).size,1);
 }],
 ['R22 pago confirmado inmutable',async()=>{await pay(alice,'p1');await assertFails(updateDoc(doc(alice,'pagos/p1'),{monto:1}));}],
 ['R23 pago confirmado no se elimina',async()=>{await pay(alice,'p1');await assertFails(deleteDoc(doc(alice,'pagos/p1')));}],
 ['R24 cuenta con abonos no se elimina',async()=>{await pay(alice,'p1');await assertFails(updateDoc(doc(alice,'eventos/e1'),{eliminado:true,revision:3}));}],
 ['R25 total menor que abonado rechazado',async()=>{await pay(alice,'p1');await assertFails(updateDoc(doc(alice,'eventos/e1'),{montoAcordado:20,totalCentavos:2000,revision:3}));}],
 ['R26 cuenta cancelada no recibe abonos',async()=>{await updateDoc(doc(alice,'eventos/e1'),{estado:'cancelado',revision:2});await assertFails(pay(alice,'p1'));}],
 ['R27 abono de venta independiente',()=>assertSucceeds(pay(alice,'p1',50,'ventas/v1'))],
 ['R28 doble incremento sin pago nuevo rechazado',async()=>{await pay(alice,'p1');await assertFails(updateDoc(doc(alice,'eventos/e1'),{abonadoCentavos:6000,totalAbonado:60,revision:3}));}],
 ['R29 un servicio eliminado no admite eventos nuevos',async()=>{await updateDoc(doc(alice,'paquetes/s1'),{eliminado:true,revision:2});await assertFails(setDoc(doc(alice,'eventos/e2'),event('e2')));}],
 ['R30 referencias historicas conservadas',async()=>{await updateDoc(doc(alice,'clientes/c1'),{eliminado:true,revision:2});await assertSucceeds(updateDoc(doc(alice,'eventos/e1'),{estado:'completado',revision:2}));}],
];
let failed=0;
try {
 for(const [name,run] of cases){
  await reset();
  try{await run();console.log('APROBADA '+name);}catch(error){failed++;console.error('FALLO '+name+' '+error.message);}
 }
} finally {await env.cleanup();}
console.log(JSON.stringify({total:cases.length,aprobadas:cases.length-failed,fallidas:failed,entorno:'demo-fotogest/Firestore Emulator; sin escrituras de prueba en produccion'}));
process.exitCode=failed?1:0;
