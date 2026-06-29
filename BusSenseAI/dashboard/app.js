const API = location.origin.includes('5000') ? '' : 'http://localhost:5000';
const levelClass = pct => pct >= 80 ? 'Red' : pct >= 55 ? 'Yellow' : 'Green';
let routeChart, demandChart, map, markers = [];

function ensureMap() {
  if (!map) {
    map = L.map('map').setView([8.5241, 76.9366], 12);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {maxZoom: 19, attribution: '&copy; OpenStreetMap'}).addTo(map);
  }
}

function renderMap(buses) {
  ensureMap();
  markers.forEach(marker => marker.remove());
  markers = buses.map(bus => L.marker([bus.latitude, bus.longitude]).addTo(map).bindPopup(`<b>${bus.bus_id}</b><br>Route ${bus.route_number}<br>${bus.occupancy_percentage}% occupied<br>${bus.seat_availability} seats`));
}

function renderChart(target, existing, labels, data, label, color) {
  if (existing) existing.destroy();
  return new Chart(document.querySelector(target), {type:'bar', data:{labels, datasets:[{label, data, backgroundColor:color}]}, options:{responsive:true, scales:{y:{beginAtZero:true,max:100}}}});
}

async function loadDashboard(){
  const [buses, stats, recs, demand, recommendedBuses] = await Promise.all([
    fetch(`${API}/api/buses`).then(r=>r.json()),
    fetch(`${API}/api/stats`).then(r=>r.json()),
    fetch(`${API}/api/recommendations`).then(r=>r.json()),
    fetch(`${API}/api/demand`).then(r=>r.json()),
    fetch(`${API}/api/recommend-buses`).then(r=>r.json())
  ]);
  document.querySelector('#metrics').innerHTML = [
    ['Avg Occupancy', `${stats.average_occupancy}%`], ['Utilization Score', `${stats.bus_utilization_score}`],
    ['Fuel Savings', `${stats.estimated_fuel_savings_litres} L`], ['CO₂ Reduction', `${stats.estimated_co2_reduction_kg} kg`]
  ].map(([k,v])=>`<article class="card"><span>${k}</span><strong>${v}</strong></article>`).join('');
  document.querySelector('#busRows').innerHTML = buses.map(b=>`<tr><td>${b.bus_id}</td><td>${b.route_number}</td><td>${b.operator_type}</td><td>${b.passenger_count??0}</td><td>${b.occupancy_percentage??0}%</td><td>${b.seat_availability??b.capacity}</td><td>${b.bus_utilization_score}</td><td><span class="badge ${levelClass(b.occupancy_percentage??0)}">${levelClass(b.occupancy_percentage??0)}</span></td></tr>`).join('');
  document.querySelector('#alerts').innerHTML = stats.overcrowding_alerts.map(a=>`<li>${a.bus_id} on ${a.route_number}: ${a.occupancy_percentage}% occupied</li>`).join('') || '<li>No current alerts.</li>';
  document.querySelector('#recommendations').innerHTML = recs.map(r=>`<li><b>${r.route_number}</b>: ${r.action} (${r.priority})</li>`).join('');
  document.querySelector('#busRecommendations').innerHTML = recommendedBuses.map(b=>`<li><b>${b.bus_id}</b> route ${b.route_number}: ${b.recommendation_reason}, ETA ${b.eta_minutes} min</li>`).join('');
  routeChart = renderChart('#routeChart', routeChart, stats.route_statistics.map(r=>r.route_number), stats.route_statistics.map(r=>r.avg_occupancy), 'Average occupancy %', '#26a69a');
  demandChart = renderChart('#demandChart', demandChart, demand.map(r=>r.route_number), demand.map(r=>r.predicted_occupancy), 'Predicted next occupancy %', '#5c6bc0');
  renderMap(buses);
}
loadDashboard(); setInterval(loadDashboard, 30000);
