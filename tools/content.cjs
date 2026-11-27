// Shared build-time contract. Runtime apps keep their existing schema/storage.
const fs=require('node:fs'),path=require('node:path');
const ROOT=path.resolve(__dirname,'..');
const THEMES=['ruby','green','moss','purple','sand','ice','night'];
const SURPRISE_DAYS=[4,9,11,15];
const BLOCKS={days:'ADVENT DAYS',advice:'ADVENT ADVICE ART',surprises:'ADVENT SURPRISES'};
function fail(where,message){throw Error(`${where}: ${message}`);}
function object(value,where,keys){
 if(!value||typeof value!=='object'||Array.isArray(value))fail(where,'expected object');
 for(const key of Object.keys(value))if(!keys.includes(key))fail(where,`unknown field ${key}; update the versioned contract explicitly`);
}
function text(value,where){if(typeof value!=='string'||!value.trim())fail(where,'required non-empty text');}
function card(value,where,assets,advice=false){
 if(![1,2].includes(value.columns))fail(where,'columns must be 1 or 2');
 if(!Object.hasOwn(assets,value.art))fail(where,`unknown art ${value.art}`);
 if(!(advice?['','alt']:THEMES).includes(value.theme))fail(where,'unsupported theme');
}
function validateContent(data,{root=ROOT}={}){
 object(data,'content',['$schema','format','schemaVersion','campaignId','year','month','assets','days']);
 if(data.format!=='advent-content'||data.schemaVersion!==1||data.campaignId!=='december-2026'||data.year!==2026||data.month!==12)fail('content','unsupported format/schema/campaign');
 if(!data.assets||Array.isArray(data.assets)||typeof data.assets!=='object'||!Object.keys(data.assets).length)fail('assets','required catalogue');
 const assetBase=path.resolve(root,'flutter','assets');
 for(const [key,file] of Object.entries(data.assets)){
  if(!/^[A-Za-z][A-Za-z0-9_]*$/.test(key)||typeof file!=='string'||!file.startsWith('assets/')||file.includes('..')||file.includes('\\'))fail('assets','invalid key/path');
  const resolved=path.resolve(root,'flutter',file);
  if(!resolved.startsWith(assetBase+path.sep)||!fs.existsSync(resolved)||!fs.statSync(resolved).isFile())fail('assets',`missing file for ${key}`);
 }
 if(!Array.isArray(data.days)||data.days.length!==31)fail('days','expected 31 December dates');
 const dates=new Set(),ids=new Set();
 for(const day of data.days){
  object(day,'day',['id','date','advice','event','revealOnDate']);
  if(typeof day.date!=='string'||!/^2026-12-(0[1-9]|[12]\d|3[01])$/.test(day.date)||day.id!==`december-2026-${day.date.slice(-2)}`)fail('day','date/id must retain the stable December 2026 identity');
  if(dates.has(day.date)||ids.has(day.id))fail('days','duplicate date/id');dates.add(day.date);ids.add(day.id);
  const where=day.date;
  object(day.advice,where+'.advice',['title','text','action','art','theme','columns']);
  for(const field of ['title','text','action'])text(day.advice[field],where+'.advice.'+field);
  card(day.advice,where+'.advice',data.assets,true);
  if(typeof day.revealOnDate!=='boolean')fail(where,'revealOnDate must be explicit boolean');
  if(day.revealOnDate&&!SURPRISE_DAYS.includes(Number(day.date.slice(-2))))fail(where,'surprise date is not approved');
  if(!Object.hasOwn(day,'event'))fail(where,'event must be an object or explicit null');
  if(day.event!==null){
   const event=day.event;
   object(event,where+'.event',['title','shortTitle','art','theme','columns','time','duration','place','mapUrl','desc','cta','cardLines','sourceCopy','verification']);
   for(const field of ['title','shortTitle','time','place','desc','verification'])text(event[field],where+'.event.'+field);
   if(Object.hasOwn(event,'mapUrl')){
    const value=event.mapUrl;
    let url;try{url=new URL(value);}catch{}
    if(typeof value!=='string'||!/^https:\/\//.test(value)||/[\s\\]/.test(value)||/%(?![\da-f]{2})/i.test(value)||!url?.hostname||url.username||url.password)fail(where+'.event.mapUrl','expected an absolute HTTPS URL without credentials or whitespace');
   }
   card(event,where+'.event',data.assets);
   if(event.duration!==null&&(!Number.isInteger(event.duration)||event.duration<=0))fail(where,'duration must be positive minutes or null');
   if(/^\d{1,2}:\d{2}$/.test(event.time)&&!/^([01]\d|2[0-3]):[0-5]\d$/.test(event.time))fail(where,'invalid source time');
   if(event.cta!==undefined)text(event.cta,where+'.event.cta');
   if(event.sourceCopy!==undefined&&typeof event.sourceCopy!=='boolean')fail(where,'sourceCopy must be boolean');
   if(event.cardLines!==undefined){
    if(!Array.isArray(event.cardLines)||!event.cardLines.length)fail(where,'cardLines must be a non-empty array');
    event.cardLines.forEach(line=>text(line,where+'.event.cardLines'));
   }
  }
 }
 return data;
}
function readContent(root=ROOT){return validateContent(JSON.parse(fs.readFileSync(path.join(root,'content/calendar_2026.json'),'utf8')),{root});}
function orderedDays(data){return [...data.days].sort((a,b)=>a.date.localeCompare(b.date));}
function webEvent(event){if(!event)return null;const {columns,verification,...source}=event;return source;}
function projectFlutter(data,{root=ROOT}={}){
 validateContent(data,{root});
 return {schemaVersion:1,campaignId:data.campaignId,year:data.year,month:data.month,assets:{...data.assets},days:orderedDays(data).map(day=>{
  const e=day.event,style=e||day.advice;
  const item={id:day.id,date:day.date,kind:e?'event':'advice',title:style.title,art:style.art,columns:style.columns,theme:style.theme,
   advice:{title:day.advice.title,text:day.advice.text,action:day.advice.action},
   event:e?{...webEvent(e),locations:e.place.split('; ').map(s=>s.trim()),startTime:/^([01]\d|2[0-3]):[0-5]\d$/.test(e.time)?e.time:null,verification:e.verification}:null};
  // A removed event restores advice, not a hidden surprise. The dormant flag
  // remains in the master so restoring the original event keeps its agreement.
  if(e&&day.revealOnDate)item.revealOnDate=true;
  return item;
 })};
}
function webData(data){
 const days=orderedDays(data);
 return {events:Object.fromEntries(days.filter(d=>d.event).map(d=>[Number(d.date.slice(-2)),webEvent(d.event)])),
  thoughts:days.map(d=>[d.advice.title,d.advice.text,d.advice.action]),
  wideDays:days.filter(d=>(d.event||d.advice).columns===2).map(d=>Number(d.date.slice(-2))),
  artForAdvice:days.map(d=>d.advice.art),adviceThemes:days.map(d=>d.advice.theme),
  surpriseDays:days.filter(d=>d.event&&d.revealOnDate).map(d=>Number(d.date.slice(-2)))};
}
// Data must never terminate its surrounding <script>, even in editor fixtures.
function js(value){return JSON.stringify(value).replace(/[<>&\u2028\u2029]/g,c=>'\\u'+c.charCodeAt(0).toString(16).padStart(4,'0'));}
function marker(name,end=false){return ` // ${end?'END':'BEGIN'} GENERATED ${name}`;}
function replaceBlock(html,name,body){
 const start=marker(name),end=marker(name,true);
 if(html.split(start).length!==2||html.split(end).length!==2||html.indexOf(end)<html.indexOf(start))fail('index.html',`missing/duplicate ${name} boundary`);
 const a=html.indexOf(start),b=html.indexOf(end)+end.length;
 return html.slice(0,a)+start+'\n'+body+'\n'+end+html.slice(b);
}
function renderHtml(template,data,options={}){
 validateContent(data,options);const d=webData(data);
 let html=template.replace(/\r\n/g,'\n');
 const events=' const events={\n'+Object.entries(d.events).map(([day,e])=>`  ${js(day)}:${js(e)}`).join(',\n')+'\n };';
 const thoughts=' const thoughts=[\n'+d.thoughts.map(t=>'  '+js(t)).join(',\n')+'\n ];';
 html=replaceBlock(html,BLOCKS.days,events+'\n'+thoughts+`\n const wideDays=new Set(${js(d.wideDays)});`);
 html=replaceBlock(html,BLOCKS.advice,` const artForAdvice=${js(d.artForAdvice)};\n const adviceThemes=${js(d.adviceThemes)};`);
 return replaceBlock(html,BLOCKS.surprises,` const surpriseDays=new Set(${js(d.surpriseDays)});`);
}
function generate({root=ROOT,check=false}={}){
 const data=readContent(root),file=path.join(root,'index.html'),html=fs.readFileSync(file,'utf8');
 const outputs=new Map([['index.html',renderHtml(html,data,{root})],['flutter/assets/advent/calendar_2026.json',JSON.stringify(projectFlutter(data,{root}),null,2)+'\n']]);
 const stale=[];
 for(const [name,expected] of outputs){
  const target=path.join(root,name),actual=fs.existsSync(target)?fs.readFileSync(target,'utf8').replace(/\r\n/g,'\n'):null;
  if(actual!==expected){stale.push(name);if(!check)fs.writeFileSync(target,expected);}
 }
 if(check&&stale.length)fail('generated content',`out of sync: ${stale.join(', ')}; run node tools/generate-content.cjs`);
 return {days:31,events:data.days.filter(d=>d.event).length,advice:data.days.filter(d=>!d.event).length,changed:stale};
}
module.exports={ROOT,THEMES,SURPRISE_DAYS,BLOCKS,validateContent,readContent,orderedDays,webEvent,projectFlutter,webData,js,marker,renderHtml,generate};
