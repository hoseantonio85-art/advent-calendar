const fs=require('node:fs');
const f='android/app/build.gradle.kts';let s=fs.readFileSync(f,'utf8');
if(!s.includes('applicationId = "com.example.advent_demo"'))throw Error('Demo applicationId changed; refusing an incompatible build');
const abis=process.argv[2];
if(abis){
 const values=abis.split(',');if(values.some(x=>!['arm64-v8a','x86_64'].includes(x)))throw Error('Unexpected demo ABI');
 s=s.replace(/\n\/\/ ADVENT DEMO ABI START[\s\S]*?\/\/ ADVENT DEMO ABI END\n?/g,'');
 s+='\n// ADVENT DEMO ABI START\nandroid { defaultConfig { ndk { abiFilters.clear(); abiFilters.addAll(listOf('+values.map(x=>'"'+x+'"').join(', ')+')) } } }\n// ADVENT DEMO ABI END\n';fs.writeFileSync(f,s);
}
