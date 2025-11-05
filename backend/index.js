const express = require('express');
const app = express();

app.use(express.json());

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
