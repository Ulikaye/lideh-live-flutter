/* LideH Live application logic.
   All interface icons are local SVG files under ../assets/icons.
   The icon names below intentionally match the filenames requested for this build.
*/

const FarmDB={async prices(){return null},async pests(){return null},async news(){return null},async saveAlert(a){return false}}; // replace with Firestore calls
/* ================================================= */
const $=s=>document.querySelector(s);
const ICON_FILES={
  home:'home-fill.svg', prices:'price-fill.svg', tag:'price-fill.svg', leaf:'plant-fill.svg', plant:'plant-fill.svg',
  cloud:'weather-fill.svg', weather:'weather-fill.svg', chat:'advisor-fill.svg', advisor:'advisor-fill.svg',
  news:'news-fill.svg', tracker:'tracker-fill.svg', chk:'tracker-fill.svg', send:'send-fill.svg',
  sun:'weather-fill.svg', rain:'weather-fill.svg', up:'success-fill.svg', dn:'warning-fill.svg',
  bell:'notification-fill.svg', notification:'notification-fill.svg', pin:'map-fill.svg', map:'map-fill.svg',
  store:'store-fill.svg', bldg:'building-fill.svg', bask:'shop-bask.svg',
  moon:'moon-fill.svg', success:'success-fill.svg', favorite:'favorite-fill.svg', warning:'warning-fill.svg',
  add:'add-fill.svg', close:'close-fill.svg', back:'back-fill.svg', menu:'menu-fill.svg',
  setting:'setting-fill.svg', virus:'virus-fill.svg', search:'search-fill.svg', edit:'et-fill.svg',
  facebook:'facebook-fill.svg', instagram:'instagram-fill.svg', x:'x-fill.svg'
};
const iconPath=n=>{const f=ICON_FILES[n]||ICON_FILES.home;return (window.ICON_DATA&&ICON_DATA[f])||new URL('assets/icons/'+f,document.baseURI).href};
const ic=n=>`<span class="i" style="--icon-url:url('${iconPath(n)}')" aria-hidden="true"></span>`;
const CROPS={Maize:900,Rice:2400,Tomatoes:1500,Cassava:600,Coffee:4800,Cotton:1300,Beans:2600,Sorghum:1100};
const REG={'Dar es Salaam':1.12,Arusha:1.02,Mbeya:.9,Morogoro:.95,Mwanza:1,Dodoma:.97};
const mo=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const PRICES={};
const hist=(c,r)=>{if(FIREBASE_CONFIG.enabled)return PRICES[c+'|'+r]||null;let b=CROPS[c]*REG[r],k=[...c].reduce((a,x)=>a+x.charCodeAt(0),0);return[...Array(6)].map((_,i)=>Math.round(b*(1+.12*Math.sin(k+i*1.1)+(i-3)*.01)/10)*10)};
const predict=h=>{const a=h.reduce((x,y)=>x+y)/h.length,l=h.at(-1),cr=(l-a)/a;return{t:cr>0?'rising':cr<0?'falling':'stable',cr,p:[1,2,3].map(m=>Math.round(l*(1+cr*.3*m)/10)*10)}};
const PESTS=[
['Fall Armyworm','pest','Maize, Sorghum, Rice','Ragged holes in leaves, sawdust-like droppings, larvae in the whorl.','Emamectin benzoate 5% SG at 0.5 g/L. Spray early morning or late evening, repeat after 14 days.','Plant early, rotate crops, scout weekly, destroy residues.'],
['Maize Lethal Necrosis','disease','Maize','Yellowing and dead leaf edges, stunting, poor grain fill.','No cure. Uproot and destroy infected plants, control thrips.','Use tolerant varieties, avoid planting next to infected fields.'],
['Tomato Leaf Miner','pest','Tomatoes, Potatoes','Mining tunnels in leaves, bored fruit, leaf curl.','Abamectin 1.8% EC or Indoxacarb 14.5% SC. Use pheromone traps.','Net houses, sanitation, parasitoid control.'],
['Rice Blast','disease','Rice','Diamond-shaped lesions on leaves, broken panicle necks.','Fungicide such as Tricyclazole. Drain excess water.','Resistant varieties, balanced nitrogen, clean seed.'],
['Cassava Brown Streak','disease','Cassava','Brown streaks on stems, corky root rot.','No cure. Remove infected plants.','Clean planting material, resistant varieties.'],
['Coffee Berry Borer','pest','Coffee','Small holes in berries, premature berry drop.','Strip and destroy leftover berries, apply recommended insecticide.','Timely harvest, field sanitation.'],
['Aphids','pest','Beans, Vegetables','Curled leaves, sticky honeydew, stunted shoots.','Neem extract or approved insecticidal soap.','Encourage ladybirds, remove weeds.'],
['Cotton Bollworm','pest','Cotton','Holes in bolls, damaged squares, caterpillars inside.','Spray recommended pyrethroid at first egg lay.','Scout early, rotate with cereals.']];
const NEWS=[['Maize prices firm ahead of the long rains','Traders in the Southern Highlands report tight stock. Farmers holding grain may see better offers in coming weeks.','Market'],['Fall armyworm: scout your field this week','Early detection cuts spray costs. Check the whorl of young maize in the morning.','Alert'],['Store beans dry to avoid losses','Moisture above 13% invites mould and weevils. Sun-dry and use airtight bags.','Tip']];
const STEPS=['Land preparation','Soil test','Buy certified seed','Planting','First weeding','Fertilizer application','Pest scouting','Harvest','Drying and storage','Sell at best price'];
const FEATS=[['prices','tag','Market prices','Live prices by region'],['map','pin','Farm map','Crops by region'],['health','leaf','Pests and diseases','Spot, treat, prevent'],['weather','cloud','Weather','Forecast and spray window'],['advisor','chat','Farm advisor','Ask in plain words'],['tracker','chk','Progress tracker','Follow your season'],['news','news','News and tips','Market and farm updates']];
const KB=[[['armyworm','holes','worm'],'Sounds like fall armyworm. Scout the whorl, and spray emamectin benzoate early morning or evening.'],[['yellow','necrosis','stunted'],'Yellowing with stunting can be maize lethal necrosis or nutrient shortage. Check for thrips and send a sample to your extension officer.'],[['tomato','tuta','tunnel'],'Mining tunnels point to Tuta absoluta. Use pheromone traps and spray abamectin or indoxacarb.'],[['price','sell','market'],'Open the Prices tab: when the latest price is above its average, the outlook is rising and holding stock briefly may pay.'],[['plant','sowing','season'],'Plant with the first steady rains. Use certified seed and rows spaced for your crop.'],[['fertilizer','urea','npk'],'Use basal fertilizer at planting and top-dress 3 to 4 weeks later. A soil test tells you exact rates.'],[['water','irrigate','dry'],'Water early morning, and mulch to hold moisture. Critical stages are flowering and grain fill.'],[['rain','spray'],'Avoid spraying if rain is expected within 6 hours. Check the Weather tab for the spray window.']];
const NAV=[['home','Home','home'],['prices','Prices','tag'],['health','Health','leaf'],['map','Map','pin'],['advisor','Advisor','chat']];
const store={get(k,d){try{return JSON.parse(localStorage.getItem(k))??d}catch(e){return d}},set(k,v){try{localStorage.setItem(k,JSON.stringify(v))}catch(e){}}};
let crop='Maize';

