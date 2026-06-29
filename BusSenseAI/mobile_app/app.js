codex/build-bussense-ai-prototype-project-mqmve9
const API = location.origin.includes('5000') ? '' : 'http://localhost:5000';
const fallbackBuses = [
  {bus_id:'KSRTC-101',operator_type:'KSRTC',route_number:'R1',occupancy_percentage:48,passenger_count:24,seat_availability:26,eta_minutes:7,latitude:8.5241,longitude:76.9366,bus_utilization_score:56},
  {bus_id:'PVT-203',operator_type:'PRIVATE',route_number:'R3',occupancy_percentage:40,passenger_count:16,seat_availability:24,eta_minutes:4,latitude:8.562,longitude:76.972,bus_utilization_score:47},
  {bus_id:'KSRTC-104',operator_type:'KSRTC',route_number:'R3',occupancy_percentage:92,passenger_count:46,seat_availability:4,eta_minutes:10,latitude:8.56,longitude:76.97,bus_utilization_score:100}
];
const i18n = {
  en:{appName:'BusSense AI Passenger App',tagline:'Choose the smartest bus now'},
  ml:{appName:'ബസ്സെൻസ് AI യാത്രക്കാരൻ ആപ്പ്',tagline:'ഇപ്പോൾ ഏറ്റവും അനുയോജ്യമായ ബസ് തിരഞ്ഞെടുക്കുക'}
};
const state = {
  page:'home', buses:[], occupancy:[], stats:null, user:{name:'Anu Passenger', trips:18, co2Saved:42.6, fuelSaved:15.9},
  location:{latitude:8.5241, longitude:76.9366, label:'Thampanoor, Thiruvananthapuram'},
  favorites:JSON.parse(localStorage.getItem('bussense:favorites') || '[]'),
  history:JSON.parse(localStorage.getItem('bussense:history') || '[]'),
  viewed:JSON.parse(localStorage.getItem('bussense:viewed') || '[]'),
  voice:localStorage.getItem('bussense:voice') === 'true', language:localStorage.getItem('bussense:language') || 'en'
};
let map, markers = [], trendChart, ecoChart;

const qs = sel => document.querySelector(sel);
const save = (key, value) => localStorage.setItem(`bussense:${key}`, JSON.stringify(value));
const pct = value => Math.round(Number(value || 0));
const crowd = value => pct(value) <= 50 ? {label:'Green', cls:'green', icon:'🟢'} : pct(value) <= 80 ? {label:'Yellow', cls:'yellow', icon:'🟡'} : {label:'Red', cls:'red', icon:'🔴'};
const seatProbability = bus => Math.max(5, Math.min(98, Math.round(((bus.seat_availability || 0) / Math.max((bus.passenger_count || 0) + (bus.seat_availability || 1), 1)) * 100)));
const comfortScore = bus => Math.max(0, Math.min(100, Math.round((100 - pct(bus.occupancy_percentage)) * 0.65 + Math.min(bus.seat_availability || 0, 25) * 1.4 + Math.max(0, 15 - (bus.eta_minutes || 20)))));
const distanceKm = bus => { const dx=(bus.latitude-state.location.latitude)*111; const dy=(bus.longitude-state.location.longitude)*111; return Math.sqrt(dx*dx+dy*dy).toFixed(1); };
const overcrowd15 = bus => Math.min(100, pct(bus.occupancy_percentage) + Math.max(3, Math.round((15 - Math.min(bus.eta_minutes || 15, 15)) * 1.5)));

async function api(path, fallback) {
  try { const res = await fetch(`${API}${path}`); if (!res.ok) throw new Error(res.statusText); return await res.json(); }
  catch (err) { console.warn(`Using sample data for ${path}`, err); return fallback; }
}

function announce(message) { if (state.voice && 'speechSynthesis' in window) speechSynthesis.speak(new SpeechSynthesisUtterance(message)); }
function addHistory(item) { state.history.unshift({...item, at:new Date().toLocaleString()}); state.history = state.history.slice(0, 20); save('history', state.history); }
function addViewed(bus) { state.viewed.unshift({bus_id:bus.bus_id, route_number:bus.route_number, occupancy_percentage:bus.occupancy_percentage, at:new Date().toLocaleString()}); state.viewed = state.viewed.slice(0, 20); save('viewed', state.viewed); }

