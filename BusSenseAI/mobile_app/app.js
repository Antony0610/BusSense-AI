const API='http://localhost:5000';
const level=p=>p>=80?'Red':p>=55?'Yellow':'Green';
async function load(){
 const [buses,recs]=await Promise.all([fetch(`${API}/api/buses`).then(r=>r.json()),fetch(`${API}/api/recommend-buses`).then(r=>r.json())]);
 document.querySelector('#busCards').innerHTML=buses.map(b=>{const l=level(b.occupancy_percentage??0); const alternatives=recs.filter(x=>x.route_number===b.route_number&&x.bus_id!==b.bus_id).map(x=>x.bus_id).join(', ')||'No better alternative now'; return `<article class="card"><h2>${b.bus_id} · Route ${b.route_number}</h2><span class="level ${l}">${l} crowd level</span><div class="meta"><p>Occupancy<br><b>${b.occupancy_percentage??0}%</b></p><p>Seats<br><b>${b.seat_availability??b.capacity}</b></p><p>ETA<br><b>${b.eta_minutes} min</b></p><p>Prediction<br><b>${(b.seat_availability??0)>10?'Seats likely':'Limited seats'}</b></p></div><p><b>Less-crowded alternatives:</b> ${alternatives}</p><p><b>Location:</b> ${b.latitude}, ${b.longitude}</p></article>`}).join('');
}
load(); setInterval(load,30000);