$('#tabs').innerHTML=NAV.map(n=>`<a class="tab" href="#${n[0]}" data-v="${n[0]}">${ic(n[2])}${n[1]}</a>`).join('');
$('#dn').innerHTML=[...NAV,['weather','Weather'],['tracker','Tracker'],['news','News']].map(n=>`<a href="#${n[0]}" data-v="${n[0]}">${n[1]}</a>`).join('');
$('#feats').innerHTML=FEATS.map(f=>`<a class="card feat" href="#${f[0]}"><span class="ic">${ic(f[1])}</span><span><b>${f[2]}</b><small>${f[3]}</small></span></a>`).join('');
const newsHTML=a=>a.map(n=>`<article class="card"><span class="tag note">${n[2]}</span><h3 style="font-size:19px;margin:10px 0 6px">${n[0]}</h3><p class="mut">${n[1]}</p></article>`).join('');
$('#homenews').innerHTML=newsHTML(NEWS.slice(0,2));$('#nlist').innerHTML=newsHTML(NEWS);
function ticker(){$('#tick').innerHTML=[0,1].map(()=>Object.keys(CROPS).map(c=>{const h=hist(c,Object.keys(REG)[0]);if(!h||h.length<2)return'';const d=(h.at(-1)/h.at(-2)-1)*100;return`<span>${c} ${h.at(-1).toLocaleString()} <i class="${d>=0?'up':'dw'}">${d>=0?'+':''}${d.toFixed(1)}%</i></span>`}).join('')).join('');}ticker();

