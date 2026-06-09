/* =========================================================
   Rauchprotokoll – Web-App (reines JS, GitHub-Pages-tauglich)
   Speicherung: localStorage. Kein Server nötig.
   ========================================================= */

const STORE_KEY = 'rauchprotokoll_entries';
const SET_KEY   = 'rauchprotokoll_settings';

/* ---------- Datenzugriff ---------- */
function loadEntries(){
  try { return JSON.parse(localStorage.getItem(STORE_KEY)) || []; }
  catch(e){ return []; }
}
function saveEntries(arr){ localStorage.setItem(STORE_KEY, JSON.stringify(arr)); }

function loadSettings(){
  try { return JSON.parse(localStorage.getItem(SET_KEY)) || {}; }
  catch(e){ return {}; }
}
function saveSettings(s){ localStorage.setItem(SET_KEY, JSON.stringify(s)); }

let entries = loadEntries();

/* ---------- Hilfsfunktionen ---------- */
function toast(msg){
  const t = document.getElementById('toast');
  t.textContent = msg; t.classList.remove('hidden');
  clearTimeout(t._timer);
  t._timer = setTimeout(()=>t.classList.add('hidden'), 2600);
}

function fmtDateTime(iso){
  const d = new Date(iso);
  return d.toLocaleString('de-CH',{day:'2-digit',month:'2-digit',year:'numeric',hour:'2-digit',minute:'2-digit'});
}
function fmtTime(iso){
  return new Date(iso).toLocaleTimeString('de-CH',{hour:'2-digit',minute:'2-digit'});
}

function windCompass(deg){
  if(deg===null||deg===undefined) return '—';
  const dirs=['N','NO','O','SO','S','SW','W','NW'];
  return dirs[Math.round((deg%360)/45)%8];
}

function smellLabel(e){
  const p=[]; if(e.smellWood)p.push('Holz'); if(e.smellToxic)p.push('giftig/chemisch');
  return p.length?p.join(', '):'—';
}
function visLabel(e){
  if(e.visStrong)return 'stark sichtbar';
  if(e.visLight)return 'leicht sichtbar';
  return '—';
}

/* =========================================================
   TAB-NAVIGATION
   ========================================================= */
document.querySelectorAll('.nav-item').forEach(btn=>{
  btn.addEventListener('click',()=>{
    const tab = btn.dataset.tab;
    document.querySelectorAll('.nav-item').forEach(b=>b.classList.toggle('active', b===btn));
    document.querySelectorAll('.tab').forEach(s=>s.classList.remove('active'));
    document.getElementById('tab-'+tab).classList.add('active');
    if(tab==='calendar') renderCalendar();
    if(tab==='stats') renderStats();
  });
});

/* =========================================================
   ERFASSEN
   ========================================================= */
const form = {
  smellWood:false, smellToxic:false, visLight:false, visStrong:false,
  intensity:3, headSelf:false, headChild:false,
  windowState:'unbekannt', rooms:'', measures:'', note:'', photo:null
};

// Toggle-Buttons
document.querySelectorAll('.toggle').forEach(btn=>{
  btn.addEventListener('click',()=>{
    const key = btn.dataset.key;
    const group = btn.dataset.group;
    if(group==='vis'){
      // nur eine Sichtbarkeit gleichzeitig
      form.visLight=false; form.visStrong=false;
      document.querySelectorAll('[data-group="vis"]').forEach(b=>b.classList.remove('on'));
      form[key]=true; btn.classList.add('on');
    } else {
      form[key]=!form[key];
      btn.classList.toggle('on', form[key]);
    }
  });
});

document.getElementById('intensity').addEventListener('input',e=>{
  form.intensity=+e.target.value;
  document.getElementById('intensityVal').textContent=e.target.value;
});

['headSelf','headChild'].forEach(id=>{
  document.getElementById(id).addEventListener('change',e=>form[id]=e.target.checked);
});
document.getElementById('windowState').addEventListener('change',e=>form.windowState=e.target.value);
document.getElementById('rooms').addEventListener('input',e=>form.rooms=e.target.value);
document.getElementById('measures').addEventListener('input',e=>form.measures=e.target.value);
document.getElementById('note').addEventListener('input',e=>form.note=e.target.value);

