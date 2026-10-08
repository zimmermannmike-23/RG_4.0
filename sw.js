// RebalGold · Service Worker (v3.63)
// Offline-Fallback: Die App-Datei wird bei jedem Online-Aufruf frisch geladen (Netz zuerst) und
// nebenbei gespeichert. Ohne Netz liefert der Cache die zuletzt geladene Fassung.
// Kursabrufe, Cloud-Sync und version.json gehen immer direkt ans Netz und werden nie gecacht.
const CACHE='rebalgold-v3.63';
self.addEventListener('install',e=>{
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then(c=>c.addAll(['./']).catch(()=>{})));
});
self.addEventListener('activate',e=>{
  e.waitUntil(caches.keys()
    .then(ks=>Promise.all(ks.filter(k=>k.startsWith('rebalgold-')&&k!==CACHE).map(k=>caches.delete(k))))
    .then(()=>self.clients.claim()));
});
self.addEventListener('fetch',e=>{
  const r=e.request;
  if(r.method!=='GET')return;
  const u=new URL(r.url);
  // Schriften: einmal laden, dann aus dem Cache
  if(/fonts\.(googleapis|gstatic)\.com$/.test(u.hostname)){
    e.respondWith(caches.open(CACHE).then(async c=>{
      const m=await c.match(r);if(m)return m;
      const res=await fetch(r);if(res.ok||res.type==='opaque')c.put(r,res.clone());return res;
    }));
    return;
  }
  if(u.origin!==self.location.origin)return;          // Kurse, Firebase: unveraendert durchreichen
  if(u.pathname.endsWith('version.json'))return;       // Update-Pruefung immer live
  e.respondWith(
    fetch(r).then(res=>{
      if(res.ok){const kopie=res.clone();caches.open(CACHE).then(c=>c.put(r,kopie));}
      return res;
    }).catch(()=>caches.match(r,{ignoreSearch:true}).then(m=>m||caches.match('./')))
  );
});
