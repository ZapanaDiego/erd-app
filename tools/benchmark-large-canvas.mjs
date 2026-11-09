import {withBrowser} from './browser-harness.mjs';
import {writeFileSync} from 'node:fs';
const report=await withBrowser(async(cdp,environment)=>{
  const results=[];
  for(const size of [1000,5000]){
    const data=await cdp.evaluate(`(async()=>{
      const size=${size},c={tableEntities:{},tableColumnEntities:{},relationshipEntities:{}};
      for(let i=0;i<size;i++){
        const id='t'+i,columnIds=[];
        for(const[name,type,options]of [['id','INT',10],['tenant_id','INT',8],...Array.from({length:5},(_,j)=>['parent_'+j,'INT',0]),['description','VARCHAR(100)',0]]){const cid=id+name;columnIds.push(cid);c.tableColumnEntities[cid]={id:cid,name,dataType:type,options};}
        c.tableEntities[id]={id,name:'area'+(i%20)+'_table'+i,columnIds};
        for(let j=1;j<=5;j++){const parent='t'+((i+j)%size),rid=id+'r'+j,composite=j%2===0;c.relationshipEntities[rid]={id:rid,start:{tableId:parent,columnIds:composite?[parent+'tenant_id',parent+'id']:[parent+'id']},end:{tableId:id,columnIds:composite?[id+'tenant_id',id+'parent_'+(j-1)]:[id+'parent_'+(j-1)]}};}
      }
      const a=analysis,source=__erdApp.editor.value,t=performance.now();await a.loadDocument({collections:c});const indexedMs=performance.now()-t;
      const mapNodes=a.projection.nodes.length;
      await a.requestFocus('area0_table0',1,{cross:true});const focusNodes=a.projection.nodes.length;
      const stats={...a.renderer.stats},times=[];
      for(let i=0;i<60;i++){await new Promise(requestAnimationFrame);const start=performance.now();a.viewport.dispatchEvent(new WheelEvent('wheel',{deltaX:i<30?1:-1,cancelable:true,bubbles:true}));times.push(performance.now()-start);}
      await a.renderer.ready();
      const panCards=a.renderer.stats.cardsCreated-stats.cardsCreated;
      await a.navigate('module',{group:'area0',links:'context',selected:''});const moduleNodes=a.projection.nodes.length;
      await a.navigate('map',{selected:'',links:'selection'});await a.requestFocus('area0_table0',1,{cross:true});await a.navigate('module',{group:'area0',links:'context',selected:''});
      return {tables:a.graph.tables.length,relations:a.graph.relations.length,indexAndInitialUiMs:+indexedMs.toFixed(1),mapNodes,focusNodes,moduleNodes,panHandlerP95Ms:times.sort((x,y)=>x-y)[57],cardsCreatedDuringPan:panCards,sourceUnchanged:source===__erdApp.editor.value};
    })()`);
    // Memoria de laboratorio tras estabilizar las mismas vistas, sin crear nuevas vistas de usuario.
    await cdp.send('HeapProfiler.collectGarbage');const before=await cdp.send('Runtime.getHeapUsage');
    await cdp.evaluate(`(async()=>{for(let i=0;i<20;i++){await analysis.navigate('map',{selected:'',links:'selection'});await analysis.requestFocus('area0_table0',1,{cross:true});await analysis.navigate('module',{group:'area0',links:'context',selected:''});}})()`);
    await cdp.send('HeapProfiler.collectGarbage');const after=await cdp.send('Runtime.getHeapUsage');
    data.heapBeforeBytes=before.usedSize;data.heapAfterBytes=after.usedSize;data.heapGrowthPercent=+((after.usedSize/before.usedSize-1)*100).toFixed(2);results.push(data);
  }
  const errors=cdp.events.filter(e=>e.method==='Runtime.exceptionThrown').map(e=>e.params.exceptionDetails.exception?.description||e.params.exceptionDetails.text);
  return {environment,results,errors,scope:'Modelo sintético con 8 columnas por tabla, 5 FK por tabla, incluidas compuestas; mapa, enfoque y módulo. No mide layout global de 5000 tablas ni compatibilidad del importador SQL.'};
},{appDir:process.cwd()});
const output=process.argv.find(v=>v.startsWith('--output='))?.slice(9);if(output)writeFileSync(output,JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));if(report.errors.length||report.results.some(r=>!r.sourceUnchanged||r.focusNodes!==11||r.mapNodes!==20))process.exitCode=1;
