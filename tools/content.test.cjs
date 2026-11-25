const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),os=require('node:os'),crypto=require('node:crypto');
const {ROOT,BLOCKS,marker,readContent,validateContent,projectFlutter,webData,renderHtml,generate}=require('./content.cjs');
const {cases}=require('./content-test-fixtures.cjs'),{exportCsv}=require('./export-content.cjs');
const master=readContent(),html=fs.readFileSync(path.join(ROOT,'index.html'),'utf8').replace(/\r\n/g,'\n');
const approved=require('./fixtures/calendar-2026-approved.json'),hash=s=>crypto.createHash('sha256').update(s).digest('hex');
function shell(s){for(const name of Object.values(BLOCKS)){const a=s.indexOf(marker(name))+marker(name).length,b=s.indexOf(marker(name,true));s=s.slice(0,a)+'\n'+s.slice(b);}return s;}
function parsed(s){return {events:JSON.parse(s.match(/ const events=(\{[\s\S]*?\n \});/)[1]),thoughts:JSON.parse(s.match(/ const thoughts=(\[[\s\S]*?\n \]);/)[1])};}
test('approved campaign: 31/14/17, byte-identical runtime data, HTML shell and all art',()=>{
 assert.equal(master.days.length,approved.days);assert.equal(master.days.filter(d=>d.event).length,approved.events);
 assert.equal(master.days.filter(d=>!d.event).length,approved.advice);
 assert.equal(hash(JSON.stringify(projectFlutter(master),null,2)+'\n'),approved.runtimeSha256);
 assert.equal(hash(JSON.stringify(webData(master))),approved.webDataSha256);
 assert.equal(hash(shell(html)),approved.htmlShellSha256);
 for(const [key,digest] of Object.entries(approved.assets))assert.equal(hash(fs.readFileSync(path.join(ROOT,'flutter',master.assets[key]))),digest,key);
});
test('editing 19 December reaches both representations without changing the original',()=>{
 const changed=cases(master).edit19,web=parsed(renderHtml(html,changed)),runtime=projectFlutter(changed);
 assert.equal(web.events[19].title,'Проверка редактирования 19 декабря');
 assert.equal(runtime.days[18].title,web.events[19].title);assert.equal(runtime.days[18].event.desc,web.events[19].desc);
 assert.equal(runtime.days[18].event.startTime,null);assert.equal(runtime.days[18].event.place,'Система оценок');
 assert.equal(hash(JSON.stringify(projectFlutter(master),null,2)+'\n'),approved.runtimeSha256);
});
test('event overlay and removal restore stable day/advice and its own art/theme/Bento',()=>{
 const c=cases(master),added=projectFlutter(c.added3),restored=projectFlutter(c.restored3),removed=projectFlutter(c.removed1);
 assert.equal(added.days.filter(d=>d.event).length,15);assert.equal(added.days[2].kind,'event');assert.equal(added.days[2].columns,2);
 assert.deepEqual(restored,projectFlutter(c.original));assert.equal(removed.days.filter(d=>d.event).length,13);
 const day=removed.days[0],a=master.days[0].advice;
 assert.equal(day.id,'december-2026-01');assert.equal(day.kind,'advice');assert.equal(day.art,a.art);assert.equal(day.theme,a.theme);assert.equal(day.columns,a.columns);
 const web=parsed(renderHtml(html,c.removed1));assert.equal(web.events[1],undefined);assert.deepEqual(web.thoughts[0],[a.title,a.text,a.action]);
});
test('counts are not a schema limit and surprise flags activate only with an approved event',()=>{
 const c=cases(master);assert.equal(projectFlutter(c.allAdvice).days.filter(d=>d.event).length,0);
 assert.equal(projectFlutter(c.removed4).days[3].revealOnDate??false,false);assert.equal(c.removed4.days[3].revealOnDate,true);
 assert(!webData(c.removed4).surpriseDays.includes(4));
 const bad=structuredClone(master);bad.days[0].revealOnDate=true;assert.throws(()=>validateContent(bad),/not approved/);
});
test('reject incomplete/duplicate dates, missing advice/event fields, art, malformed times and paths',()=>{
 for(const mutate of [d=>d.days.pop(),d=>{d.days[1]=d.days[0];},d=>{d.days[0].date='2026-12-32';},d=>{d.days[0].id='new-id';},d=>{delete d.days[0].advice;},d=>{d.days[0].advice.text='';},d=>{d.days[0].advice.art='unknown';},d=>{delete d.days[0].event.time;},d=>{d.days[0].event.place='';},d=>{d.days[0].event.time='25:00';},d=>{d.days[0].event.duration=0;},d=>{d.assets.gift='../private';},d=>{d.days[0].unexpected='lost metadata';}]){
  const bad=structuredClone(master);mutate(bad);assert.throws(()=>validateContent(bad));
 }
});
test('generation is deterministic, restores approved data and never rewrites unrelated HTML',()=>{
 assert.equal(renderHtml(html,master),html);assert.equal(renderHtml(renderHtml(html,cases(master).edit19),master),html);
 const reordered=structuredClone(master);reordered.days.reverse();assert.deepEqual(projectFlutter(reordered),projectFlutter(master));
 assert.equal(shell(renderHtml(html,cases(master).added3)),shell(html));
 assert.throws(()=>renderHtml(html.replace(marker(BLOCKS.days),'missing boundary'),master),/boundary/);
});
test('script literals cannot escape into surrounding HTML',()=>{
 const data=structuredClone(master);data.days[18].event.title='</script><script>bad()</script>\u2028';
 const result=renderHtml(html,data);assert.equal(parsed(result).events[19].title,data.days[18].event.title);
 assert.equal((result.match(/<\/script>/g)||[]).length,(html.match(/<\/script>/g)||[]).length);
});
test('--check detects edits to generated HTML and Flutter; regeneration repairs both',()=>{
 const dir=fs.mkdtempSync(path.join(os.tmpdir(),'advent7-content-test-'));
 try{
  for(const rel of ['content/calendar_2026.json','index.html',...Object.values(master.assets).map(p=>'flutter/'+p)]){
   fs.mkdirSync(path.dirname(path.join(dir,rel)),{recursive:true});fs.copyFileSync(path.join(ROOT,rel),path.join(dir,rel));
  }
  fs.mkdirSync(path.join(dir,'flutter/assets/advent'),{recursive:true});generate({root:dir});generate({root:dir,check:true});
  fs.writeFileSync(path.join(dir,'index.html'),renderHtml(html,cases(master).edit19));assert.throws(()=>generate({root:dir,check:true}),/index.html/);
  generate({root:dir});fs.appendFileSync(path.join(dir,'flutter/assets/advent/calendar_2026.json'),' ');
  assert.throws(()=>generate({root:dir,check:true}),/calendar_2026.json/);generate({root:dir});generate({root:dir,check:true});
 }finally{
  const resolved=path.resolve(dir);assert(resolved.startsWith(path.resolve(os.tmpdir())+path.sep)&&path.basename(resolved).startsWith('advent7-content-test-'));
  fs.rmSync(resolved,{recursive:true,force:true});
 }
});
test('CSV is deterministic UTF-8 with BOM, multiline quoting and advice retained beneath events',()=>{
 const csv=exportCsv(master);assert.equal(csv.charCodeAt(0),0xfeff);assert.equal(exportCsv(master),csv);
 assert(csv.includes('"2026-12-19","december-2026-19","event","Помни о главном"'));
 assert(csv.includes('"Не указано"'));assert(csv.includes('"Сегодня открывается система оценок за год и 4 квартал. 🎯\n\n'));
 const data=structuredClone(master);data.days[18].advice.title='текст, "кавычки"\nновая строка';
 assert(exportCsv(data).includes('"текст, ""кавычки""\nновая строка"'));
});
