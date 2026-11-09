/* Cámara y layouts separados: navegar no vuelve a clonar todos los trazados. */
window.AnalysisStorage = (() => {
  let opening;
  function database() {
    opening ||= new Promise((resolve,reject)=>{
      const request=indexedDB.open('erd-app-workspace',2);
      request.onupgradeneeded=()=>{for(const name of ['entries','layouts'])if(!request.result.objectStoreNames.contains(name))request.result.createObjectStore(name);};
      request.onsuccess=()=>{request.result.onversionchange=()=>{request.result.close();opening=null;};resolve(request.result);};request.onerror=()=>{opening=null;reject(request.error);};request.onblocked=()=>{opening=null;reject(new Error('Cierra otras pestañas para actualizar el almacenamiento.'));};
    });return opening;
  }
  function read(db,store,key) {return new Promise((resolve,reject)=>{const r=db.transaction(store).objectStore(store).get(key);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});}
  async function get(key) {
    const db=await database(),value=await read(db,'entries',key);
    if(!value?.layoutRefs)return value;
    const fingerprint=value.fingerprint;
    const state=await read(db,'entries','analysis-state:'+fingerprint);
    if(state)value.state=state;
    value.layouts={};
    // Una transacción para todos los layouts de esta vista, incluso en restauraciones grandes.
    await new Promise((resolve,reject)=>{const tx=db.transaction('layouts'),store=tx.objectStore('layouts');for(const k of value.layoutRefs){const r=store.get(fingerprint+'\0'+k);r.onsuccess=()=>{if(r.result)value.layouts[k]=r.result;};}tx.oncomplete=resolve;tx.onerror=()=>reject(tx.error);});
    delete value.layoutRefs;return value;
  }
  async function set(key,value) {const db=await database();return new Promise((resolve,reject)=>{const tx=db.transaction('entries','readwrite');tx.objectStore('entries').put(value,key);tx.oncomplete=resolve;tx.onerror=()=>reject(tx.error);tx.onabort=()=>reject(tx.error||new Error('Guardado cancelado.'));});}
  async function saveAnalysis(metadata,layouts,cameraOnly=false) {
    const db=await database(),fp=metadata.fingerprint;
    return new Promise((resolve,reject)=>{
      const tx=db.transaction(cameraOnly?['entries']:['entries','layouts'],'readwrite'),entries=tx.objectStore('entries');
      entries.put(metadata.state,'analysis-state:'+fp);
      if(!cameraOnly){
        const store=tx.objectStore('layouts'),previous=entries.get('analysis:'+fp);
        previous.onsuccess=()=>{const retained=new Set(metadata.layoutRefs);for(const key of previous.result?.layoutRefs||[])if(!retained.has(key))store.delete(fp+'\0'+key);};
        for(const[key,value]of Object.entries(layouts))store.put(value,fp+'\0'+key);
        entries.put(metadata,'analysis:'+fp);
      }
      tx.oncomplete=resolve;tx.onerror=()=>reject(tx.error);tx.onabort=()=>reject(tx.error||new Error('Guardado cancelado.'));
    });
  }
  return {get,set,saveAnalysis};
})();