// Foto: Kamera öffnen, Bild verkleinern, als DataURL speichern
document.getElementById('btnPhoto').addEventListener('click',()=>document.getElementById('photoInput').click());
document.getElementById('photoInput').addEventListener('change',e=>{
  const file=e.target.files[0]; if(!file)return;
  const reader=new FileReader();
  reader.onload=ev=>{
    const img=new Image();
    img.onload=()=>{
      // auf max 1280px Breite verkleinern (spart Speicher)
      const max=1280, scale=Math.min(1,max/img.width);
      const cv=document.createElement('canvas');
      cv.width=img.width*scale; cv.height=img.height*scale;
      cv.getContext('2d').drawImage(img,0,0,cv.width,cv.height);
      form.photo=cv.toDataURL('image/jpeg',0.7);
      const wrap=document.getElementById('photoPreviewWrap');
      document.getElementById('photoPreview').src=form.photo;
      wrap.classList.remove('hidden');
    };
    img.src=ev.target.result;
  };
  reader.readAsDataURL(file);
});

function resetForm(){
  Object.assign(form,{smellWood:false,smellToxic:false,visLight:false,visStrong:false,
    intensity:3,headSelf:false,headChild:false,windowState:'unbekannt',
    rooms:'',measures:'',note:'',photo:null});
  document.querySelectorAll('.toggle').forEach(b=>b.classList.remove('on'));
  document.getElementById('intensity').value=3;
  document.getElementById('intensityVal').textContent='3';
  document.getElementById('headSelf').checked=false;
  document.getElementById('headChild').checked=false;
  document.getElementById('windowState').value='unbekannt';
  document.getElementById('rooms').value='';
  document.getElementById('measures').value='';
  document.getElementById('note').value='';
  document.getElementById('photoPreviewWrap').classList.add('hidden');
  document.getElementById('photoInput').value='';
}

document.getElementById('btnDiscard').addEventListener('click',()=>{
  if(confirm('Eingabe löschen? Alle Felder werden verworfen.')) resetForm();
});

/* ---------- Standort + Wetter ---------- */
// liefert {coords:[lat,lon]} oder {error:'...'} – mit verständlichem Grund
function getLocation(){
  return new Promise(resolve=>{
    const s=loadSettings();
    if(s.useFixed && s.fixedLat && s.fixedLon){
      const lat=parseFloat(s.fixedLat), lon=parseFloat(s.fixedLon);
      if(isNaN(lat)||isNaN(lon)){ resolve({error:'Feste Koordinaten ungültig – bitte in den Einstellungen prüfen.'}); return; }
      resolve({coords:[lat,lon]}); return;
    }
    if(!navigator.geolocation){ resolve({error:'Dieser Browser unterstützt keine Standortbestimmung.'}); return; }
    navigator.geolocation.getCurrentPosition(
      pos=>resolve({coords:[pos.coords.latitude,pos.coords.longitude]}),
      err=>{
        let msg='Standort nicht verfügbar.';
        if(err.code===1) msg='Standort-Erlaubnis verweigert. Bitte im Browser erlauben (Schloss-Symbol in der Adresszeile) – oder in den Einstellungen feste Koordinaten eintragen.';
        else if(err.code===2) msg='Standort konnte nicht bestimmt werden (kein Signal). Tipp: feste Koordinaten in den Einstellungen eintragen.';
        else if(err.code===3) msg='Standortabfrage hat zu lange gedauert. Bitte erneut laden.';
        resolve({error:msg});
      },
      {timeout:12000, enableHighAccuracy:false, maximumAge:300000}
    );
  });
}

// zuletzt geladene Wetterdaten (werden beim Speichern verwendet)
let currentWeather=null, currentCoords=null;