function route(){const v=(location.hash.slice(1)||'home');document.querySelectorAll('.view').forEach(e=>e.classList.toggle('on',e.id===v));
 document.querySelectorAll('[data-v]').forEach(e=>e.classList.toggle('on',e.dataset.v===v));scrollTo({top:0});if(v==='prices')prices();if(v==='map')map()}
addEventListener('hashchange',route);

/* prices */
$('#crops').innerHTML=Object.keys(CROPS).map(c=>`<button class="chip" data-c="${c}">${c}</button>`).join('');
$('#reg').innerHTML=Object.keys(REG).map(r=>`<option>${r}</option>`).join('');
$('#crops').onclick=e=>{if(e.target.dataset.c){crop=e.target.dataset.c;prices()}};$('#reg').onchange=prices;
function prices(){const r=$('#reg').value,h=hist(crop,r);if(!h||h.length<2){$('#pcard').innerHTML=`<div class="card"><b>No price yet</b><p class="mut">${crop} in ${r} has not been entered. Try another region.</p></div>`;return}const P=predict(h),l=h.at(-1),d=(l/h.at(-2)-1)*100;
 document.querySelectorAll('#crops .chip').forEach(c=>c.classList.toggle('on',c.dataset.c===crop));
 const all=[...h,...P.p],mx=Math.max(...all)*1.05,mn=Math.min(...all)*.95,X=i=>20+i*(300/8),Y=v=>110-(v-mn)/(mx-mn)*95;
 const pts=a=>a.map((v,i)=>`${X(i)},${Y(v)}`),pr=[h.at(-1),...P.p].map((v,i)=>`${X(i+5)},${Y(v)}`);
 const now=new Date().getMonth(),lab=i=>mo[(now-5+i+12)%12];
 $('#pcard').innerHTML=`<div class="card"><span class="mut">${crop} in ${r}</span><div class="price" id="pv">0<small> TZS/kg</small></div>
 <span class="badge ${d>=0?'up':'dw'}">${ic(d>=0?'up':'dn')}${d>=0?'+':''}${d.toFixed(1)}% vs last month</span>
 <svg class="chart" viewBox="0 0 340 135" style="margin-top:14px"><polyline class="ln" fill="none" stroke="var(--teal)" stroke-width="3" stroke-linecap="round" points="${pts(h).join(' ')}"/><polyline class="ln" fill="none" stroke="var(--sun)" stroke-width="3" stroke-dasharray="2 7" stroke-linecap="round" points="${pr.join(' ')}"/>${all.map((_,i)=>i%2?'':`<text x="${X(i)}" y="130" font-size="9" fill="var(--mut)" text-anchor="middle">${lab(i)}</text>`).join('')}</svg>
 <p class="mut" style="font-size:13px">Solid: past 6 months. Dotted: 3-month outlook.</p></div>
 <div class="card"><h3 style="font-size:20px">Outlook: <span class="${P.t==='rising'?'up':P.t==='falling'?'dw':''}">${P.t}</span></h3>
 <p class="mut" style="margin-top:6px">${P.t==='rising'?'Price sits above its 6-month average. Holding stock a little longer may pay if you can store safely.':P.t==='falling'?'Price sits below its average. Consider selling part of the stock now and reviewing weekly.':'Price is steady. Sell as needed.'} (${(Math.abs(P.cr)*100).toFixed(1)}% from average)</p>
 <div class="pm">${P.p.map((v,i)=>`<div><span class="mut">${mo[(now+i+1)%12]}</span><b>${v.toLocaleString()}</b></div>`).join('')}</div>
 <p class="mut" style="font-size:12px;margin-top:12px">Demo data and a simple trend model. Connect Firebase to use real market records.</p></div>`;
 const el=$('#pv'),t0=performance.now();(function f(t){const k=Math.min(1,(t-t0)/700);el.firstChild.nodeValue=Math.round(l*(1-Math.pow(1-k,3))).toLocaleString();if(k<1)requestAnimationFrame(f)})(t0)}
