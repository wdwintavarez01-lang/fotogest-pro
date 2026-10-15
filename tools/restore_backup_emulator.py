"""Comprueba un respaldo REST en un proyecto local aislado. Nunca restaura en produccion."""
import argparse,json,pathlib,urllib.request,hashlib
parser=argparse.ArgumentParser()
parser.add_argument('backup')
parser.add_argument('--port',type=int,default=8085)
args=parser.parse_args()
source=pathlib.Path(args.backup)
data=json.loads(source.read_text(encoding='utf-8'))
project='demo-fotogest-restore'
root=f'http://127.0.0.1:{args.port}/v1/projects/{project}/databases/(default)/documents'
def request(url,body=None):
 req=urllib.request.Request(url,data=json.dumps(body).encode() if body is not None else None,
  headers={'Authorization':'Bearer owner','Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=45) as response:return json.load(response)
writes=[]
for document in data['documents']:
 path=document['name'].split('/documents/')[1]
 name=f'projects/{project}/databases/(default)/documents/{path}'
 writes.append({'update':{'name':name,'fields':document['fields']}})
request(root+':commit',{'writes':writes})
verified=0
for document in data['documents']:
 path=document['name'].split('/documents/')[1]
 restored=request(root+'/'+path)
 if restored['fields']!=document['fields']:raise RuntimeError('Los campos no coinciden: '+path)
 verified+=1
print(json.dumps({'respaldo_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
 'documentos_restaurados_y_comparados':verified,'campos_coinciden':True,
 'destino':'127.0.0.1 / demo-fotogest-restore','produccion_modificada':False},ensure_ascii=False))
