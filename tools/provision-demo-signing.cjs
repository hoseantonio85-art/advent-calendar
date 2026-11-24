// Run manually by an authorized repository administrator. No token extraction.
const fs=require('node:fs'),os=require('node:os'),path=require('node:path'),cp=require('node:child_process'),crypto=require('node:crypto');
const repo='hoseantonio85-art/advent-calendar',secret='ADVENT_DEMO_SIGNING',environment='advent-demo-signing';
function run(cmd,args,opts={}){
  const r=cp.spawnSync(cmd,args,{encoding:'utf8',timeout:30000,stdio:['pipe','pipe','pipe'],...opts});
  if(r.error||r.status!==0)throw Error('Setup command failed; no secret value has been printed. Check normal GitHub CLI authentication and repository secret-write permission.');
  return r.stdout;
}
if(process.env.GITHUB_ACTIONS)throw Error('Provision once from an administrator workstation, not from an untrusted CI job');
if(process.argv.includes('--help')){console.log('After normal gh auth login: node tools/provision-demo-signing.cjs\nCreates ADVENT_DEMO_SIGNING only if absent; refuses key rotation. Prints public fingerprint only.');process.exit(0);}
const endpoint='repos/'+repo+'/environments/'+environment;
const environments=JSON.parse(run('gh',['api','repos/'+repo+'/environments']));
if(!environments.environments.some(e=>e.name===environment)){
  run('gh',['api','--method','PUT',endpoint,'--input','-'],{input:JSON.stringify({deployment_branch_policy:{protected_branches:false,custom_branch_policies:true}})});
  run('gh',['api','--method','POST',endpoint+'/deployment-branch-policies','--input','-'],{input:JSON.stringify({name:'main',type:'branch'})});
}
const configuration=JSON.parse(run('gh',['api',endpoint]));
const policies=JSON.parse(run('gh',['api',endpoint+'/deployment-branch-policies']));
if(configuration.deployment_branch_policy?.protected_branches!==false||configuration.deployment_branch_policy?.custom_branch_policies!==true||policies.branch_policies.length!==1||policies.branch_policies[0].name!=='main'||policies.branch_policies[0].type!=='branch')throw Error('Signing environment must allow only main, not pull requests. Review its branch policy before provisioning.');
const names=JSON.parse(run('gh',['secret','list','--repo',repo,'--env',environment,'--json','name']));
if(names.some(s=>s.name===secret))throw Error('ADVENT_DEMO_SIGNING already exists. Refusing to replace the persistent demo identity.');
const tempRoot=fs.realpathSync(os.tmpdir()),dir=fs.mkdtempSync(path.join(tempRoot,'advent-demo-provision-'));
const file=n=>path.join(dir,n);
let password=crypto.randomBytes(36).toString('base64url');
try{
  if(process.platform==='win32'){
    const account=process.env.USERDOMAIN+'\\'+process.env.USERNAME;
    run('icacls',[dir,'/inheritance:r','/grant:r',account+':(OI)(CI)F']);
  }else fs.chmodSync(dir,0o700);
  const openssl=process.platform==='win32'&&fs.existsSync('C:/Program Files/Git/usr/bin/openssl.exe')?'C:/Program Files/Git/usr/bin/openssl.exe':'openssl';
  run(openssl,['req','-x509','-newkey','rsa:3072','-noenc','-sha256','-days','10950','-subj','/CN=Advent Calendar Demo/O=Advent Calendar Demo','-keyout',file('temporary-private.pem'),'-out',file('certificate.pem')]);
  run(openssl,['pkcs12','-export','-inkey',file('temporary-private.pem'),'-in',file('certificate.pem'),'-name','advent-demo','-out',file('temporary.p12'),'-passout','env:ADVENT_PROVISION_PASSWORD'],{env:{...process.env,ADVENT_PROVISION_PASSWORD:password}});
  const cert=new crypto.X509Certificate(fs.readFileSync(file('certificate.pem'))),fingerprint=cert.fingerprint256.replaceAll(':','').toLowerCase();
  const bundle={schema:1,keystoreBase64:fs.readFileSync(file('temporary.p12')).toString('base64'),storePassword:password,keyAlias:'advent-demo',keyPassword:password,certificateSha256:fingerprint};
  run('gh',['secret','set',secret,'--repo',repo,'--env',environment],{input:JSON.stringify(bundle)});
  console.log('Persistent demo signing secret installed. Public certificate SHA-256: '+fingerprint);
  console.log('No private key/password was printed or retained on disk. Do not regenerate this secret for later builds.');
}finally{
  password='';
  const resolved=path.resolve(dir);
  if(!resolved.startsWith(tempRoot+path.sep)||!path.basename(resolved).startsWith('advent-demo-provision-'))throw Error('Unexpected cleanup target');
  fs.rmSync(resolved,{recursive:true,force:true});
}
