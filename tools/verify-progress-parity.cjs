// Exercise the approved HTML's pure counter with the same date/raw-view cases
// as the domain contract. Do not run the page, DOM, artwork or preview modes.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync('index.html','utf8');
const start=html.indexOf('function visibleVisitedCount()');
const end=html.indexOf('\n }',start)+3;
assert(start>=0&&end>start,'Missing HTML progress function');
const source=html.slice(start,end);
const raw=[1,2,8,8,99,-1,'2',NaN];
for(const [y,m,d,expected] of [[2025,12,31,0],[2026,11,30,0],[2026,12,1,1],[2026,12,2,2],[2026,12,8,3],[2027,1,1,3]]){
  const context={displayToday:()=>({y,m,d}),progressVisited:()=>new Set(raw)};
  assert.equal(vm.runInNewContext(source+';visibleVisitedCount()',context),expected,`${y}-${m}-${d}`);
}
console.log('PASS: HTML Variant A dates/unique raw views/unknown IDs/year boundaries');
