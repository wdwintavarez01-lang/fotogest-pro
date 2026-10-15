"""Exporta las seis colecciones usando la sesion existente de Firebase CLI.
No modifica datos ni imprime credenciales. El destino debe ser privado.
"""
import argparse,datetime,hashlib,json,pathlib,re,shutil,subprocess,urllib.request
parser=argparse.ArgumentParser()
parser.add_argument('--project',required=True)
parser.add_argument('--output',required=True)
args=parser.parse_args()
if not re.fullmatch(r'[a-z][a-z0-9-]+',args.project):raise SystemExit('Proyecto invalido.')
target=pathlib.Path(args.output).resolve()
if target.exists():raise SystemExit('El archivo ya existe; no se sobrescribe.')
cli=shutil.which('firebase')
if not cli:raise SystemExit('Instala Firebase CLI e inicia sesion antes de exportar.')
subprocess.run([cli,'projects:list','--json'],capture_output=True,timeout=90,check=True)
account=subprocess.run([cli,'login:list','--json'],capture_output=True,text=True,encoding='utf-8',timeout=30,check=True)
accounts=json.loads(account.stdout[account.stdout.find('{'):])['result']
if not accounts:raise SystemExit('No hay una sesion Firebase CLI disponible.')
token=accounts[0]['tokens']['access_token']
root=f'https://firestore.googleapis.com/v1/projects/{args.project}/databases/(default)/documents'
rows=[];counts={}
for collection in ['usuarios','clientes','paquetes','eventos','ventas','pagos']:
 page='';count=0
 while True:
  request=urllib.request.Request(root+'/'+collection+'?pageSize=1000'+('&pageToken='+page if page else ''),headers={'Authorization':'Bearer '+token})
  with urllib.request.urlopen(request,timeout=40) as response:data=json.load(response)
  docs=data.get('documents',[]);rows.extend(docs);count+=len(docs)
  page=data.get('nextPageToken','')
  if not page:break
 counts[collection]=count
target.parent.mkdir(parents=True,exist_ok=True)
target.write_text(json.dumps({'project':args.project,'fecha':datetime.datetime.now(datetime.timezone.utc).isoformat(),'documents':rows},ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'documentos':len(rows),'conteos':counts,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'incluye_authentication':False},ensure_ascii=False))