$('#al').onclick=()=>{const v=+$('#tgt').value;if(!v)return;const a=store.get('alerts',[]);a.push({crop,v});store.set('alerts',a);FarmDB.saveAlert({crop,v});$('#alm').textContent=`Alert saved: ${crop} at ${v.toLocaleString()} TZS/kg.`;$('#tgt').value=''}

/* health */
let hf='all';$('#hf').innerHTML=['all','pest','disease'].map(t=>`<button class="chip" data-t="${t}">${t==='all'?'All':t==='pest'?'Pests':'Diseases'}</button>`).join('');
$('#hf').onclick=e=>{if(e.target.dataset.t){hf=e.target.dataset.t;health()}};
function health(){document.querySelectorAll('#hf .chip').forEach(c=>c.classList.toggle('on',c.dataset.t===hf));
 $('#plist').innerHTML=PESTS.filter(p=>hf==='all'||p[1]===hf).map(p=>`<article class="card pest" onclick="this.classList.toggle('open')"><span class="tag ${p[1]}">${p[1]}</span><h3 style="font-size:20px">${p[0]}</h3><span class="mut">Affects: ${p[2]}</span><div class="more"><div><dl><dt>Symptoms</dt><dd>${p[3]}</dd><dt>Treatment</dt><dd>${p[4]}</dd><dt>Prevention</dt><dd>${p[5]}</dd></dl></div></div></article>`).join('')}

/* weather (demo forecast) */
$('#wr').innerHTML=Object.keys(REG).map(r=>`<option>${r}</option>`).join('');$('#wr').onchange=wx;
function wx(){const r=$('#wr').value,k=[...r].reduce((a,x)=>a+x.charCodeAt(0),0),d=['Today','Tue','Wed','Thu','Fri','Sat'];
 const D=d.map((n,i)=>({n,t:24+(k+i*3)%9,rain:(k*7+i*23)%100}));const ok=D[0].rain<40;
 $('#wnow').innerHTML=`<div style="display:flex;gap:14px;align-items:center"><span class="ic">${ic(ok?'sun':'rain')}</span><div><h3 style="font-size:30px">${D[0].t}°C</h3><span class="mut">${D[0].rain}% chance of rain, ${r}</span></div></div><p style="margin-top:12px"><span class="badge ${ok?'up':'dw'}">${ok?'Good time to spray':'Hold spraying'}</span> <span class="mut">${ok?'Low rain risk. Spray early morning.':'Rain may wash chemicals off.'}</span></p>`;
 $('#fc').innerHTML=D.map(x=>`<div class="card"><b>${x.n}</b>${ic(x.rain>50?'rain':'sun')}<div>${x.t}°</div><small class="mut">${x.rain}%</small></div>`).join('')}

