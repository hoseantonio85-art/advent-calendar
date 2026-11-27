const fs=require('node:fs'),path=require('node:path');
const {ROOT,readContent,orderedDays}=require('./content.cjs');
function exportCsv(data){
 const header=['date','id','type','advice_title','advice_text','advice_action','event_title','event_short_title','event_description','time','duration_minutes','place','verification','reveal_on_date','art','theme','bento_columns','card_lines','map_url'];
 const rows=orderedDays(data).map(d=>{const e=d.event,s=e||d.advice;return [d.date,d.id,e?'event':'advice',d.advice.title,d.advice.text,d.advice.action,e?.title,e?.shortTitle,e?.desc,e?.time,e?.duration,e?.place,e?.verification,!!(e&&d.revealOnDate),s.art,s.theme,s.columns,e?.cardLines?.join('\n'),e?.mapUrl];});
 const cell=v=>'"'+String(v??'').replace(/"/g,'""')+'"';
 return '\uFEFF'+[header,...rows].map(row=>row.map(cell).join(',')).join('\r\n')+'\r\n';
}
if(require.main===module){
 const args=process.argv.slice(2);if(args.length&&!(args.length===2&&args[0]==='--out'))throw Error('Usage: node tools/export-content.cjs [--out path.csv]');
 const out=path.resolve(ROOT,args[1]||'build/content/calendar_2026.csv');fs.mkdirSync(path.dirname(out),{recursive:true});fs.writeFileSync(out,exportCsv(readContent()));
 console.log('CSV: '+path.relative(ROOT,out));
}
module.exports={exportCsv};
