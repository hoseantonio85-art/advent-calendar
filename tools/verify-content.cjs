const fs=require('node:fs'),assert=require('node:assert/strict'),path=require('node:path');
const {ROOT,readContent,generate}=require('./content.cjs');
generate({check:true});const master=readContent();
const html=fs.readFileSync(path.join(ROOT,'index.html'),'utf8');
function match(regex,label){const m=html.match(regex);assert(m,'Missing '+label);return JSON.parse(m[1]);}
const events=match(/ const events=(\{[\s\S]*?\n \});/,'events'),thoughts=match(/ const thoughts=(\[[\s\S]*?\n \]);/,'thoughts');
const wide=match(/const wideDays=new Set\((\[[^\]]*\])/,'Bento'),art=match(/const artForAdvice=(\[[^;]+\])/,'advice art');
const themes=match(/const adviceThemes=(\[[^;]+\])/,'advice themes'),surprises=match(/const surpriseDays=new Set\((\[[^\]]*\])/,'surprises');
const data=JSON.parse(fs.readFileSync(path.join(ROOT,'flutter/assets/advent/calendar_2026.json'),'utf8'));
assert.equal(data.days.length,31);assert.equal(new Set(data.days.map(d=>d.id)).size,31);
for(const [i,d] of data.days.entries()){
 const day=i+1,e=events[day],source=master.days.find(s=>s.id===d.id);
 assert.equal(d.date,'2026-12-'+String(day).padStart(2,'0'));assert.equal(d.kind,e?'event':'advice');
 assert.equal(d.revealOnDate??false,surprises.includes(day));
 assert.equal(d.columns,wide.includes(day)?2:1);assert.equal(d.theme,e?.theme??themes[i]);
 assert.equal(d.title,e?.title??thoughts[i][0]);assert.equal(d.art,e?.art??art[i]);
 assert.deepEqual(Object.values(d.advice),thoughts[i]);
 if(e){const {locations,startTime,verification,...fields}=d.event;assert.deepEqual(fields,e);assert.deepEqual(locations,e.place.split('; ').map(s=>s.trim()));assert.equal(startTime,/^([01]\d|2[0-3]):[0-5]\d$/.test(e.time)?e.time:null);assert.equal(verification,source.event.verification);}
 else assert.equal(d.event,null);
}
const sourceAssets={};
for(const m of html.matchAll(/(?:assets(?:\.(\w+)|\["(\w+)"\])\s*=|["']?(\w+)["']?\s*:)\s*["'](data:image\/[^"']+)["']/g))if(m[4].includes(';base64,'))sourceAssets[m[1]||m[2]||m[3]]=m[4];
sourceAssets.hero_tree=html.match(/class="hero-art"[\s\S]*?<img[^>]+src="([^"]+)"/)[1];
for(const [key,file] of Object.entries(data.assets)){
 assert.equal(typeof sourceAssets[key],'string',`Art ${key} must also be embedded in standalone HTML`);
 assert.deepEqual(fs.readFileSync(path.join(ROOT,'flutter',file)),Buffer.from(sourceAssets[key].split(',')[1],'base64'),key);
}
const n=data.days.filter(d=>d.kind==='event').length;
console.log(`PASS: 31/${n}/${31-n}; master/HTML/Flutter fields, advice, Bento and ${Object.keys(data.assets).length} art files match`);