// Wetterbereich auf der Erfassen-Seite laden und anzeigen
async function loadWeatherDisplay(){
  const statusEl=document.getElementById('weatherStatus');
  const contentEl=document.getElementById('weatherContent');
  statusEl.textContent='Wird geladen…';
  statusEl.classList.remove('hidden');
  contentEl.classList.add('hidden');
  currentWeather=null; currentCoords=null;

  const loc=await getLocation();
  if(loc.error){ statusEl.textContent='⚠ '+loc.error; return; }
  currentCoords=loc.coords;

  const w=await fetchWeather(loc.coords[0],loc.coords[1]);
  if(!w){ statusEl.textContent='⚠ Wetterdaten konnten nicht geladen werden (Internet prüfen).'; return; }
  currentWeather=w;

  // Anzeige füllen
  statusEl.classList.add('hidden');
  contentEl.classList.remove('hidden');
  const compass=windCompass(w.windDirection);
  document.getElementById('windDir').textContent=`aus ${compass}`;
  document.getElementById('windSpd').textContent=`${w.windSpeed} km/h`;
  document.getElementById('wTemp').textContent=`${w.temperature} °C`;
  document.getElementById('wPress').textContent=`${w.pressure} hPa`;
  document.getElementById('wHum').textContent=`${w.humidity} %`;
  document.getElementById('wDisp').textContent=w.dispersion;

  // Pfeil zeigt, WOHIN der Wind weht (Richtung + 180°)
  const arrow=document.getElementById('compassArrow');
  const blowTo=((w.windDirection||0)+180)%360;
  arrow.style.transform=`translate(-50%,-50%) rotate(${blowTo}deg)`;

  // Hinweis: weht der Wind Richtung Süden (also auf dich zu)?
  const note=document.getElementById('windNote');
  const towardCompass=windCompass(blowTo);
  const south = blowTo>=135 && blowTo<=225;       // weht nach S/SO/SW
  const lightWind = (w.windSpeed!==null && w.windSpeed<12);
  arrow.classList.toggle('south', south);
  if(south && lightWind){
    note.className='weather-note hit';
    note.textContent=`Wind weht nach ${towardCompass} bei wenig Wind – Rauch zieht in diese Richtung. Guter Zeitpunkt zum Dokumentieren.`;
  } else {
    note.className='weather-note';
    note.textContent=`Wind weht nach ${towardCompass} (${w.windSpeed} km/h).`;
  }
}

document.getElementById('btnRefreshWeather').addEventListener('click',loadWeatherDisplay);

function estimateDispersion(temp,pres,hum){
  if(temp==null||pres==null) return 'neutral';
  let s=0;
  if(pres>1020)s-=1; if(pres<1005)s+=1;
  if(temp>15)s+=1; if(temp<5)s-=1;
  if(hum>85)s-=1;
  if(s>=1)return 'steigt auf';
  if(s<=-1)return 'sinkt zu Boden';
  return 'neutral';
}

async function fetchWeather(lat,lon){
  const url=`https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}`+
    `&current=temperature_2m,relative_humidity_2m,surface_pressure,wind_speed_10m,wind_direction_10m`;
  try{
    const res=await fetch(url);
    if(!res.ok)return null;
    const d=await res.json(); const c=d.current;
    return {
      temperature:c.temperature_2m, humidity:c.relative_humidity_2m,
      pressure:c.surface_pressure, windSpeed:c.wind_speed_10m,
      windDirection:c.wind_direction_10m,
      dispersion:estimateDispersion(c.temperature_2m,c.surface_pressure,c.relative_humidity_2m)
    };
  }catch(e){ return null; }
}

document.getElementById('btnSave').addEventListener('click',async()=>{
  if(!form.smellWood&&!form.smellToxic&&!form.visLight&&!form.visStrong){
    toast('Bitte mindestens Geruch oder Sichtbarkeit wählen.'); return;
  }
  const btn=document.getElementById('btnSave');
  btn.disabled=true; btn.textContent='Speichere…';

  const id=(entries.reduce((m,e)=>Math.max(m,e.id||0),0))+1;
  const entry={
    id, timestamp:new Date().toISOString(),
    smellWood:form.smellWood, smellToxic:form.smellToxic,
    visLight:form.visLight, visStrong:form.visStrong,
    intensity:form.intensity, headSelf:form.headSelf, headChild:form.headChild,
    windowState:form.windowState, rooms:form.rooms.trim(),
    measures:form.measures.trim(), note:form.note.trim(), photo:form.photo,
    lat:null,lon:null,temperature:null,pressure:null,humidity:null,
    windSpeed:null,windDirection:null,dispersion:null
  };

  // Standort + Wetter: bereits angezeigte Werte nutzen, sonst frisch holen
  let coords=currentCoords, w=currentWeather;
  if(!coords){
    const loc=await getLocation();
    if(loc.coords){ coords=loc.coords; w=await fetchWeather(coords[0],coords[1]); }
  }
  if(coords){
    entry.lat=coords[0]; entry.lon=coords[1];
    if(w){ Object.assign(entry,w); }
  }

  entries.push(entry); saveEntries(entries);
  resetForm();
  btn.disabled=false; btn.textContent='Speichern';
  toast(coords?'Eintrag gespeichert.':'Gespeichert (ohne Standort/Wetter).');
});

/* =========================================================
   KALENDER
   ========================================================= */
