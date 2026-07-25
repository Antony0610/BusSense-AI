// BusSense AI Authority Dashboard Application Logic
const API = location.origin.includes('5000') ? '' : 'http://localhost:5000';

let map = null;
let markers = [];
let routeChartInstance = null;
let demandChartInstance = null;

let currentFilter = 'ALL';
let currentSearch = '';
let cachedBuses = [];

// Determine crowd level string and styling
function getCrowdStatus(pct) {
  if (pct >= 80) return { label: 'High / Overcrowded', level: 'red', color: '#f43f5e' };
  if (pct >= 55) return { label: 'Moderate', level: 'yellow', color: '#f59e0b' };
  return { label: 'Low / Optimal', level: 'green', color: '#10b981' };
}

// Leaflet Map Initialization & Updates
function updateMap(buses) {
  if (!window.L) return;

  if (!map) {
    map = L.map('map').setView([8.5241, 76.9366], 12);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap & BusSense AI'
    }).addTo(map);
  }

  // Clear existing markers
  markers.forEach(m => m.remove());
  markers = [];

  buses.forEach(bus => {
    const status = getCrowdStatus(bus.occupancy_percentage || 0);
    const isKsrtc = bus.operator_type === 'KSRTC';
    
    // Custom HTML Marker Icon
    const customIcon = L.divIcon({
      className: 'custom-bus-pin',
      html: `<div style="
        background: ${status.color};
        color: #ffffff;
        padding: 4px 8px;
        border-radius: 20px;
        font-weight: 800;
        font-size: 11px;
        box-shadow: 0 4px 10px rgba(0,0,0,0.4);
        border: 2px solid white;
        display: flex;
        align-items: center;
        gap: 4px;
      ">
        <span>${isKsrtc ? '🚍' : '🚌'}</span>
        <span>${bus.bus_id}</span>
      </div>`,
      iconSize: [80, 30],
      iconAnchor: [40, 15]
    });

    const marker = L.marker([bus.latitude || 8.5241, bus.longitude || 76.9366], { icon: customIcon })
      .addTo(map)
      .bindPopup(`
        <div style="font-family: sans-serif; padding: 4px;">
          <h4 style="margin: 0 0 4px; font-size: 14px;">${bus.bus_id} (${bus.operator_type})</h4>
          <p style="margin: 0; font-size: 12px; color: #555;">Route: <b>${bus.route_number}</b></p>
          <p style="margin: 0; font-size: 12px; color: #555;">Passengers: <b>${bus.passenger_count || 0} / ${bus.capacity || 50}</b></p>
          <p style="margin: 0; font-size: 12px; color: ${status.color}; font-weight: bold;">
            Occupancy: ${bus.occupancy_percentage || 0}% (${status.label})
          </p>
          <p style="margin: 4px 0 0; font-size: 11px; color: #888;">Seats Available: ${bus.seat_availability || 0}</p>
        </div>
      `);
    markers.push(marker);
  });
}

// Chart.js Chart Rendering
function renderRouteChart(routeStats) {
  const ctx = document.getElementById('routeChart');
  if (!ctx) return;

  const labels = routeStats.map(r => `Route ${r.route_number}`);
  const data = routeStats.map(r => r.avg_occupancy);

  if (routeChartInstance) {
    routeChartInstance.destroy();
  }

  routeChartInstance = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: [{
        label: 'Avg Occupancy %',
        data: data,
        backgroundColor: 'rgba(13, 148, 136, 0.65)',
        borderColor: '#0d9488',
        borderWidth: 2,
        borderRadius: 8
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: { beginAtZero: true, max: 100, grid: { color: 'rgba(255,255,255,0.05)' } },
        x: { grid: { display: false } }
      },
      plugins: { legend: { display: false } }
    }
  });
}

