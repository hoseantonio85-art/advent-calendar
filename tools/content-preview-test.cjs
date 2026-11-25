// Real browser acceptance of generated variants using the existing QA preview.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {pathToFileURL}=require('node:url'),{chromium}=require('playwright');
const {ROOT,readContent,renderHtml}=require('./content.cjs'),{cases}=require('./content-test-fixtures.cjs');
async function main(){
 const master=readContent(),data=cases(master),template=fs.readFileSync(path.join(ROOT,'index.html'),'utf8');
 const folder=path.join(ROOT,'build/content-preview');fs.mkdirSync(folder,{recursive:true});
 const file=path.join(folder,'calendar.html'),url=pathToFileURL(file).href;
 const browser=await chromium.launch({headless:true});
 try{
  const context=await browser.newContext({viewport:{width:390,height:844},timezoneId:'Europe/Moscow',reducedMotion:'reduce'});
  const page=await context.newPage(),errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  await page.route('https://fonts.googleapis.com/**',route=>route.fulfill({contentType:'text/css',body:
   `@font-face{font-family:'Roboto';font-weight:100 900;src:url(data:font/ttf;base64,${fs.readFileSync(path.join(ROOT,'flutter/assets/fonts/Roboto-Variable.ttf')).toString('base64')});}@font-face{font-family:'Yeseva One';font-weight:400;src:url(data:font/ttf;base64,${fs.readFileSync(path.join(ROOT,'flutter/assets/fonts/YesevaOne-Regular.ttf')).toString('base64')});}`}));
  await page.addInitScript(()=>{const Native=Date;window.Date=class extends Native{constructor(...args){super(...(args.length?args:['2026-12-31T09:00:00Z']));}static now(){return new Native('2026-12-31T09:00:00Z').getTime();}};});
  async function load(source,query='?preview=31'){
   fs.writeFileSync(file,renderHtml(template,source));await page.goto(url+query);await page.evaluate(()=>document.fonts.ready);
   assert.equal(await page.locator('.day-card').count(),31);
  }
  async function close(){await page.locator('#closeSheet').click();}
  await load(data.edit19);await page.locator('[data-day="19"]').click();
  assert((await page.locator('#sheet').textContent()).includes('Проверка редактирования 19 декабря'));
  assert((await page.locator('#sheet').textContent()).includes('из единого источника'));await close();
  await load(data.added3);assert(await page.locator('[data-day="3"]').evaluate(e=>e.classList.contains('event')&&e.classList.contains('wide')));
  await load(data.restored3);assert(await page.locator('[data-day="3"]').evaluate(e=>e.classList.contains('wisdom')&&!e.classList.contains('wide')));
  await page.locator('[data-day="3"]').click();assert((await page.locator('#sheet').textContent()).includes(master.days[2].advice.text));await close();
  await load(data.original,'?preview=3');await page.locator('[data-day="4"]').click();assert.equal(await page.locator('#sheet').getAttribute('aria-hidden'),'true');
  await load(data.removed4,'?preview=31');await page.locator('[data-day="4"]').click();assert.equal(await page.locator('.surprise-confetti').count(),0);await close();
  // Stable IDs/data survive a real event/advice overlay. No QA progress writes.
  await load(data.original,'');
  await page.evaluate(()=>{localStorage.setItem('advent2026-visited',JSON.stringify([1,3]));localStorage.setItem('advent2026-saved',JSON.stringify([3]));});
  await load(data.added3,'');
  assert.deepEqual(await page.evaluate(()=>JSON.parse(localStorage.getItem('advent2026-saved'))),[3]);
  assert.deepEqual(await page.evaluate(()=>JSON.parse(localStorage.getItem('advent2026-visited'))),[1,3]);
  await load(data.restored3,'');
  assert.equal(await page.locator('[data-day="3"] .saved-heart').count(),1);
  assert((await page.locator('.progress-panel').textContent()).includes('2 / 31'));
  assert.deepEqual(await page.evaluate(()=>JSON.parse(localStorage.getItem('advent2026-saved'))),[3]);
  await load(data.original);await page.screenshot({path:path.join(folder,'restored-preview-31.png')});
  assert.deepEqual(errors,[]);await context.close();
  fs.writeFileSync(path.join(folder,'result.json'),JSON.stringify({result:'PASS',cases:['edit19','add/remove event','advice art/Bento fallback','preview=31/3','removed surprise','raw views/saved persistence'],productionFilesChanged:false},null,2)+'\n');
  console.log('PASS: generated HTML preview=31, edit19, event overlay/fallback, surprises, progress/saved persistence');
 }finally{await browser.close();}
}
main().catch(e=>{console.error(e);process.exitCode=1;});
