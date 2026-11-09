/* Navegador de laboratorio independiente del perfil del usuario. */
import { spawn, execFileSync } from 'node:child_process';
import { existsSync, readdirSync, mkdtempSync, rmSync } from 'node:fs';
import { createServer } from 'node:net';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { setTimeout as delay } from 'node:timers/promises';
const HERE = dirname(fileURLToPath(import.meta.url));
export class Cdp {
  constructor(ws) { this.ws=ws;this.id=0;this.pending=new Map();this.events=[];ws.onmessage=e=>{const m=JSON.parse(e.data),p=this.pending.get(m.id);if(p){clearTimeout(p.timer);this.pending.delete(m.id);m.error?p.reject(new Error(JSON.stringify(m.error))):p.resolve(m.result);}else this.events.push(m);};ws.onclose=()=>{for(const p of this.pending.values()){clearTimeout(p.timer);p.reject(new Error('Navegador de pruebas cerrado.'));}this.pending.clear();}; }
  send(method,params={},timeout=60000) {return new Promise((resolve,reject)=>{const id=++this.id,timer=setTimeout(()=>{this.pending.delete(id);reject(new Error('Timeout: '+method));},timeout);this.pending.set(id,{resolve,reject,timer});this.ws.send(JSON.stringify({id,method,params}));});}
  async evaluate(expression,awaitPromise=true){const r=await this.send('Runtime.evaluate',{expression,awaitPromise,returnByValue:true,userGesture:true},300000);if(r.exceptionDetails)throw new Error(r.exceptionDetails.exception?.description||r.exceptionDetails.text);return r.result.value;}
}
async function port(){return new Promise(resolve=>{const s=createServer();s.listen(0,'127.0.0.1',()=>{const p=s.address().port;s.close(()=>resolve(p));});});}
function chromePath(){const candidates=[process.env.CHROME_BIN];for(const bin of ['google-chrome','chromium','chromium-browser'])try{candidates.push(execFileSync('which',[bin],{encoding:'utf8',stdio:['ignore','pipe','ignore']}).trim());}catch{}for(const root of [join(process.env.HOME||'','.cache/puppeteer/chrome'),join(process.env.HOME||'','.cache/ms-playwright')])if(existsSync(root))for(const entry of readdirSync(root))for(const file of ['chrome-linux64/chrome','chrome-linux/chrome'])candidates.push(join(root,entry,file));const found=candidates.find(p=>p&&existsSync(p));if(!found)throw new Error('Define CHROME_BIN con la ruta a Chrome.');return found;}
async function http(url){for(let i=0;i<300;i++){try{const r=await fetch(url);if(r.ok)return;}catch{}await delay(100);}throw new Error('No responde '+url);}
export async function withBrowser(action,{appDir=resolve(HERE,'..'),gpu=true,visible=false,cpu=1,edgeMode='auto',autoload=true}={}) {
  const webPort=await port(),debugPort=await port(),profile=mkdtempSync('/tmp/erd-perf-'),binary=chromePath();
  const server=spawn('python3',['-m','http.server',String(webPort),'--bind','127.0.0.1'],{cwd:appDir,stdio:'ignore'});
  const chrome=spawn(binary,[...(visible?[]:['--headless=new']),'--no-sandbox',...(!gpu?['--disable-gpu']:[]),'--disable-dev-shm-usage','--window-size=1400,900',`--remote-debugging-port=${debugPort}`,`--user-data-dir=${profile}`,'about:blank'],{stdio:['ignore','ignore','pipe'],detached:true});
  let chromeError='';chrome.stderr.on('data',chunk=>{chromeError=(chromeError+chunk.toString()).slice(-4000);});
  let ws;
  try{
    await Promise.all([http(`http://127.0.0.1:${webPort}/`),http(`http://127.0.0.1:${debugPort}/json/version`).catch(error=>{throw new Error(error.message+' (Chrome exit='+chrome.exitCode+') '+chromeError);})]);
    const targets=await fetch(`http://127.0.0.1:${debugPort}/json`).then(r=>r.json());ws=new WebSocket(targets.find(t=>t.type==='page').webSocketDebuggerUrl);await new Promise((resolve,reject)=>{ws.onopen=resolve;ws.onerror=reject;});const cdp=new Cdp(ws);
    await cdp.send('Runtime.enable');await cdp.send('Page.enable');await cdp.send('Performance.enable');await cdp.send('Emulation.setDeviceMetricsOverride',{width:1400,height:900,deviceScaleFactor:1,mobile:false});if(cpu!==1)await cdp.send('Emulation.setCPUThrottlingRate',{rate:cpu});
    const appUrl = `http://127.0.0.1:${webPort}/${autoload ? `?autoload=1&performance=1&edges=${edgeMode}` : ''}`;
    await cdp.send('Page.navigate',{url:appUrl});
    if(autoload){
      for(let i=0;i<300;i++){try{if(await cdp.evaluate('!!window.__erdApp && !__erdApp.getStatus().busy && __erdApp.getStatus().tables===150',false))break;}catch{}await delay(100);if(i===299)throw new Error('No se cargó el ejemplo de 150 tablas.');}
    }else{
      for(let i=0;i<300;i++){try{if(await cdp.evaluate('!!window.__erdApp && !__erdApp.getStatus().busy',false))break;}catch{}await delay(100);if(i===299)throw new Error('No se inició la app.');}
      await cdp.evaluate('__erdApp.ready');
    }
    await cdp.evaluate('__erdApp.ready');
    let gpuReport;
    try{const version=await fetch(`http://127.0.0.1:${debugPort}/json/version`).then(r=>r.json());const browserWs=new WebSocket(version.webSocketDebuggerUrl);await new Promise(resolve=>browserWs.onopen=resolve);const browserCdp=new Cdp(browserWs);const info=await browserCdp.send('SystemInfo.getInfo');gpuReport={devices:info.gpu.devices.map(d=>({vendor:d.vendorString,device:d.deviceString})),renderer:info.gpu.auxAttributes?.glRenderer,featureStatus:info.gpu.featureStatus};browserWs.close();}catch{gpuReport={unavailable:true};}
    return await action(cdp,{binary,gpuRequested:gpu,gpuReport,headless:!visible,cpu});
  }finally{ws?.close();try{process.kill(-chrome.pid,'SIGTERM');}catch{chrome.kill('SIGTERM');}server.kill('SIGTERM');await delay(200);rmSync(profile,{recursive:true,force:true,maxRetries:10,retryDelay:100});}
}