/* advisor */
const add=(t,c)=>{$('#msgs').insertAdjacentHTML('beforeend',`<div class="bub ${c}"></div>`);$('#msgs').lastChild.textContent=t};
add('Hello! Describe what you see in your field or ask about prices, planting and fertilizer.','ai');
function ask(){const q=$('#q').value.trim();if(!q)return;add(q,'me');$('#q').value='';const m=KB.find(k=>k[0].some(w=>q.toLowerCase().includes(w)));setTimeout(()=>add(m?m[1]:'I am not sure yet. Try words like armyworm, price, fertilizer or irrigation, or contact your extension officer.','ai'),500)}
$('#s').onclick=ask;$('#q').onkeydown=e=>e.key==='Enter'&&ask();

/* tracker */
function track(){const d=store.get('steps',[]);$('#steps').innerHTML=STEPS.map((s,i)=>`<label class="ck"><input type="checkbox" data-i="${i}" ${d.includes(i)?'checked':''}>${s}</label>`).join('');
 $('#pct').textContent=`${d.length} of ${STEPS.length} steps done`;$('#pb').style.width=d.length/STEPS.length*100+'%'}
$('#steps').onchange=e=>{let d=store.get('steps',[]).filter(x=>x!==+e.target.dataset.i);if(e.target.checked)d.push(+e.target.dataset.i);store.set('steps',d);track()};

$('#th').onclick=()=>{const r=document.documentElement,dk=getComputedStyle(r).getPropertyValue('--bg').trim()==='#071A1B';r.dataset.theme=dk?'light':'dark'};
$('#fbs').textContent=FIREBASE_CONFIG.enabled?'Backend: Firebase connected':'Backend: demo data. Add your Firebase config at the top of the script.';

