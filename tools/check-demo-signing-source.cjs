const fs=require('node:fs'),cp=require('node:child_process');
const files=cp.execFileSync('git',['ls-files','-z'],{encoding:'utf8'}).split('\0').filter(Boolean);
for(const p of files){
 if(/\.(?:jks|keystore|p12|pfx|key)$/i.test(p)||/(?:^|\/)key\.properties$/i.test(p)||p.endsWith('demo-signing-secret.json'))throw Error('Private signing material must not be tracked: '+p);
 if(/\.(?:pem|json|yml|yaml|md|cjs|py|dart|properties)$/i.test(p)){
  const s=fs.readFileSync(p,'utf8');
  if(/-----BEGIN (?:RSA |EC |ENCRYPTED )?PRIVATE KEY-----/.test(s))throw Error('Private key text is tracked: '+p);
 }
}
console.log('No tracked private signing-key files or PEM material.');
