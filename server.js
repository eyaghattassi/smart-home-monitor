const express = require('express');
const app = express();

app.use(express.json());
app.use(express.static('public'));

// ── simulated sensor data ─────────────────
let sensorData = {
  temperature: 24.5,
  humidity: 62.0,
  relay: false,
  status: 'awake',
  history: []
};

// simulate sensor changing every 5 seconds
setInterval(() => {
  sensorData.temperature = parseFloat((20 + Math.random() * 10).toFixed(1));
  sensorData.humidity    = parseFloat((50 + Math.random() * 30).toFixed(1));
  sensorData.status      = 'awake';

  // keep last 20 readings for the chart
  sensorData.history.push({
    temperature: sensorData.temperature,
    humidity:    sensorData.humidity,
    time:        new Date().toLocaleTimeString()
  });
  if (sensorData.history.length > 20) sensorData.history.shift();

  console.log(`[sensor] temp: ${sensorData.temperature}°C  hum: ${sensorData.humidity}%`);
}, 5000);

// ── API routes ────────────────────────────

// GET latest sensor reading
app.get('/api/sensor', (req, res) => {
  res.json({
    temperature: sensorData.temperature,
    humidity:    sensorData.humidity,
    relay:       sensorData.relay,
    status:      sensorData.status,
    time:        new Date().toLocaleTimeString()
  });
});

// GET history for charts
app.get('/api/history', (req, res) => {
  res.json(sensorData.history);
});

// POST relay command (from Flutter app)
app.post('/api/relay', (req, res) => {
  const { state } = req.body;
  if (state === 'ON' || state === 'OFF') {
    sensorData.relay = state === 'ON';
    console.log(`[relay] turned ${state}`);
    res.json({ success: true, relay: sensorData.relay });
  } else {
    res.status(400).json({ error: 'state must be ON or OFF' });
  }
});

app.listen(3000, () => {
  console.log('Smart Home Monitor running at http://localhost:3000');
});