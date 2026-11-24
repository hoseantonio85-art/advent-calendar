const {test}=require('node:test'),assert=require('node:assert/strict');
const {versions}=require('./demo-android-version.cjs');
test('sequential APKs and retried/new builds always increase',()=>{
  const first=versions(123,1),retry=versions(123,2),next=versions(124,1);
  assert.equal(first.candidate,first.baseline+1);
  assert.ok(retry.baseline>first.candidate);assert.ok(next.baseline>versions(123,49).candidate);
  assert.equal(first.applicationId,next.applicationId);
});
test('reject invalid counters rather than wrap or downgrade',()=>{
  for(const pair of [[0,1],[1,0],[1,50],[1.5,1],[NaN,1],[21000000,1]])assert.throws(()=>versions(...pair));
  assert.ok(versions(20999999,49).candidate<2100000000);
});