function renderDemandChart(demandData) {
  const ctx = document.getElementById('demandChart');
  if (!ctx) return;

  const labels = demandData.map(d => `Route ${d.route_number}`);
  const data = demandData.map(d => d.predicted_occupancy);

  if (demandChartInstance) {
    demandChartInstance.destroy();
  }

  demandChartInstance = new Chart(ctx, {
    type: 'line',
    data: {
      labels: labels,
      datasets: [{
        label: 'Predicted Next Occupancy %',
        data: data,
        borderColor: '#6366f1',
        backgroundColor: 'rgba(99, 102, 241, 0.25)',
        fill: true,
        tension: 0.4,
        pointBackgroundColor: '#6366f1',
        pointRadius: 6
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: { beginAtZero: true, max: 100, grid: { color: 'rgba(255,255,255,0.05)' } },
        x: { grid: { display: false } }
      },
      plugins: { legend: { display: false } }
    }
  });
}

// Render Table Rows with Filtering
function renderBusTable(buses) {
  const tbody = document.getElementById('busRows');
  if (!tbody) return;

  let filtered = buses.filter(b => {
    const matchFilter = currentFilter === 'ALL' || b.operator_type === currentFilter;
    const searchLower = currentSearch.toLowerCase();
    const matchSearch = !currentSearch ||
      (b.bus_id && b.bus_id.toLowerCase().includes(searchLower)) ||
      (b.route_number && b.route_number.toLowerCase().includes(searchLower));
    return matchFilter && matchSearch;
  });

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="9" class="text-center py-4">No matching buses found.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map(bus => {
    const occ = bus.occupancy_percentage || 0;
    const status = getCrowdStatus(occ);
    const isKsrtc = bus.operator_type === 'KSRTC';

    return `
      <tr>
        <td><b>${bus.bus_id}</b></td>
        <td><span class="badge-operator ${isKsrtc ? 'ksrtc' : 'private'}">${bus.operator_type}</span></td>
        <td>Route ${bus.route_number}</td>
        <td>${bus.passenger_count || 0} / ${bus.capacity || 50}</td>
        <td>
          <div style="display: flex; align-items: center; gap: 8px;">
            <span>${occ}%</span>
            <div class="progress-bar-bg">
              <div class="progress-bar-fill ${status.level}" style="width: ${Math.min(occ, 100)}%;"></div>
            </div>
          </div>
        </td>
        <td>${bus.seat_availability ?? (bus.capacity - (bus.passenger_count || 0))}</td>
        <td><b>${bus.bus_utilization_score || 0}</b></td>
        <td><span class="badge-status ${status.level}">${status.label}</span></td>
        <td>
          <button class="btn btn-secondary btn-sm" onclick="triggerDispatch('${bus.route_number}', '${bus.operator_type}')">
            ⚡ Dispatch
          </button>
        </td>
      </tr>
    `;
  }).join('');
}

// Global Dispatch Handler
window.triggerDispatch = async function(route, operator) {
  try {
    const res = await fetch(`${API}/api/dispatch`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ route_number: route, operator_type: operator })
    });
    const data = await res.json();
    alert(`Success: ${data.message}`);
    loadDashboard();
  } catch (err) {
    console.error('Dispatch failed', err);
  }
};