async function loadData() {
  const [buses, occupancy, stats] = await Promise.all([
    api('/api/buses', fallbackBuses), api('/api/occupancy', []), api('/api/stats', {estimated_co2_reduction_kg:state.user.co2Saved, estimated_fuel_savings_litres:state.user.fuelSaved})
  ]);
  state.buses = buses.map((bus, index) => ({eta_minutes:6 + index * 4, latitude:8.5241, longitude:76.9366, ...bus}));
  state.occupancy = occupancy;
  state.stats = stats;
}

function busCard(bus, options={}) {
  const c = crowd(bus.occupancy_percentage); const comfort = comfortScore(bus); const seat = seatProbability(bus);
  return `<article class="bus-card" data-bus-id="${bus.bus_id}"><div class="bus-top"><div><div class="bus-title">${bus.operator_type === 'PRIVATE' ? 'Private Bus' : 'KSRTC'} ${bus.bus_id}</div><p class="muted">Route ${bus.route_number} · ${distanceKm(bus)} km away</p></div><span class="pill ${c.cls}">${c.icon} ${c.label}</span></div><div class="bus-grid"><div><span>Occupancy</span><b>${pct(bus.occupancy_percentage)}%</b></div><div><span>Passengers</span><b>${bus.passenger_count ?? 0}</b></div><div><span>ETA</span><b>${bus.eta_minutes ?? '--'} min</b></div><div><span>Seats</span><b>${bus.seat_availability ?? 0}</b></div><div><span>Seat chance</span><b>${seat}%</b></div><div><span>15-min risk</span><b>${overcrowd15(bus)}%</b></div></div><div class="comfort" aria-label="Comfort score"><span style="width:${comfort}%"></span></div><p><b>Comfort score:</b> ${comfort}/100 · ${seat >= 65 ? 'High chance of getting a seat.' : seat >= 35 ? 'Moderate chance of getting a seat.' : 'Low chance of getting a seat.'}</p>${options.reason ? `<p><b>AI recommendation:</b> ${options.reason}</p>` : ''}<div class="actions"><button data-action="view" data-id="${bus.bus_id}">View</button><button data-action="favorite-bus" data-id="${bus.bus_id}">Save bus</button><button data-action="report" data-id="${bus.bus_id}">Report</button></div></article>`;
}

function bestBuses() { return [...state.buses].sort((a,b)=> comfortScore(b)-comfortScore(a) || (a.eta_minutes||99)-(b.eta_minutes||99)); }
function recommendationReason(bus) { return `${bus.operator_type === 'PRIVATE' ? 'Private Bus' : 'KSRTC'} ${bus.bus_id} arriving in ${bus.eta_minutes} minutes has ${pct(bus.occupancy_percentage)}% occupancy and is recommended.`; }

function renderHome() {
  qs('#page-home').innerHTML = qs('#home-template').innerHTML;
  qs('#nearbyCount').textContent = state.buses.length;
  const best = bestBuses()[0]; qs('#bestComfort').textContent = best ? `${comfortScore(best)}/100` : '--'; qs('#seatChance').textContent = best ? `${seatProbability(best)}%` : '--';
  qs('#nearbyBuses').innerHTML = bestBuses().slice(0,4).map(bus => busCard(bus, {reason:recommendationReason(bus)})).join('');
  qs('#searchButton').addEventListener('click', () => { addHistory({source:qs('#sourceInput').value, destination:qs('#destinationInput').value}); renderPage('recommendations'); announce('Showing recommended buses'); });
  renderMap(); wireCards();
}

function renderLive() {
  qs('#page-live').innerHTML = qs('#live-template').innerHTML;
  qs('#liveBusList').innerHTML = state.buses.map(bus => busCard(bus)).join('');
  const labels = state.occupancy.length ? state.occupancy.slice(0,8).map(r=>r.bus_id).reverse() : state.buses.map(b=>b.bus_id);
  const values = state.occupancy.length ? state.occupancy.slice(0,8).map(r=>r.occupancy_percentage).reverse() : state.buses.map(b=>b.occupancy_percentage);
  if (trendChart) trendChart.destroy();
  trendChart = new Chart(qs('#occupancyTrend'), {type:'line', data:{labels,datasets:[{label:'Occupancy %',data:values,borderColor:'#00796b',backgroundColor:'#80cbc466',fill:true,tension:.35}]}, options:{scales:{y:{beginAtZero:true,max:100}}}});
  wireCards();
}

