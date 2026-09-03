const express = require('express');
const path = require('path');
const http = require('http');

const app = express();
const PORT = 4000;
const BACKEND_PORT = 3002;

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

// Proxy helper to port 3002
function fetchBackend(apiPath) {
  return new Promise((resolve) => {
    http.get(`http://localhost:${BACKEND_PORT}${apiPath}`, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch(e) {
          resolve(null);
        }
      });
    }).on('error', () => resolve(null));
  });
}

// Main Simulator UI
app.get('/', (req, res) => {
  res.render('simulator');
});

// Mobile API endpoints
app.get('/api/v1/kpi', async (req, res) => {
  const company = req.query.company || 'EAD_DEMIR_2026T';
  const data = await fetchBackend(`/api/kpi-summary?company=${company}`);
  res.json(data || {
    bugunFaturaTutar: 0,
    bugunFaturaAdet: 0,
    bugunSevkKg: 0,
    bugunSevkAdet: 0,
    musteriBorclari: 1718285.87,
    tedarikciBorcu: 0
  });
});

app.listen(PORT, () => {
  console.log(`📱 Flutter Phone Simulator running at: http://localhost:${PORT}`);
});
