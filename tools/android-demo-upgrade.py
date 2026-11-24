"""Real UI + adb install -r test of two ordinary release APKs, no test entrypoint."""
import argparse, base64, hashlib, json, os, re, subprocess, time, zipfile
from pathlib import Path
import xml.etree.ElementTree as ET

P=argparse.ArgumentParser();P.add_argument('--baseline',required=True);P.add_argument('--candidate',required=True);P.add_argument('--out',required=True);args=P.parse_args()
out=Path(args.out);out.mkdir(parents=True,exist_ok=True)
app='com.example.advent_demo'
def run(*cmd,binary=False,timeout=35):
    p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=timeout)
    if p.returncode: raise RuntimeError('Command failed: '+' '.join(cmd[:3])+'; '+p.stderr.decode(errors='replace')[-500:])
    return p.stdout if binary else p.stdout.decode(errors='replace')
def adb(*cmd,**kw):return run('adb',*cmd,**kw)
def tool(name):
    return sorted((Path(os.environ['ANDROID_HOME'])/'build-tools').glob('*/'+name),key=lambda p:[int(n) for n in re.findall(r'\d+',p.parent.name)])[-1]
def metadata(apk):
    text=run(str(tool('aapt')),'dump','badging',apk)
    m=re.search(r"^package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'",text,re.M)
    assert m and m[1]==app and 'application-debuggable' not in text,'Need ordinary release demo APK'
    certs=re.findall(r'certificate SHA-256 digest:\s*([a-fA-F0-9]+)',run(str(tool('apksigner')),'verify','--print-certs',apk))
    assert len(certs)==1,'Expected one signing identity'
    return {'applicationId':m[1],'versionCode':int(m[2]),'versionName':m[3],'certificateSha256':certs[0].lower(),'apkSha256':hashlib.sha256(Path(apk).read_bytes()).hexdigest()}
def screenshot(name):
    (out/(name+'.png')).write_bytes(adb('exec-out','screencap','-p',binary=True))
def tree():
    # UIAutomator itself enables accessibility/Flutter semantics. No app hook.
    adb('shell','uiautomator','dump','--compressed','/sdcard/advent-upgrade-ui.xml',timeout=20)
    text=adb('shell','cat','/sdcard/advent-upgrade-ui.xml')
    (out/'last-ui.xml').write_text(text)
    return ET.fromstring(text)