let calYear, calMonth, selectedDay=null;
(function initCal(){ const n=new Date(); calYear=n.getFullYear(); calMonth=n.getMonth(); })();

function entriesByDay(){
  const map={};
  entries.forEach(e=>{
    const d=new Date(e.timestamp);
    const k=`${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
    (map[k]=map[k]||[]).push(e);
  });
  return map;
}

document.getElementById('calPrev').addEventListener('click',()=>{calMonth--;if(calMonth<0){calMonth=11;calYear--;}renderCalendar();});
document.getElementById('calNext').addEventListener('click',()=>{calMonth++;if(calMonth>11){calMonth=0;calYear++;}renderCalendar();});

function renderCalendar(){
  const months=['Januar','Februar','März','April','Mai','Juni','Juli','August','September','Oktober','November','Dezember'];
  document.getElementById('calTitle').textContent=`${months[calMonth]} ${calYear}`;
  const cal=document.getElementById('calendar'); cal.innerHTML='';
  ['Mo','Di','Mi','Do','Fr','Sa','So'].forEach(d=>{
    const el=document.createElement('div'); el.className='cal-dow'; el.textContent=d; cal.appendChild(el);
  });
  const byDay=entriesByDay();
  const first=new Date(calYear,calMonth,1);
  let startDow=(first.getDay()+6)%7; // Montag=0
  const daysInMonth=new Date(calYear,calMonth+1,0).getDate();
  const today=new Date();
  for(let i=0;i<startDow;i++){const e=document.createElement('div');e.className='cal-day empty';cal.appendChild(e);}
  for(let day=1;day<=daysInMonth;day++){
    const el=document.createElement('div'); el.className='cal-day'; el.textContent=day;
    const key=`${calYear}-${calMonth}-${day}`;
    if(byDay[key]){el.classList.add('has');const m=document.createElement('span');m.className='mark';el.appendChild(m);}
    if(today.getFullYear()===calYear&&today.getMonth()===calMonth&&today.getDate()===day)el.classList.add('today');
    if(selectedDay===key)el.classList.add('sel');
    el.addEventListener('click',()=>{selectedDay=key;renderCalendar();renderDayDetails(key,byDay[key]||[]);});
    cal.appendChild(el);
  }
}

function renderDayDetails(key,list){
  const wrap=document.getElementById('dayDetails');
  if(list.length===0){wrap.innerHTML='<p class="hint">Keine Belastung an diesem Tag.</p>';return;}
  wrap.innerHTML='';
  list.sort((a,b)=>a.timestamp.localeCompare(b.timestamp));
  list.forEach(e=>wrap.appendChild(entryCard(e)));
}

function entryCard(e){
  const card=document.createElement('div'); card.className='entry-card';
  const head=document.createElement('div'); head.className='ec-head';
  head.innerHTML=`<span>${fmtTime(e.timestamp)} Uhr</span>
    <span class="ec-tag ${e.smellToxic?'tox':''}">${smellLabel(e)}</span>`;
  card.appendChild(head);

  const headache=[e.headSelf?'ich':'',e.headChild?'Kind':''].filter(Boolean).join(', ')||'nein';
  const kv=document.createElement('div'); kv.className='kv';
  kv.innerHTML=`
    <b>Sichtbarkeit</b><span>${visLabel(e)}</span>
    <b>Stärke</b><span>${e.intensity}/5</span>
    <b>Kopfweh</b><span>${headache}</span>
    <b>Fenster</b><span>${e.windowState}</span>
    <b>Räume</b><span>${e.rooms||'—'}</span>
    <b>Wind</b><span>${windCompass(e.windDirection)} • ${e.windSpeed??'—'} km/h</span>
    <b>Temperatur</b><span>${e.temperature??'—'} °C</span>
    <b>Luftdruck</b><span>${e.pressure??'—'} hPa</span>
    <b>Ausbreitung</b><span>${e.dispersion||'—'}</span>
    <b>Maßnahmen</b><span>${e.measures||'—'}</span>
    <b>Notiz</b><span>${e.note||'—'}</span>`;
  card.appendChild(kv);

  if(e.photo){const img=document.createElement('img');img.src=e.photo;card.appendChild(img);}

  const del=document.createElement('button'); del.className='del-link'; del.textContent='🗑 Löschen';
  del.addEventListener('click',()=>{
    if(confirm('Diesen Eintrag löschen?')){
      entries=entries.filter(x=>x.id!==e.id); saveEntries(entries);
      renderCalendar(); renderDayDetails(selectedDay, entriesByDay()[selectedDay]||[]);
      toast('Eintrag gelöscht.');
    }
  });
  card.appendChild(del);
  return card;
}

/* =========================================================
   STATISTIK
   ========================================================= */
function renderStats(){
  const cards=document.getElementById('statCards');
  const toxic=entries.filter(e=>e.smellToxic).length;
  const wood=entries.filter(e=>e.smellWood).length;
  const head=entries.filter(e=>e.headSelf||e.headChild).length;
  const stat=(num,lbl,color)=>`<div class="stat-card"><div class="num" style="color:${color}">${num}</div><div class="lbl">${lbl}</div></div>`;
  cards.innerHTML=
    stat(entries.length,'Gesamt','var(--accent)')+
    stat(toxic,'Giftig','var(--danger)')+
    stat(wood,'Holz','#8a6d3b')+
    stat(head,'Mit Kopfweh','#b5731f');

  // pro Monat
  const map={};
  entries.forEach(e=>{
    const d=new Date(e.timestamp);
    const k=`${String(d.getMonth()+1).padStart(2,'0')}/${String(d.getFullYear()).slice(2)}`;
    map[k]=(map[k]||0)+1;
  });
  const keys=Object.keys(map);
  const maxV=Math.max(1,...Object.values(map));
  const chart=document.getElementById('barChart');
  if(keys.length===0){chart.innerHTML='<p class="hint">Noch keine Daten.</p>';return;}
  chart.innerHTML=keys.map(k=>`
    <div class="bar-wrap">
      <span class="bar-val">${map[k]}</span>
      <div class="bar" style="height:${(map[k]/maxV)*100}%"></div>
      <span class="bar-lbl">${k}</span>
    </div>`).join('');
}

/* =========================================================
   EXPORT: PDF / Text / Backup / Monatsbericht
   ========================================================= */
function buildRows(list){
  return list.map(e=>{
    const headache=[e.headSelf?'ich':'',e.headChild?'Kind':''].filter(Boolean).join('/')||'—';
    return [
      String(e.id), fmtDateTime(e.timestamp), smellLabel(e), visLabel(e),
      String(e.intensity), headache, windCompass(e.windDirection),
      e.windSpeed??'—', e.temperature??'—', e.pressure??'—',
      e.dispersion||'—', e.note||''
    ];
  });
}

function makePdf(list, titleSuffix=''){
  const { jsPDF } = window.jspdf;
  const doc=new jsPDF({orientation:'landscape'});
  doc.setFontSize(14);
  doc.text('Immissionsprotokoll Rauchbelastung '+titleSuffix, 14, 15);
  doc.setFontSize(9);
  doc.text(`Erstellt: ${fmtDateTime(new Date().toISOString())}  •  Einträge: ${list.length}`,14,21);
  doc.autoTable({
    startY:25,
    head:[['Nr','Datum/Zeit','Geruch','Sicht','Int.','Kopfweh','Wind','km/h','°C','hPa','Ausbreitung','Notiz']],
    body:buildRows(list),
    styles:{fontSize:7,cellPadding:1.5},
    headStyles:{fillColor:[47,107,94]},
    columnStyles:{11:{cellWidth:40}}
  });
  doc.setFontSize(7);
  const y=doc.lastAutoTable.finalY+8;
  doc.text('Hinweis: Zeitstempel automatisch gesetzt. GPS und Wetterdaten (Quelle: Open-Meteo) automatisch ergänzt.',14,y);
  return doc;
}

document.getElementById('btnPdf').addEventListener('click',()=>{
  if(entries.length===0){toast('Keine Einträge.');return;}
  makePdf(entries).save('rauchprotokoll.pdf');
});

document.getElementById('btnText').addEventListener('click',async()=>{
  if(entries.length===0){toast('Keine Einträge.');return;}
  let txt='Rauchprotokoll – Export\n\n';
  entries.forEach(e=>{
    txt+=`${fmtDateTime(e.timestamp)} | Geruch: ${smellLabel(e)} | ${visLabel(e)} | Stärke ${e.intensity}/5 | `+
         `Wind ${windCompass(e.windDirection)} ${e.windSpeed??'—'}km/h | ${e.temperature??'—'}°C | `+
         `${e.pressure??'—'}hPa | ${e.dispersion||'—'} | ${e.note||''}\n`;
  });
  if(navigator.share){
    try{ await navigator.share({title:'Rauchprotokoll',text:txt}); return; }catch(e){}
  }
  // Fallback: als .txt herunterladen
  downloadFile('rauchprotokoll.txt', txt, 'text/plain');
  toast('Textdatei gespeichert.');
});

document.getElementById('btnMonthly').addEventListener('click',()=>{
  const s=loadSettings();
  const now=new Date();
  const lm=new Date(now.getFullYear(),now.getMonth()-1,1);
  const list=entries.filter(e=>{
    const d=new Date(e.timestamp);
    return d.getFullYear()===lm.getFullYear()&&d.getMonth()===lm.getMonth();
  });
  if(list.length===0){toast('Keine Einträge im Vormonat.');return;}
  const months=['Januar','Februar','März','April','Mai','Juni','Juli','August','September','Oktober','November','Dezember'];
  const monthName=`${months[lm.getMonth()]} ${lm.getFullYear()}`;
  makePdf(list,'– '+monthName).save(`rauchprotokoll_${monthName.replace(' ','_')}.pdf`);

  const to=s.reportEmail||'';
  const subject=encodeURIComponent('Rauchprotokoll '+monthName);
  const body=encodeURIComponent(`Anbei das Rauchprotokoll für ${monthName} (${list.length} Einträge). Bitte das soeben heruntergeladene PDF anhängen.`);
  setTimeout(()=>{ window.location.href=`mailto:${to}?subject=${subject}&body=${body}`; }, 600);
  toast('PDF gespeichert – Mail-App öffnet sich.');
});

/* ---------- Backup / Wiederherstellen ---------- */
function downloadFile(name, content, type){
  const blob=new Blob([content],{type});
  const a=document.createElement('a');
  a.href=URL.createObjectURL(blob); a.download=name;
  document.body.appendChild(a); a.click(); a.remove();
  URL.revokeObjectURL(a.href);
}

document.getElementById('btnBackup').addEventListener('click',()=>{
  if(entries.length===0){toast('Keine Daten.');return;}
  downloadFile('rauchprotokoll_backup.json', JSON.stringify(entries,null,2),'application/json');
  toast('Backup gespeichert.');
});

document.getElementById('btnRestore').addEventListener('click',()=>document.getElementById('restoreInput').click());
document.getElementById('restoreInput').addEventListener('change',e=>{
  const file=e.target.files[0]; if(!file)return;
  const r=new FileReader();
  r.onload=ev=>{
    try{
      const data=JSON.parse(ev.target.result);
      if(!Array.isArray(data))throw 0;
      if(confirm(`${data.length} Einträge wiederherstellen? Vorhandene werden ersetzt.`)){
        entries=data; saveEntries(entries); renderStats();
        toast('Wiederhergestellt.');
      }
    }catch(err){ toast('Datei ungültig.'); }
  };
  r.readAsText(file);
});

/* =========================================================
   EINSTELLUNGEN
   ========================================================= */
const settingsModal=document.getElementById('settingsModal');
document.getElementById('btnSettings').addEventListener('click',()=>{
  const s=loadSettings();
  document.getElementById('useFixed').checked=!!s.useFixed;
  document.getElementById('fixedFields').classList.toggle('hidden',!s.useFixed);
  document.getElementById('fixedLat').value=s.fixedLat||'';
  document.getElementById('fixedLon').value=s.fixedLon||'';
  document.getElementById('reportEmail').value=s.reportEmail||'';
  settingsModal.classList.remove('hidden');
});
document.getElementById('useFixed').addEventListener('change',e=>{
  document.getElementById('fixedFields').classList.toggle('hidden',!e.target.checked);
});
document.getElementById('btnSettingsClose').addEventListener('click',()=>settingsModal.classList.add('hidden'));
document.getElementById('btnSettingsSave').addEventListener('click',()=>{
  saveSettings({
    useFixed:document.getElementById('useFixed').checked,
    fixedLat:document.getElementById('fixedLat').value.trim().replace(',','.'),
    fixedLon:document.getElementById('fixedLon').value.trim().replace(',','.'),
    reportEmail:document.getElementById('reportEmail').value.trim()
  });
  settingsModal.classList.add('hidden');
  toast('Einstellungen gespeichert.');
});
settingsModal.addEventListener('click',e=>{ if(e.target===settingsModal) settingsModal.classList.add('hidden'); });

/* ---------- Init ---------- */
renderCalendar();
loadWeatherDisplay();
