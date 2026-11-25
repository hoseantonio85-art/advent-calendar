// Temporary acceptance inputs only. None are written into app assets or HTML.
const {readContent,projectFlutter}=require('./content.cjs');
function cases(master=readContent()){
 const original=structuredClone(master),edit19=structuredClone(master),added3=structuredClone(master),removed1=structuredClone(master),removed4=structuredClone(master),allAdvice=structuredClone(master);
 const at=(data,n)=>data.days.find(d=>Number(d.date.slice(-2))===n);
 at(edit19,19).event.title='Проверка редактирования 19 декабря';
 at(edit19,19).event.desc+='\n\nТест: изменение только из единого источника.';
 at(added3,3).event={...structuredClone(at(master,19).event),title:'Временное мероприятие 3 декабря',shortTitle:'Временное мероприятие',cardLines:['Временное','мероприятие'],columns:2};
 at(removed1,1).event=null;at(removed4,4).event=null;allAdvice.days.forEach(d=>{d.event=null;});
 const restored3=structuredClone(added3);at(restored3,3).event=null;
 return {original,edit19,added3,restored3,removed1,removed4,allAdvice};
}
if(require.main===module)process.stdout.write(JSON.stringify(Object.fromEntries(Object.entries(cases()).map(([key,value])=>[key,projectFlutter(value)]))));
module.exports={cases};
