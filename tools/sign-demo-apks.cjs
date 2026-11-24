// Trusted default-branch publication step only. Never execute PR scripts here.
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const {versions}=require('./demo-android-version.cjs');
function tool(name){
  const root=path.join(process.env.ANDROID_HOME,'build-tools');
  const dirs=fs.readdirSync(root).sort((a,b)=>a.localeCompare(b,undefined,{numeric:true})).reverse();
  const found=dirs.map(d=>path.join(root,d,name)).find(p=>fs.existsSync(p));if(!found)throw Error('Android tool unavailable: '+name);return found;
}
function run(cmd,args,env=process.env){
  const r=cp.spawnSync(cmd,args,{encoding:'utf8',timeout:60000,env,stdio:['ignore','pipe','pipe']});
  if(r.error||r.status!==0)throw Error('Android signing/verification failed; sensitive subprocess output suppressed');
  return r.stdout;
}
const expected=versions(Number(process.env.SOURCE_NUMBER),Number(process.env.SOURCE_ATTEMPT));
let bundle;
try{bundle=JSON.parse(process.env.ADVENT_DEMO_SIGNING??'');}catch{throw Error('Protected repository secret ADVENT_DEMO_SIGNING is missing/invalid; no fallback signing permitted');}
if(bundle.schema!==1||bundle.keyAlias!=='advent-demo'||!/^[a-f0-9]{64}$/.test(bundle.certificateSha256??'')||typeof bundle.storePassword!=='string'||bundle.storePassword.length<32||typeof bundle.keyPassword!=='string'||typeof bundle.keystoreBase64!=='string')throw Error('Invalid demo signing secret; refusing signing');
const root=fs.realpathSync(process.env.RUNNER_TEMP),dir=fs.mkdtempSync(path.join(root,'advent-sign-'));fs.chmodSync(dir,0o700);
const key=path.join(dir,'key.p12');
const child={...process.env,ADVENT_STORE_PASSWORD:bundle.storePassword,ADVENT_KEY_PASSWORD:bundle.keyPassword};delete child.ADVENT_DEMO_SIGNING;
const signer=tool('apksigner'),aapt=tool('aapt');
const inputs=[
 ['release','android-release/advent-calendar-test-release-arm64.apk',expected.candidate],
 ['debug','android-apk/app-debug.apk',expected.candidate],
 ['profile','android-profile/advent-calendar-profile-arm64.apk',expected.candidate],
 ['debug-arm64','android-debug-arm64/advent-calendar-debug-arm64.apk',expected.candidate],
 ['baseline','android-upgrade/advent-calendar-upgrade-baseline.apk',expected.baseline],
 ['candidate','android-upgrade/advent-calendar-upgrade-candidate.apk',expected.candidate],
];
const result={applicationId:expected.applicationId,versionCode:expected.candidate,baselineVersionCode:expected.baseline,versionName:expected.versionName,certificateSha256:bundle.certificateSha256,scheme:'persistent-demo-v1',apks:{}};
try{
  fs.writeFileSync(key,Buffer.from(bundle.keystoreBase64,'base64'),{mode:0o600});
  for(const [kind,input,code] of inputs){
    const badging=run(aapt,['dump','badging',input]);
    const m=/^package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'/m.exec(badging);
    if(!m||m[1]!==expected.applicationId||Number(m[2])!==code||m[3]!==expected.versionName)throw Error('Unexpected APK identity/version: '+kind);
    const output=input+'.signed';
    run(signer,['sign','--ks',key,'--ks-type','PKCS12','--ks-key-alias',bundle.keyAlias,'--ks-pass','env:ADVENT_STORE_PASSWORD','--key-pass','env:ADVENT_KEY_PASSWORD','--out',output,input],child);
    const verify=run(signer,['verify','--verbose','--print-certs',output]);
    const certs=[...verify.matchAll(/certificate SHA-256 digest:\s*([a-fA-F0-9]+)/g)].map(m=>m[1].toLowerCase());
    if(certs.length!==1||certs[0]!==bundle.certificateSha256)throw Error('Unexpected signing certificate: '+kind);
    if(kind==='release')fs.writeFileSync('android-size/release-signing.txt',verify);
    fs.renameSync(output,input);fs.rmSync(output+'.idsig',{force:true});
    result.apks[kind]={versionCode:code,versionName:m[3],bytes:fs.statSync(input).size,certificateSha256:certs[0]};
  }
  fs.mkdirSync('android-size',{recursive:true});fs.writeFileSync('android-size/demo-signing.json',JSON.stringify(result,null,2)+'\n');
  console.log(`Persistent demo identity verified: ${result.applicationId}; ${result.baselineVersionCode} -> ${result.versionCode}; public SHA-256 ${result.certificateSha256}`);
}finally{
  bundle=null;delete child.ADVENT_STORE_PASSWORD;delete child.ADVENT_KEY_PASSWORD;
  const resolved=path.resolve(dir);if(!resolved.startsWith(root+path.sep))throw Error('Unexpected key cleanup path');fs.rmSync(resolved,{recursive:true,force:true});
}
