/* Removes the old Flutter app's service worker and caches from visitors' browsers.
   The old site registered /flutter_service_worker.js. This file replaces it, clears everything, and unregisters itself.
   Safe to delete a few months after launch. */
self.addEventListener('install',()=>self.skipWaiting());
self.addEventListener('activate',e=>e.waitUntil((async()=>{
  for(const k of await caches.keys())await caches.delete(k);
  await self.registration.unregister();
  for(const c of await self.clients.matchAll({type:'window'}))c.navigate(c.url);
})()));