/* map */
const OUT=[[30.5,-1.1],[33.9,-1],[34.5,-1.1],[35.8,-2.5],[36.8,-3],[37.7,-3.1],[37.7,-3.4],[38,-3.7],[38.6,-4.2],[39.2,-4.7],[38.9,-5.8],[39.3,-6.9],[39.5,-7.9],[39.4,-8.9],[39.6,-10],[40.4,-10.5],[38.5,-11.3],[37,-11.6],[35.8,-11.5],[34.6,-11.5],[34.5,-10],[33.9,-9.5],[33.3,-9.4],[32.9,-9.2],[31,-8.6],[30.5,-7],[30,-6],[29.6,-4.8],[30.3,-3.6],[30.8,-2.4]];
const RG=[['Arusha',36.7,-3.4,3200,41000,['Maize','Beans','Coffee','Tomatoes']],['Kilimanjaro',37.4,-3.35,2900,28000,['Coffee','Maize','Beans']],['Mbeya',33.5,-8.9,5100,96000,['Maize','Rice','Coffee','Beans']],['Iringa',35.7,-7.8,2600,52000,['Maize','Tomatoes','Beans']],['Morogoro',37.6,-6.8,4300,88000,['Rice','Maize','Sorghum']],['Dar es Salaam',39.2,-6.8,1500,6000,['Tomatoes','Cassava']],['Dodoma',35.8,-6.2,2200,47000,['Sorghum','Maize']],['Mwanza',32.9,-2.5,3800,63000,['Cotton','Rice','Cassava']],['Kagera',31.5,-1.9,3300,58000,['Coffee','Beans','Cassava']],['Kigoma',29.9,-4.9,1700,31000,['Cassava','Coffee']],['Tabora',32.8,-5,2900,72000,['Cotton','Maize','Rice']],['Singida',34.7,-4.8,1900,39000,['Sorghum','Maize']],['Shinyanga',33.4,-3.7,2400,55000,['Cotton','Rice']],['Tanga',38.6,-5.1,2100,34000,['Cassava','Maize']],['Mtwara',39.6,-10.5,1300,22000,['Cassava','Sorghum']],['Ruvuma',35.6,-10.5,3000,68000,['Maize','Coffee','Beans']],['Manyara',36.2,-4.2,2000,44000,['Maize','Beans','Sorghum']],['Katavi',31.2,-6.4,900,26000,['Rice','Maize']]];
let mc='All',ms='Mbeya';const PX=o=>[(o[0]-29.3)*34,(-o[1]-.9)*34];
$('#mc').innerHTML=['All',...Object.keys(CROPS)].map(c=>`<button class="chip" data-m="${c}">${c}</button>`).join('');
$('#mc').onclick=e=>{if(e.target.dataset.m){mc=e.target.dataset.m;map()}};
const LY=[['crops','Crops','leaf','#F4A62A'],['market','Markets','bask','#E8743B'],['shop','Shops','store','#2F73D1'],['office','Offices','bldg','#07403F']];
const POI=[['Kariakoo Market','market',39.27,-6.82,'Dar es Salaam','Largest trading hub for grains, vegetables and fruit.','Large'],['Kibaigwa Grain Market','market',36.58,-6.4,'Dodoma','Well-known maize and sunflower trading market.','Large'],['Mwanjelwa Market','market',33.45,-8.92,'Mbeya','Main produce market for the Southern Highlands.','Large'],['Buzuruga Market','market',32.93,-2.53,'Mwanza','Lake zone market for rice, cassava and vegetables.','Medium'],['Soko Kuu','market',36.68,-3.37,'Arusha','Central market for vegetables and cereals.','Medium'],['Mbuyuni Market','market',37.34,-3.35,'Kilimanjaro','Busy produce market in Moshi.','Medium'],['Mawenzi Market','market',37.66,-6.82,'Morogoro','Rice, maize and vegetables from the valleys.','Medium'],['Iringa Main Market','market',35.69,-7.77,'Iringa','Tomatoes, maize and potatoes.','Small'],
['Agro-input wholesalers','shop',39.22,-6.78,'Dar es Salaam','Fertilizer, seed, pesticides and tools. Sample listing.','Large'],['Agro-vet dealers','shop',36.72,-3.4,'Arusha','Inputs, veterinary and farm tools. Sample listing.','Medium'],['Fertilizer and seed dealers','shop',33.5,-8.88,'Mbeya','Highlands input shops. Sample listing.','Large'],['Tools and irrigation shops','shop',37.62,-6.86,'Morogoro','Pumps, pipes and hand tools. Sample listing.','Medium'],['Input shops','shop',32.9,-2.48,'Mwanza','Seed and pesticide retailers. Sample listing.','Medium'],['Input shops','shop',35.73,-6.15,'Dodoma','Seed and fertilizer retailers. Sample listing.','Small'],['Input shops','shop',37.3,-3.32,'Kilimanjaro','Coffee and maize inputs. Sample listing.','Small'],['Input shops','shop',35.62,-10.7,'Ruvuma','Maize and coffee inputs. Sample listing.','Small'],
['Ministry of Agriculture','office',35.82,-6.15,'Dodoma','National policy and extension services.','Government'],['Fertilizer Regulatory Authority','office',35.7,-6.2,'Dodoma','Regulates fertilizer and subsidy.','Government'],['National Food Reserve Agency','office',35.76,-6.21,'Dodoma','Strategic grain reserves.','Government'],['Sokoine University of Agriculture','office',37.65,-6.85,'Morogoro','Agricultural university and research.','Education'],['TOSCI Seed Certification','office',37.7,-6.78,'Morogoro','Seed quality certification.','Government'],['Pesticides Research','office',36.75,-3.45,'Arusha','Plant health and pesticides research.','Government'],['Coffee Board','office',37.36,-3.37,'Kilimanjaro','Coffee sector regulation.','Government'],['TARI Uyole','office',33.55,-8.93,'Mbeya','Agricultural research centre.','Government'],['TARI Ukiriguru','office',33.0,-2.7,'Mwanza','Cotton and lake zone research.','Government']];
let ly='crops',sp=null;
$('#ml').innerHTML=LY.map(l=>`<button class="chip" data-l="${l[0]}">${ic(l[2])}${l[1]}</button>`).join('');
$('#ml').onclick=e=>{const b=e.target.closest('[data-l]');if(b){ly=b.dataset.l;sp=null;map()}};
$('#mtop').onclick=e=>{const g=e.target.closest('[data-p]');if(g){sp=+g.dataset.p;map()}};
const dark=()=>{const t=document.documentElement.dataset.theme;return t?t==='dark':matchMedia('(prefers-color-scheme:dark)').matches};
let LM,TL,LG,lastLy;
let tOK=false;
function tiles(){if(TL)LM.removeLayer(TL);const d=dark(),k=typeof MAPTILER_KEY!=='undefined'&&MAPTILER_KEY;
 TL=k?L.tileLayer(`https://api.maptiler.com/maps/${d?'dataviz-dark':'dataviz-light'}/{z}/{x}/{y}.png?key=${k}`,{tileSize:512,zoomOffset:-1,maxZoom:18,attribution:'&copy; MapTiler &copy; OpenStreetMap contributors'}):L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:18,attribution:'&copy; OpenStreetMap contributors'});
 TL.on('tileload',()=>{tOK=true;const m=$('#mapmsg');if(m)m.remove()});TL.on('tileerror',()=>{if(!tOK&&!$('#mapmsg'))$('.mapw').insertAdjacentHTML('beforeend','<div id="mapmsg">Map tiles are not loading. Add a MapTiler key in js/config.js and host the site over https.</div>')});TL.addTo(LM)}
