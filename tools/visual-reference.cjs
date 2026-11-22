const fs=require('node:fs'),path=require('node:path');
const {chromium}=require('playwright');
(async()=>{
 const browser=await chromium.launch({headless:true});
 const page=await browser.newPage({viewport:{width:390,height:844},deviceScaleFactor:1,reducedMotion:'reduce'});
 await page.addInitScript(()=>{
  const OriginalDate=Date;
  window.Date=class extends OriginalDate {constructor(...args){super(...(args.length?args:['2026-12-15T09:00:00Z']));}static now(){return new OriginalDate('2026-12-15T09:00:00Z').getTime();}};
  window.ADVENT_CONFIG={timeZone:'Europe/Moscow'};
 });
 await page.goto('file://'+path.resolve('index.html').split(path.sep).join('/'));
 await page.evaluate(()=>document.fonts.ready);
 async function capture(name){const data=(await page.screenshot()).toString('base64');for(let i=0;i<data.length;i+=40000)console.log(`ADVENT_PNG|${name}|${i/40000}|${data.slice(i,i+40000)}`);}
 await capture('reference-calendar-390');
 await page.locator('[data-day="1"]').click();await page.waitForTimeout(600);await capture('reference-event-390');
 await browser.close();
})().catch(e=>{console.error(e);process.exitCode=1;});