// CSV Export Feature
function exportCsv() {
  if (!cachedBuses.length) return;
  const headers = ['Bus ID', 'Operator', 'Route', 'Capacity', 'Passenger Count', 'Occupancy %', 'Seats Available', 'Utilization Score'];
  const csvRows = [headers.join(',')];

  cachedBuses.forEach(b => {
    csvRows.push([
      b.bus_id,
      b.operator_type,
      b.route_number,
      b.capacity,
      b.passenger_count || 0,
      b.occupancy_percentage || 0,
      b.seat_availability || 0,
      b.bus_utilization_score || 0
    ].join(','));
  });

  const blob = new Blob([csvRows.join('\n')], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `BusSense_Fleet_Report_${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
}

// Main Dashboard Fetch Loop
async function loadDashboard() {
  try {
    const [buses, stats, recs, demand, reports] = await Promise.all([
      fetch(`${API}/api/buses`).then(r => r.json()),
      fetch(`${API}/api/stats`).then(r => r.json()),
      fetch(`${API}/api/recommendations`).then(r => r.json()),
      fetch(`${API}/api/demand`).then(r => r.json()),
      fetch(`${API}/api/report`).then(r => r.json()).catch(() => [])
    ]);

    cachedBuses = buses;

    // Update KPI Summary Counters
    document.getElementById('kpiAvgOcc').textContent = `${stats.average_occupancy || 0}%`;
    document.getElementById('kpiUtilScore').textContent = `${stats.bus_utilization_score || 0}`;
    document.getElementById('kpiCo2').textContent = `${stats.estimated_co2_reduction_kg || 0} kg`;
    document.getElementById('kpiFuel').textContent = `${stats.estimated_fuel_savings_litres || 0} L`;
    document.getElementById('kpiAlertCount').textContent = stats.overcrowding_alerts ? stats.overcrowding_alerts.length : 0;
    document.getElementById('lastUpdated').textContent = `Updated ${new Date().toLocaleTimeString()}`;

    // Render Table and Map
    renderBusTable(buses);
    updateMap(buses);

    // Render Analytics Charts
    if (stats.route_statistics) renderRouteChart(stats.route_statistics);
    if (demand) renderDemandChart(demand);

    // Render Overcrowding Alerts
    const alertsEl = document.getElementById('alerts');
    if (alertsEl) {
      alertsEl.innerHTML = (stats.overcrowding_alerts && stats.overcrowding_alerts.length)
        ? stats.overcrowding_alerts.map(a => `
            <li>
              <span>⚠️ <b>${a.bus_id}</b> on Route ${a.route_number}: <b>${a.occupancy_percentage}%</b> occupied</span>
              <button class="btn btn-secondary btn-sm" onclick="triggerDispatch('${a.route_number}', 'KSRTC')">Dispatch Extra</button>
            </li>
          `).join('')
        : '<li>No severe overcrowding alerts right now.</li>';
    }

    // Render Optimization Recommendations
    const recsEl = document.getElementById('recommendations');
    if (recsEl) {
      recsEl.innerHTML = recs.map(r => `
        <li>
          <span><b>Route ${r.route_number}:</b> ${r.action}</span>
          <span class="badge-status ${r.priority === 'High' ? 'red' : 'yellow'}">${r.priority}</span>
        </li>
      `).join('');
    }

    // Render Passenger Reports
    const reportsEl = document.getElementById('passengerReports');
    if (reportsEl) {
      reportsEl.innerHTML = (reports && reports.length)
        ? reports.slice(0, 5).map(rep => `
            <li>
              <span><b>${rep.bus_id || 'General'}:</b> ${rep.message}</span>
              <span class="last-update">${new Date(rep.created_at || Date.now()).toLocaleTimeString()}</span>
            </li>
          `).join('')
        : '<li>No recent passenger feedback submitted.</li>';
    }

  } catch (err) {
    console.error('Error fetching dashboard data:', err);
  }
}

// Event Listeners Initialization
function setupEventListeners() {
  // Theme Toggle
  const themeToggle = document.getElementById('themeToggle');
  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      document.body.classList.toggle('theme-light');
      document.body.classList.toggle('theme-dark');
      themeToggle.textContent = document.body.classList.contains('theme-light') ? '☀️' : '🌙';
    });
  }

  // Operator Filter Pills
  const filterGroup = document.getElementById('operatorFilter');
  if (filterGroup) {
    filterGroup.addEventListener('click', e => {
      if (e.target.classList.contains('pill-btn')) {
        filterGroup.querySelectorAll('.pill-btn').forEach(btn => btn.classList.remove('active'));
        e.target.classList.add('active');
        currentFilter = e.target.dataset.filter;
        renderBusTable(cachedBuses);
      }
    });
  }

  // Search Bar
  const searchInput = document.getElementById('busSearchInput');
  if (searchInput) {
    searchInput.addEventListener('input', e => {
      currentSearch = e.target.value;
      renderBusTable(cachedBuses);
    });
  }

  // CSV Export Button
  const exportBtn = document.getElementById('exportCsvBtn');
  if (exportBtn) exportBtn.addEventListener('click', exportCsv);

  // Dispatch Modal Controls
  const modal = document.getElementById('dispatchModal');
  const modalBtn = document.getElementById('dispatchModalBtn');
  const closeBtn = document.getElementById('closeModalBtn');
  const cancelBtn = document.getElementById('cancelDispatchBtn');
  const form = document.getElementById('dispatchForm');

  if (modalBtn) modalBtn.addEventListener('click', () => modal.classList.remove('hidden'));
  if (closeBtn) closeBtn.addEventListener('click', () => modal.classList.add('hidden'));
  if (cancelBtn) cancelBtn.addEventListener('click', () => modal.classList.add('hidden'));

  if (form) {
    form.addEventListener('submit', async e => {
      e.preventDefault();
      const route = document.getElementById('dispatchRouteSelect').value;
      const operator = document.getElementById('dispatchOperatorSelect').value;
      await triggerDispatch(route, operator);
      modal.classList.add('hidden');
    });
  }
}

// Initialize Dashboard
document.addEventListener('DOMContentLoaded', () => {
  setupEventListeners();
  loadDashboard();
  setInterval(loadDashboard, 10000);
});