def find(label):
    found=[]
    for n in tree().iter('node'):
        value=n.get('text','')+' '+n.get('content-desc','')
        if label not in value or n.get('package')!=app:continue
        bounds=[int(x) for x in re.findall(r'\d+',n.get('bounds',''))]
        if len(bounds)!=4:continue
        x,y,r,b=bounds
        if r>x and b>y:found.append(((r-x)*(b-y),(x+r)//2,(y+b)//2))
    return min(found)[1:] if found else None
def swipe(direction):
    adb('shell','input','swipe','500','1050' if direction=='up' else '350','500','350' if direction=='up' else '1050','450');time.sleep(1)
def wait_for(label,scroll=None):
    for i in range(10):
        p=find(label)
        if p:return p
        if scroll and i>=2:swipe(scroll)
        else:time.sleep(1)
    screenshot('failure');raise AssertionError('UI label not found: '+label)
def click(label,scroll=None):
    x,y=wait_for(label,scroll);adb('shell','input','tap',str(x),str(y));time.sleep(1.5)
def uid():
    s=adb('shell','cmd','package','list','packages','-U',app)
    (out/'package-uid.txt').write_text(s)
    m=re.search(r'\buid:(\d+)',s)
    if not m:raise AssertionError('Installed package UID unavailable')
    return m.group(1)
def launch():
    # Match the existing native CI renderer override on software GPU only.
    # The ordinary release APK and its physical-device defaults are unchanged.
    command=['adb','shell','am','start','-W','-n',app+'/.MainActivity','--ez','enable-impeller','false']
    started=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=60)
    (out/'launch-status.txt').write_bytes(started.stdout+started.stderr)
    if started.returncode:raise RuntimeError('Android launch failed: '+(started.stdout+started.stderr).decode(errors='replace')[-1000:])
    time.sleep(4)
def varint(data,pos):
    n=shift=0
    while True:
        b=data[pos];pos+=1;n|=(b&127)<<shift
        if b<128:return n,pos
        shift+=7
def fields(data):
    pos=0
    while pos<len(data):
        tag,pos=varint(data,pos);number,wire=tag>>3,tag&7
        if wire==0:value,pos=varint(data,pos)
        elif wire==2:
            size,pos=varint(data,pos);value=data[pos:pos+size];pos+=size
        elif wire in (1,5):
            size=8 if wire==1 else 4;value=data[pos:pos+size];pos+=size
        else:raise AssertionError('Unexpected Preferences protobuf wire')
        yield number,wire,value
scope=base64.urlsafe_b64encode(b'standalone-demo').decode()
prefix='advent.v1.'+scope+'.december-2026.'
expected={prefix+'opened.december-2026-01':True,prefix+'opened.december-2026-03':True,prefix+'saved.december-2026-03':True}
def facts():
    paths=adb('shell','find','/data/user/0/'+app+'/files','-name','*.preferences_pb').splitlines()
    result={}
    for path in paths:
        data=adb('exec-out','cat',path,binary=True)
        for number,wire,entry in fields(data):
            if number!=1 or wire!=2:continue
            item={n:v for n,w,v in fields(entry)}
            key=item.get(1,b'').decode(errors='replace')
            if key.startswith(prefix):
                value={n:v for n,w,v in fields(item[2])}
                if 1 in value:result[key]=bool(value[1])
    assert all(result.get(k)==v for k,v in expected.items()),'Stored opened/saved facts are missing'
    return result
try:
    before=metadata(args.baseline);after=metadata(args.candidate)
    assert after['versionCode']>before['versionCode'],'APK versionCode must increase'
    assert before['certificateSha256']==after['certificateSha256'],'Signing certificate changed'
    with zipfile.ZipFile(args.baseline) as z:
        name=next(n for n in z.namelist() if n.endswith('/assets/advent/calendar_2026.json'))
        content=json.loads(z.read(name));advice=content['days'][2]['title']
    with zipfile.ZipFile(args.candidate) as z:new_content=json.loads(z.read(name))
    assert content['campaignId']==new_content['campaignId'],'Campaign migration requires an explicit update fixture'
    for i in [0,2]:assert content['days'][i]['id']==new_content['days'][i]['id'],'Persistent day ids changed'
    assert content['days'][2]['kind']==new_content['days'][2]['kind']=='advice','Saved-advice fixture requires migration review'
    new_advice=new_content['days'][2]['title']
    assert not adb('shell','pm','list','packages',app).strip(),'Fresh isolated emulator required; never uninstall to hide a failed update'
    # adb root restarts the device-side daemon. "closed" can mean it is
    # restarting successfully, so wait for root and both Android services.
    ready=False
    for attempt in range(3):
        root=subprocess.run(['adb','root'],stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=25)
        root_log=(root.stdout+root.stderr).decode(errors='replace')
        (out/'adb-root-status.txt').write_text(root_log)
        if root.returncode and not any(t in root_log.lower() for t in ['closed','restarting','offline']):raise RuntimeError('Root unavailable on test emulator: '+root_log)
        adb('wait-for-device',timeout=45)
        for check in range(30):
            try:
                ready=adb('shell','id','-u').strip()=='0' and adb('shell','getprop','sys.boot_completed').strip()=='1' and adb('shell','am','get-current-user').strip()=='0'
            except (RuntimeError,subprocess.TimeoutExpired):ready=False
            if ready:break
            time.sleep(1)
        if ready:break
    assert ready,'Emulator transport/services did not recover after adb root'
    time.sleep(2)
    adb('shell','settings','put','global','auto_time','0');adb('shell','settings','put','global','auto_time_zone','0')
    adb('shell',"date -s '2026-12-15 12:00:00'")
    for setting in ['window_animation_scale','transition_animation_scale','animator_duration_scale']:adb('shell','settings','put','global',setting,'0')
    adb('shell','wm','size','720x1280');adb('shell','wm','density','320');adb('shell','settings','put','system','font_scale','1.0')
    assert 'Success' in adb('install',args.baseline,timeout=90)
    old_uid=uid();launch();click('Открой свой декабрь')
    wait_for('Засчитано 0 из 31')
    click('1 декабря,',scroll='up');click('Закрыть')
    click('3 декабря,',scroll='up');click('Сохранить совет',scroll='up');wait_for('Совет сохранён');click('Закрыть')
    wait_for('Засчитано 2 из 31',scroll='down');screenshot('baseline-calendar')
    click('Твоя история декабря');wait_for(advice,scroll='up');screenshot('baseline-favorites')
    adb('shell','am','force-stop',app);time.sleep(1);raw_before=facts()
    update=adb('install','-r',args.candidate,timeout=90);assert 'Success' in update,'Real replacement install failed'
    assert uid()==old_uid,'UID changed: this was not an in-place update'
    raw_after=facts();assert raw_before==raw_after,'Stored facts changed during update'
    launch();click('Открой свой декабрь');wait_for('Засчитано 2 из 31');screenshot('candidate-calendar')
    click('Твоя история декабря');wait_for(new_advice,scroll='up');screenshot('candidate-favorites')
    result={'result':'PASS','operation':'adb install -r; no uninstall/clear/reset','baseline':before,'candidate':after,'unchangedUid':old_uid,'rawFactsBefore':raw_before,'rawFactsAfter':raw_after,'visibleProgress':'2 / 31','savedAdviceTitle':new_advice,'device':'API '+adb('shell','getprop','ro.build.version.sdk').strip()+' x86_64 emulator; ordinary ARM64+x86_64 release APKs; not a physical phone','fixtureClock':'2026-12-15, isolated emulator only','applicationEntrypoint':'lib/main.dart, no integration_test/QA entrypoint'}
    (out/'upgrade-report.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print('PASS: two consecutive release APKs updated in place; UID, raw opened/saved, visible progress and favorite retained')
except Exception:
    try:screenshot('failure')
    except Exception:pass
    try:(out/'failure-logcat.txt').write_text(adb('logcat','-d',timeout=10))
    except Exception:pass
    raise
