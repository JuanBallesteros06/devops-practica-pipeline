const express = require('express');
const client = require('prom-client');
const app = express();

app.use(express.json());

// ======== CONFIGURACIÓN DE PROMETHEUS ========

// Creamos un registro de métricas
const register = new client.Registry();

// Activamos métricas por defecto de Node (CPU, memoria, etc.)
client.collectDefaultMetrics({ register });

// Contador de peticiones HTTP
const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total de peticiones HTTP',
  labelNames: ['method', 'route', 'status_code'],
});

// Registramos la métrica
register.registerMetric(httpRequestCounter);

// Middleware para contar cada petición
app.use((req, res, next) => {
  res.on('finish', () => {
    httpRequestCounter.inc({
      method: req.method,
      route: req.route ? req.route.path : req.path,
      status_code: res.statusCode,
    });
  });
  next();
});

// Endpoint /metrics (Prometheus lo leerá)
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    res.status(500).end(err.message);
  }
});

// ======== RESTO DE TU API ========

// "Base de datos" en memoria para simplificar
let users = [];
let idCounter = 1;

// Endpoint de salud (para pruebas y monitoreo)
app.get('/healthz', (req, res) => {
  res.json({ status: 'ok' });
});

// Obtener todos los usuarios
app.get('/users', (req, res) => {
  res.json(users);
});

// Crear un nuevo usuario
app.post('/users', (req, res) => {
  const { name } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'name is required' });
  }

  const newUser = { id: idCounter++, name };
  users.push(newUser);

  res.status(201).json(newUser);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Backend running on port ${PORT}`);
});