function renderRecommendations() {
  qs('#page-recommendations').innerHTML = qs('#recommendations-template').innerHTML;
  const picks = bestBuses().slice(0,5);
  qs('#recommendationList').innerHTML = picks.map(bus => busCard(bus, {reason:recommendationReason(bus)})).join('');
  const crowded = state.buses.filter(bus => pct(bus.occupancy_percentage) > 85);
  qs('#alternativeList').innerHTML = crowded.length ? crowded.map(bus => { const alternatives = bestBuses().filter(item => item.bus_id !== bus.bus_id).slice(0,2); return `<article class="bus-card"><h3>${bus.bus_id} is overcrowded (${pct(bus.occupancy_percentage)}%)</h3><p>Alternative buses available.</p>${alternatives.map(alt => `<p><b>${alt.bus_id}</b>: ${pct(alt.occupancy_percentage)}% occupancy · ${alt.eta_minutes} min · comfort ${comfortScore(alt)}/100</p>`).join('')}</article>`; }).join('') : '<p class="muted">No bus above 85% occupancy right now.</p>';
  wireCards();
}

function renderSustainability() {
  qs('#page-sustainability').innerHTML = qs('#sustainability-template').innerHTML;
  const co2 = Number(state.stats?.estimated_co2_reduction_kg || state.user.co2Saved).toFixed(1); const fuel = Number(state.stats?.estimated_fuel_savings_litres || state.user.fuelSaved).toFixed(1);
  qs('#co2Saved').textContent = `${co2} kg`; qs('#fuelSaved').textContent = `${fuel} L`; qs('#ecoTrips').textContent = state.user.trips;
  if (ecoChart) ecoChart.destroy();
  ecoChart = new Chart(qs('#ecoChart'), {type:'doughnut', data:{labels:['CO₂ saved kg','Fuel saved L','Trips'], datasets:[{data:[co2,fuel,state.user.trips], backgroundColor:['#2e7d32','#26a69a','#f9a825']}]} });
}

function renderProfile() {
  qs('#page-profile').innerHTML = qs('#profile-template').innerHTML;
  qs('#profileName').textContent = state.user.name; qs('#profileStats').textContent = `${state.user.trips} trips · ${state.user.co2Saved} kg CO₂ saved`;
  qs('#favoritesList').innerHTML = state.favorites.map(f => `<span class="chip">${f.type}: ${f.value}</span>`).join('') || '<p class="muted">No favorites saved yet.</p>';
  qs('#historyList').innerHTML = state.history.slice(0,4).map(h => `<article class="bus-card"><b>${h.source || 'Current location'} → ${h.destination || 'Destination'}</b><p class="muted">${h.at}</p></article>`).join('') || '<p class="muted">No recent searches.</p>';
  qs('#largeTextToggle').checked = document.body.classList.contains('large-text'); qs('#contrastToggle').checked = document.body.classList.contains('high-contrast'); qs('#voiceToggle').checked = state.voice; qs('#languageSelect').value = state.language;
  qs('#largeTextToggle').onchange = e => document.body.classList.toggle('large-text', e.target.checked);
  qs('#contrastToggle').onchange = e => document.body.classList.toggle('high-contrast', e.target.checked);
  qs('#voiceToggle').onchange = e => { state.voice=e.target.checked; localStorage.setItem('bussense:voice', state.voice); announce('Voice announcements enabled'); };
  qs('#languageSelect').onchange = e => { state.language=e.target.value; localStorage.setItem('bussense:language', state.language); applyLanguage(); };
  qs('#saveRoute').onclick = () => addFavorite('route', bestBuses()[0]?.route_number || 'R1'); qs('#saveBus').onclick = () => addFavorite('bus', bestBuses()[0]?.bus_id || 'KSRTC-101'); qs('#saveDestination').onclick = () => addFavorite('destination', 'Technopark');
  qs('#shareLocation').onclick = () => alert(`Share location: ${state.location.latitude}, ${state.location.longitude}`); qs('#callEmergency').onclick = () => alert('Calling emergency contact: +91-100'); qs('#reportCrowding').onclick = () => postReport('overcrowding'); qs('#reportIssue').onclick = () => postReport('service_issue');
  qs('[data-page-link="history"]').onclick = () => renderPage('history');
}

function renderHistory() {
  qs('#page-history').innerHTML = qs('#history-template').innerHTML;
  qs('#searchHistory').innerHTML = state.history.map(h => `<article class="bus-card"><b>${h.source} → ${h.destination}</b><p class="muted">${h.at}</p></article>`).join('') || '<p class="muted">No searches yet.</p>';
  qs('#viewedHistory').innerHTML = state.viewed.map(v => `<article class="bus-card"><b>${v.bus_id}</b><p>Route ${v.route_number} · ${pct(v.occupancy_percentage)}% occupied</p><p class="muted">${v.at}</p></article>`).join('') || '<p class="muted">No viewed buses yet.</p>';
}

