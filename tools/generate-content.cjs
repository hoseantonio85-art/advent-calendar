const {generate}=require('./content.cjs');
if(process.argv.slice(2).some(s=>s!=='--check'))throw Error('Usage: node tools/generate-content.cjs [--check]');
const result=generate({check:process.argv.includes('--check')});
console.log(`PASS: ${result.days}/${result.events}/${result.advice}; generated HTML/Flutter ${process.argv.includes('--check')?'in sync':'updated'} (${result.changed.length} changed)`);
