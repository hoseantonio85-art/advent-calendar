const path=require('node:path'),fs=require('node:fs');
const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true});
 async function capture(page,name){fs.mkdirSync('build/visual-qa',{recursive:true});await page.screenshot({path:`build/visual-qa/reference-${name}.png`});}
 for(const width of [320,360,390,430]){
  const context=await browser.newContext({viewport:{width,height:844},deviceScaleFactor:1,reducedMotion:'reduce',timezoneId:'Europe/Moscow'});
  const page=await context.newPage();
  await page.addInitScript(()=>{const Native=Date;window.Date=class extends Native{constructor(...args){super(...(args.length?args:['2026-12-15T09:00:00Z']));}static now(){return new Native('2026-12-15T09:00:00Z').getTime();}};window.ADVENT_CONFIG={timeZone:'Europe/Moscow'};});
  await page.route('https://fonts.googleapis.com/**',route=>route.fulfill({contentType:'text/css',body:
   `@font-face{font-family:'Roboto';font-weight:100 900;src:url(data:font/ttf;base64,${fs.readFileSync('flutter/assets/fonts/Roboto-Variable.ttf').toString('base64')});}@font-face{font-family:'Yeseva One';font-weight:400;src:url(data:font/ttf;base64,${fs.readFileSync('flutter/assets/fonts/YesevaOne-Regular.ttf').toString('base64')});}`}));
  await page.goto('file://'+path.resolve('index.html').split(path.sep).join('/'));await page.evaluate(()=>document.fonts.ready);
  if(!await page.evaluate(()=>document.fonts.check('400 12px "Roboto"')&&document.fonts.check('400 28px "Yeseva One"')))throw Error('Reference font fallback');
  console.log('ADVENT_METRICS|'+width+'|'+JSON.stringify(await page.evaluate(()=>Object.fromEntries(['.hero h1','.hero-art','.progress-panel','.day-card[data-day="2"] .illustration','.day-card[data-day="9"] .illustration','.day-card[data-day="25"] .illustration','.day-card[data-day="31"] .illustration'].map(q=>{const e=document.querySelector(q),s=getComputedStyle(e),r=e.getBoundingClientRect();return[q,{x:r.x,y:r.y,width:r.width,height:r.height,font:s.fontSize,top:s.top,right:s.right}]})))));
  await capture(page,`calendar-${width}`);
  if(width==320||width==390){await page.evaluate(()=>window.scrollTo(0,document.body.scrollHeight));await capture(page,`finale-${width}`);}
  async function show(day){if(day==1||day==3)await page.evaluate(()=>window.scrollTo(0,0));await page.locator(`[data-day="${day}"]`).click();await page.waitForTimeout(50);}
  async function close(){await page.locator('#closeSheet').click();await page.waitForTimeout(50);}
  if(width==390){
   await page.locator('[data-day="15"]').evaluate(el=>window.scrollTo(0,el.getBoundingClientRect().top+window.scrollY-(window.innerHeight-el.offsetHeight)*.4));await capture(page,'middle-390');
   await show(1);await capture(page,'event-390');await close();
   await show(3);await capture(page,'advice-390');await close();
   await page.locator('#aboutBtn').click();await page.waitForTimeout(50);await capture(page,'history-390');await close();
  }
  if(width==320){await show(11);await capture(page,'long-event-320');await page.locator('.sheet-scroll').evaluate(el=>el.scrollTop=el.scrollHeight);await capture(page,'long-event-bottom-320');}
  await context.close();
 }
 await browser.close();
})().catch(e=>{console.error(e);process.exitCode=1;});