function addFavorite(type, value) { if (!value) return; state.favorites.unshift({type,value}); state.favorites = state.favorites.slice(0, 20); save('favorites', state.favorites); renderProfile(); }
async function postReport(type, bus_id = bestBuses()[0]?.bus_id) { try { await fetch(`${API}/api/report`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({bus_id, report_type:type, latitude:state.location.latitude, longitude:state.location.longitude})}); } catch (err) { console.warn('Report stored only in demo UI', err); } alert(`Report submitted: ${type} for ${bus_id}`); }

function wireCards() { document.querySelectorAll('[data-action]').forEach(btn => btn.onclick = () => { const bus = state.buses.find(item => item.bus_id === btn.dataset.id); if (!bus) return; if (btn.dataset.action === 'view') { addViewed(bus); announce(`${bus.bus_id} has ${pct(bus.occupancy_percentage)} percent occupancy`); } if (btn.dataset.action === 'favorite-bus') addFavorite('bus', bus.bus_id); if (btn.dataset.action === 'report') postReport('passenger_report', bus.bus_id); }); }

function renderMap() {
  if (!window.L) return;
  if (!map) { map = L.map('mobileMap').setView([state.location.latitude, state.location.longitude], 12); L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {maxZoom:19, attribution:'&copy; OpenStreetMap'}).addTo(map); L.circleMarker([state.location.latitude,state.location.longitude], {radius:8,color:'#00796b'}).addTo(map).bindPopup('Your location'); }
  markers.forEach(marker => marker.remove());
  markers = state.buses.map(bus => L.marker([bus.latitude,bus.longitude]).addTo(map).bindPopup(`${bus.bus_id}<br>${pct(bus.occupancy_percentage)}% occupied<br>${distanceKm(bus)} km away`));
  setTimeout(() => map.invalidateSize(), 50);
}

function renderPage(page) {
  state.page = page;
  document.querySelectorAll('.page').forEach(item => item.classList.remove('active-page'));
  qs(`#page-${page}`).classList.add('active-page');
  document.querySelectorAll('.tab').forEach(tab => tab.classList.toggle('active', tab.dataset.page === page));
  ({home:renderHome, live:renderLive, recommendations:renderRecommendations, sustainability:renderSustainability, profile:renderProfile, history:renderHistory}[page] || renderHome)();
}

function applyLanguage() { const text = i18n[state.language] || i18n.en; document.querySelectorAll('[data-i18n]').forEach(el => el.textContent = text[el.dataset.i18n] || el.textContent); }
function tick() { qs('#currentTime').textContent = new Date().toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'}); qs('#userLocation').textContent = state.location.label; }
function setupShell() { document.querySelectorAll('.tab').forEach(tab => tab.onclick = () => renderPage(tab.dataset.page)); qs('#themeToggle').onclick = () => { document.body.classList.toggle('dark'); qs('#themeToggle').textContent = document.body.classList.contains('dark') ? '☀️' : '🌙'; }; tick(); setInterval(tick, 30000); applyLanguage(); }

(async function init(){ setupShell(); await loadData(); renderPage('home'); setInterval(async()=>{ await loadData(); renderPage(state.page); }, 45000); })();
=======
const API='http://localhost:5000';
const level=p=>p>=80?'Red':p>=55?'Yellow':'Green';
async function load(){
 const [buses,recs]=await Promise.all([fetch(`${API}/api/buses`).then(r=>r.json()),fetch(`${API}/api/recommend-buses`).then(r=>r.json())]);
 document.querySelector('#busCards').innerHTML=buses.map(b=>{const l=level(b.occupancy_percentage??0); const alternatives=recs.filter(x=>x.route_number===b.route_number&&x.bus_id!==b.bus_id).map(x=>x.bus_id).join(', ')||'No better alternative now'; return `<article class="card"><h2>${b.bus_id} · Route ${b.route_number}</h2><span class="level ${l}">${l} crowd level</span><div class="meta"><p>Occupancy<br><b>${b.occupancy_percentage??0}%</b></p><p>Seats<br><b>${b.seat_availability??b.capacity}</b></p><p>ETA<br><b>${b.eta_minutes} min</b></p><p>Prediction<br><b>${(b.seat_availability??0)>10?'Seats likely':'Limited seats'}</b></p></div><p><b>Less-crowded alternatives:</b> ${alternatives}</p><p><b>Location:</b> ${b.latitude}, ${b.longitude}</p></article>`}).join('');
}
load(); setInterval(load,30000);
 main