function initMap(){if(LM||!window.L)return;LM=L.map('lmap',{zoomControl:false,minZoom:5,maxBounds:[[-15,26],[3,45]]});LM.fitBounds([[-11.8,29.3],[-0.9,40.6]]);L.control.zoom({position:'bottomright'}).addTo(LM);tiles();new MutationObserver(tiles).observe(document.documentElement,{attributes:true,attributeFilter:['data-theme']})}
function map(){document.querySelectorAll('#ml .chip').forEach(c=>c.classList.toggle('on',c.dataset.l===ly));$('#mc').style.display=ly==='crops'?'flex':'none';
 document.querySelectorAll('#mc .chip').forEach(c=>c.classList.toggle('on',c.dataset.m===mc));
 initMap();if(!LM){$('#lmap').textContent='Map library could not load. Check your internet connection.';return}
 setTimeout(()=>LM.invalidateSize(),60);if(LG)LM.removeLayer(LG);
 if(ly!=='crops'){const Y=LY.find(l=>l[0]===ly),P=POI.map((p,i)=>[p,i]).filter(x=>x[0][1]===ly);if(sp===null||POI[sp][1]!==ly)sp=P[0][1];
  LG=L.markerClusterGroup({maxClusterRadius:42,showCoverageOnHover:false,iconCreateFunction:c=>L.divIcon({className:'',iconSize:[44,44],html:`<div class="cl">${c.getChildCount()}</div>`})});
  P.forEach(([p,i])=>LG.addLayer(L.marker([p[3],p[2]],{icon:L.divIcon({className:'',iconSize:[34,34],html:`<div class="pn ${i===sp?'sel':''}" style="background:${Y[3]}">${ic(Y[2])}</div>`})}).on('click',()=>{sp=i;map()})));
  const p=POI[sp];$('#mdet').innerHTML=`<span class="tag" style="color:${Y[3]}">${Y[1].replace(/s$/,'')} / ${p[6]}</span><h3 style="font-size:26px;margin-top:10px">${p[0]}</h3><span class="mut">${p[4]} region</span><p style="margin-top:8px">${p[5]}</p><a class="btn" style="margin-top:14px" target="_blank" rel="noopener" href="https://www.google.com/maps/dir/?api=1&destination=${p[3]},${p[2]}">${ic('map')}Directions</a>`;
  $('#mtop').innerHTML=P.map(([q,i])=>`<div class="card li ${i===sp?'sel':''}" data-p="${i}"><span class="ic" style="color:${Y[3]}">${ic(Y[2])}</span><span><b>${q[0]}</b><br><small class="mut">${q[4]} / ${q[6]}</small></span></div>`).join('')}
 else{const R=RG.filter(r=>mc==='All'||r[5].includes(mc));if(!R.find(r=>r[0]===ms))ms=R[0][0];const mx=Math.max(...R.map(r=>r[4]));
  LG=L.layerGroup(R.map(r=>{const d=24+Math.sqrt(r[4]/mx)*28;return L.marker([r[2],r[1]],{icon:L.divIcon({className:'',iconSize:[d,d],html:`<div class="cm ${r[0]===ms?'sel':''}" style="width:${d}px;height:${d}px">${(r[3]/1000).toFixed(1)}k</div>`})}).on('click',()=>{ms=r[0];map()})}));
  const r=RG.find(q=>q[0]===ms);
  $('#mdet').innerHTML=`<span class="mut">Selected region</span><h3 style="font-size:28px">${r[0]}</h3><div class="pm"><div><span class="mut">Farms</span><b>${r[3].toLocaleString()}</b></div><div><span class="mut">Hectares</span><b>${(r[4]/1000).toFixed(0)}k</b></div><div><span class="mut">Crops</span><b>${r[5].length}</b></div></div><div class="ps">${r[5].map(c=>`<span class="chip">${c}</span>`).join('')}</div><a class="btn" style="margin-top:14px" href="#prices" onclick="crop='${r[5][0]}';$('#reg').value=REG['${r[0]}']?'${r[0]}':$('#reg').value">See ${r[5][0]} prices</a>`;
  $('#mtop').innerHTML=[...R].sort((a,b)=>b[4]-a[4]).slice(0,4).map(q=>`<div class="card" style="padding:12px 16px"><div style="display:flex;justify-content:space-between"><b>${q[0]}</b><span class="mut">${(q[4]/1000).toFixed(0)}k ha</span></div><div class="bar"><i style="width:${q[4]/mx*100}%"></i></div></div>`).join('')}
 LG.addTo(LM);if(lastLy!==ly){lastLy=ly;LM.fitBounds([[-11.8,29.3],[-0.9,40.6]])}}
