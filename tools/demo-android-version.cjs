const fs=require('node:fs');
const APP_ID='com.example.advent_demo';
function versions(run,attempt){
  if(!Number.isSafeInteger(run)||run<1||!Number.isSafeInteger(attempt)||attempt<1||attempt>49)throw Error('Invalid build sequence');
  const baseline=run*100+attempt*2,candidate=baseline+1;
  if(candidate>2100000000)throw Error('Android versionCode exhausted');
  return {applicationId:APP_ID,baseline,candidate,versionName:`0.1.${run}.${attempt}`,runNumber:run,attempt};
}
if(require.main===module){
  const v=versions(Number(process.env.GITHUB_RUN_NUMBER),Number(process.env.GITHUB_RUN_ATTEMPT));
  fs.mkdirSync('build',{recursive:true});fs.writeFileSync('build/demo-build-version.json',JSON.stringify(v,null,2)+'\n');
  if(!process.env.GITHUB_ENV)throw Error('GITHUB_ENV is required');
  fs.appendFileSync(process.env.GITHUB_ENV,`DEMO_VERSION_CODE=${v.candidate}\nDEMO_BASELINE_CODE=${v.baseline}\nDEMO_VERSION_NAME=${v.versionName}\n`);
  console.log(`Demo ${APP_ID}: ${v.baseline} -> ${v.candidate}, ${v.versionName}`);
}
module.exports={versions,APP_ID};
