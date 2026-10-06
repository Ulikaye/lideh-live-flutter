/* Firebase connection + live data. Collections: prices, regions, places, pests, news (public read, admin write). */
window.fbReady=(async()=>{
 if(!FIREBASE_CONFIG.enabled)return null;
 const b='https://www.gstatic.com/firebasejs/10.12.2/',ld=u=>new Promise((ok,no)=>{const s=document.createElement('script');s.src=u;s.onload=ok;s.onerror=no;document.head.appendChild(s)});
 try{await ld(b+'firebase-app-compat.js');await ld(b+'firebase-firestore-compat.js');const{enabled,...cfg}=FIREBASE_CONFIG;firebase.initializeApp(cfg);return firebase.firestore()}catch(e){console.warn('Firebase failed',e);return null}
})();
(async()=>{
 const db=await fbReady;if(!db)return;
 const get=c=>db.collection(c).get().then(s=>s.docs.map(d=>({id:d.id,...d.data()})));
 try{const[pr,rg,pl,pe,nw]=await Promise.all(['prices','regions','places','pests','news'].map(get));
  const put=(arr,rows)=>{if(rows.length){arr.length=0;arr.push(...rows)}};
  if(pr.length){Object.keys(CROPS).forEach(k=>delete CROPS[k]);for(const p of pr){CROPS[p.crop]=1;PRICES[p.crop+'|'+p.region]=Object.keys(p.history||{}).sort().slice(-6).map(m=>p.history[m])}}
  if(rg.length){Object.keys(REG).forEach(k=>delete REG[k]);rg.sort((a,b)=>b.ha-a.ha).forEach(r=>REG[r.name]=1)}
  put(RG,rg.map(r=>[r.name,+r.lon,+r.lat,+r.farms,+r.ha,r.crops||[]]));
  put(POI,pl.map(p=>[p.name,p.type,+p.lon,+p.lat,p.region,p.desc,p.size]));
  put(PESTS,pe.map(p=>[p.name,p.type,p.affects,p.symptoms,p.treatment,p.prevention]));
  put(NEWS,nw.sort((a,b)=>(b.date||'').localeCompare(a.date||'')).map(n=>[n.title,n.body,n.cat]));
  rebuildAll();$('#fbs').textContent='';
 }catch(e){console.warn('Load failed. Showing demo data.',e);$('#fbs').textContent='Could not load live data. Showing saved demo data.'}
})();
