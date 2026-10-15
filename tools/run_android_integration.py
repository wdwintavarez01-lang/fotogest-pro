"""Ejecuta la prueba en el AVD y corta su red real al recibir marcadores."""
import os,pathlib,subprocess,sys
sys.stdout.reconfigure(encoding='utf-8')
adb=r'C:\Android\sdk\platform-tools\adb.exe'
flutter=r'C:\src\flutter\bin\flutter.bat'
device='emulator-5554'
def network(online):
 for args in [['shell','cmd','connectivity','airplane-mode','disable' if online else 'enable'],
              ['shell','svc','wifi','enable' if online else 'disable'],
              ['shell','svc','data','enable' if online else 'disable']]:
  subprocess.run([adb,'-s',device,*args],capture_output=True,check=True,timeout=20)
 print('RED_AVD '+('ACTIVA' if online else 'MODO_AVION'),flush=True)
env=dict(os.environ)
env['JAVA_TOOL_OPTIONS']=r'-Djdk.net.unixdomain.tmpdir=C:\FotoGest_NIO_AF_UNIX_NoDisponible'
target=sys.argv[1] if len(sys.argv)>1 else 'integration_test/app_flow_test.dart'
stage=sys.argv[2] if len(sys.argv)>2 else ''
name='integracion_android' if not stage else 'integracion_reinicio_'+stage.lower()
log=pathlib.Path(r'C:\Users\Soporte TI\Downloads\Seminario\Entrega_FotoGest_Pro\Evidencias')/(name+'_1_1_0.txt')
try:
 network(True)
 with log.open('w',encoding='utf-8') as out:
  args=['cmd.exe','/d','/c',flutter,'test',target,'-d',device,'--no-pub','--no-uninstall','--reporter','expanded']
  if stage:args.append('--dart-define=STAGE='+stage)
  proc=subprocess.Popen(args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace',env=env)
  for line in proc.stdout:
   out.write(line);out.flush();print(line,end='',flush=True)
   if 'FOTOGEST_OFFLINE_START' in line:network(False)
   if 'FOTOGEST_ONLINE_START' in line:network(True)
   if 'FOTOGEST_CAPTURE_' in line:
    label=line.split('FOTOGEST_CAPTURE_')[1].strip().lower()
    image=subprocess.run([adb,'-s',device,'exec-out','screencap','-p'],capture_output=True,check=True,timeout=20).stdout
    (log.parent/f'android_1_1_0_{label}.png').write_bytes(image)
  code=proc.wait()
finally:network(True)
sys.exit(code)
