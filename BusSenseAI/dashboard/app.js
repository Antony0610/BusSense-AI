const API = location.origin.includes('5000') ? '' : 'http://localhost:5000';
const levelClass = pct => pct >= 80 ? 'Red' : pct >= 55 ? 'Yellow' : 'Green';
async function loadDashboard(){
  const [buses, stats, recs] = await Promise.all([
    fetch(`${API}/api/buses`).then(r=>r.json()), fetch(`${API}/api/stats`).then(r=>r.json()), fetch(`${API}/api/recommendations`).then(r=>r.json())
  ]);
  document.querySelector('#metrics').innerHTML = [
    ['Avg Occupancy', `${stats.average_occupancy}%`], ['Utilization Score', `${stats.bus_utilization_score}`],
    ['Fuel Savings', `${stats.estimated_fuel_savings_litres} L`], ['CO₂ Reduction', `${stats.estimated_co2_reduction_kg} kg`]
  ].map(([k,v])=>`<article class="card"><span>${k}</span><strong>${v}</strong></article>`).join('');
  document.querySelector('#busRows').innerHTML = buses.map(b=>`<tr><td>${b.bus_id}</td><td>${b.route_number}</td><td>${b.operator_type}</td><td>${b.passenger_count??0}</td><td>${b.occupancy_percentage??0}%</td><td>${b.seat_availability??b.capacity}</td><td><span class="badge ${levelClass(b.occupancy_percentage??0)}">${levelClass(b.occupancy_percentage??0)}</span></td></tr>`).join('');
  document.querySelector('#alerts').innerHTML = stats.overcrowding_alerts.map(a=>`<li>${a.bus_id} on ${a.route_number}: ${a.occupancy_percentage}% occupied</li>`).join('') || '<li>No current alerts.</li>';
  document.querySelector('#recommendations').innerHTML = recs.map(r=>`<li><b>${r.route_number}</b>: ${r.action} (${r.priority})</li>`).join('');
  new Chart(document.querySelector('#routeChart'), {type:'bar', data:{labels:stats.route_statistics.map(r=>r.route_number), datasets:[{label:'Average occupancy %', data:stats.route_statistics.map(r=>r.avg_occupancy), backgroundColor:'#26a69a'}]}, options:{scales:{y:{beginAtZero:true,max:100}}}});
}
loadDashboard(); setInterval(loadDashboard, 30000);