$('#mq').innerHTML=[0,1].map(()=>['Live prices','Farm map','Pest alerts','Spray window','Farm advisor','Free for everyone'].map(t=>`<span>${ic('leaf')}${t}</span>`).join('')).join('');
/* loader */
(()=>{const l=document.createElement('div');l.className='ld';l.textContent='0%';document.body.append(l);let n=0;const t=setInterval(()=>{n+=Math.ceil(Math.random()*14);if(n>=100){n=100;clearInterval(t);setTimeout(()=>{l.classList.add('out');setTimeout(()=>l.remove(),1000)},200)}l.textContent=n+'%'},70)})();
function rebuildAll(){const cr=Object.keys(CROPS),o=a=>a.map(r=>`<option>${r}</option>`).join('');if(!cr.includes(crop))crop=cr[0];
 $('#homenews').innerHTML=newsHTML(NEWS.slice(0,2));$('#nlist').innerHTML=newsHTML(NEWS);ticker();
 $('#crops').innerHTML=cr.map(c=>`<button class="chip" data-c="${c}">${c}</button>`).join('');$('#reg').innerHTML=o(Object.keys(REG));$('#wr').innerHTML=o(Object.keys(REG));
 $('#mc').innerHTML=['All',...cr].map(c=>`<button class="chip" data-m="${c}">${c}</button>`).join('');prices();health();wx();map()}
health();wx();track();map();route();
