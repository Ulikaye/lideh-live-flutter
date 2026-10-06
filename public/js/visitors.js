/* Public visitor counter. Counts one visit per device per day in Firestore: stats/{YYYY-MM-DD}.visitors
   Needs FIREBASE_CONFIG (js/app.js) enabled + the rules in firestore.rules. Without it, preview numbers are shown. */
(function(){
const key=t=>new Intl.DateTimeFormat('en-CA',{timeZone:'Africa/Dar_es_Salaam'}).format(t);
const days=[...Array(7)].map((_,i)=>key(new Date(Date.now()-i*864e5)));
const load=u=>new Promise((ok,no)=>{const s=document.createElement('script');s.src=u;s.onload=ok;s.onerror=no;document.head.appendChild(s)});
async function counts(){
 if(!FIREBASE_CONFIG.enabled)return{c:[142,168,131,190,155,121,174],live:false};
 const db=await fbReady;if(!db)return{c:[0,0,0,0,0,0,0],live:false};
 try{if(localStorage.getItem('lh_seen')!==days[0]){await db.doc('stats/'+days[0]).set({visitors:firebase.firestore.FieldValue.increment(1)},{merge:true});localStorage.setItem('lh_seen',days[0])}}catch(e){}
 return{c:await Promise.all(days.map(d=>db.doc('stats/'+d).get().then(s=>s.exists?s.data().visitors:0))),live:true};
}
function up(el,n){const t0=performance.now();(function f(t){const k=Math.min(1,(t-t0)/900);el.textContent=Math.round(n*(1-Math.pow(1-k,3))).toLocaleString();if(k<1)requestAnimationFrame(f)})(t0)}
counts().catch(()=>({c:[0,0,0,0,0,0,0],live:false,err:true})).then(({c,live,err})=>{
 const mx=Math.max(...c,1),wk=c.reduce((a,b)=>a+b,0),wd=days.map(d=>'SMTWTFS'[new Date(d+'T12:00:00').getDay()]);
 document.querySelectorAll('[data-vis]').forEach(el=>{
  el.innerHTML=`<h4>People using LideH Live</h4><div class="vn"><div><b data-n="${c[0]}">0</b><span>today</span></div><div><b data-n="${wk}">0</b><span>last 7 days</span></div></div>
  <div class="vb">${[...c].reverse().map((v,i)=>`<i style="--h:${Math.max(6,v/mx*100)}%;--d:${i*70}ms" title="${v}"><em>${[...wd].reverse()[i]}</em></i>`).join('')}</div>
  <small>${err?'Counter unavailable right now.':live?'Unique devices per day, counted in Tanzania time.':'Preview numbers. Live counting starts when Firebase is connected.'}</small>`;
  el.querySelectorAll('[data-n]').forEach(n=>up(n,+n.dataset.n))})});
})();
