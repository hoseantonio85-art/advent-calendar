const {test}=require('node:test'),assert=require('node:assert/strict');
const {validateSource}=require('./demo-publication-policy.cjs');
const repo='hoseantonio85-art/advent-calendar';
const run={workflow_id:427003215,status:'completed',conclusion:'success',event:'push',
  repository:{full_name:repo},head_repository:{full_name:repo},head_branch:'main',
  head_sha:'a'.repeat(40),run_number:131,run_attempt:1};
const jobs=['verify','android-motion','android-release','android-upgrade'].map(name=>({name,status:'completed',conclusion:'success'}));
test('main source and existing PR preview retain one version namespace',()=>{
  const a=validateSource(run,jobs);
  const b=validateSource({...run,event:'pull_request',head_branch:'feature/issue-2-native-calendar'},jobs);
  assert.equal(a.source,'main');assert.equal(b.source,'pull_request');assert.deepEqual(a.version,b.version);
});
test('reject fork, foreign workflow, failed/incomplete build and invalid identity/version',()=>{
  for(const patch of [{repository:{full_name:'fork/calendar'}},{head_repository:{full_name:'fork/calendar'}},
    {workflow_id:1},{conclusion:'failure'},{status:'in_progress'},{head_sha:'bad'},
    {run_number:0},{run_attempt:50}])assert.throws(()=>validateSource({...run,...patch},jobs));
});
test('reject branch/event spoofing and other unapproved sources',()=>{
  for(const patch of [{event:'pull_request'},{head_branch:'feature/issue-2-native-calendar'},
    {event:'workflow_dispatch'},{event:'pull_request_target'},{head_branch:'other'}]){
    assert.throws(()=>validateSource({...run,...patch},jobs));
  }
});
test('all four gates must finish successfully; missing, skipped or duplicate gates fail closed',()=>{
  for(let n=0;n<jobs.length;n++){
    assert.throws(()=>validateSource(run,jobs.filter((_,i)=>i!==n)));
    for(const conclusion of ['skipped','failure','cancelled',null]){
      assert.throws(()=>validateSource(run,jobs.map((j,i)=>i===n?{...j,conclusion}:j)));
    }
    assert.throws(()=>validateSource(run,[...jobs,jobs[n]]));
  }
});
