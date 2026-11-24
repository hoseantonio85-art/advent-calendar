const fs=require('node:fs'),assert=require('node:assert/strict'),path=require('node:path');
const root=path.resolve(__dirname,'..'),html=fs.readFileSync(path.join(root,'index.html'),'utf8');
function literal(name,end){const start=html.indexOf('const '+name+'=')+('const '+name+'=').length;return Function('return ('+html.slice(start,html.indexOf(end,start)+3)+')')();}
const events=literal('events','\n };'),thoughts=literal('thoughts','\n ];');
const wide=JSON.parse(html.match(/const wideDays=new Set\((\[[^\]]+\])/)[1]);
const art=Function('return '+html.match(/const artForAdvice=(\[[^;]+\])/)[1])();
const data=JSON.parse(fs.readFileSync(path.join(root,'flutter/assets/advent/calendar_2026.json'),'utf8'));
assert.equal(data.days.length,31);assert.equal(new Set(data.days.map(d=>d.id)).size,31);
assert.equal(data.days.filter(d=>d.kind==='event').length,14);assert.equal(data.days.filter(d=>d.kind==='advice').length,17);
for(const [i,d] of data.days.entries()){
 const day=i+1,e=events[day];assert.equal(d.date,'2026-12-'+String(day).padStart(2,'0'));
 assert.equal(d.columns,wide.includes(day)?2:1);assert.equal(d.theme,e?.theme||(i%3===0?'alt':''));
 assert.equal(d.title,e?.title||thoughts[i][0]);assert.equal(d.art,e?.art||art[i%art.length]);
 assert.deepEqual(Object.values(d.advice),thoughts[i]);
 if(e){const {locations,startTime,verification,...source}=d.event;assert.deepEqual(source,e);assert.deepEqual(locations,e.place.split('; ').map(x=>x.trim()));assert.equal(startTime,/^\d\d:\d\d$/.test(e.time)?e.time:null);assert.equal(verification,'requiresConfirmation');}else assert.equal(d.event,null);
}
const sourceAssets={};for(const m of html.matchAll(/(?:assets(?:\.(\w+)|\["(\w+)"\])\s*=|["']?(\w+)["']?\s*:)\s*["'](data:image\/[^"']+)["']/g))if(m[4].includes(';base64,'))sourceAssets[m[1]||m[2]||m[3]]=m[4];
sourceAssets.hero_tree=html.match(/class="hero-art"[\s\S]*?<img[^>]+src="([^"]+)"/)[1];
for(const [key,p] of Object.entries(data.assets))assert.deepEqual(fs.readFileSync(path.join(root,'flutter',p)),Buffer.from(sourceAssets[key].split(',')[1],'base64'),key);
console.log('PASS: 31/14/17; every source field, advice, layout and 16 art files match HTML exactly');
