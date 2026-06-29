const API='http://localhost:5000';
const level=p=>p>=80?'Red':p>=55?'Yellow':'Green';
const eta=(i)=>`${6+i*4} min`;
async function load(){
 const buses=await fetch(`${API}/api/buses`).then(r=>r.json());
 const sorted=[...buses].sort((a,b)=>(a.occupancy_percentage??0)-(b.occupancy_percentage??0));
 document.querySelector('#busCards').innerHTML=buses.map((b,i)=>{const alternatives=sorted.filter(x=>x.route_number===b.route_number&&x.bus_id!==b.bus_id).slice(0,2).map(x=>x.bus_id).join(', ')||'No better alternative now'; const l=level(b.occupancy_percentage??0); return `<article class="card"><h2>${b.bus_id} · Route ${b.route_number}</h2><span class="level ${l}">${l} crowd level</span><div class="meta"><p>Occupancy<br><b>${b.occupancy_percentage??0}%</b></p><p>Seats<br><b>${b.seat_availability??b.capacity}</b></p><p>ETA<br><b>${eta(i)}</b></p><p>Prediction<br><b>${(b.seat_availability??0)>10?'Seats likely':'Limited seats'}</b></p></div><p><b>Less-crowded alternatives:</b> ${alternatives}</p></article>`}).join('');
}
load(); setInterval(load,30000);
