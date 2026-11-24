// Loaded only from the trusted publisher commit on main, before any key is used.
const {versions}=require('./demo-android-version.cjs');
const repository='hoseantonio85-art/advent-calendar';
const gates=['verify','android-motion','android-release','android-upgrade'];
function validateSource(run,jobs){
  const main=run.event==='push'&&run.head_branch==='main';
  const preview=run.event==='pull_request'&&run.head_branch==='feature/issue-2-native-calendar';
  if(run.workflow_id!==427003215||run.status!=='completed'||run.conclusion!=='success'||
      run.repository?.full_name!==repository||run.head_repository?.full_name!==repository||
      !(main||preview)||!/^[a-f0-9]{40}$/.test(run.head_sha??'')){
    throw Error('Untrusted source: require successful same-repository Flutter main push or calendar PR');
  }
  // The existing workflow run counter is the demo's version namespace.
  const version=versions(run.run_number,run.run_attempt);
  for(const name of gates){
    const matches=jobs.filter(j=>j.name===name);
    if(matches.length!==1||matches[0].conclusion!=='success'||matches[0].status!=='completed'){
      throw Error(`Required CI gate did not pass exactly once: ${name}`);
    }
  }
  return {source:main?'main':'pull_request',version};
}
module.exports={validateSource};
