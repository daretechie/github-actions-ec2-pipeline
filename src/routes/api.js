const express = require('express');

const router = express.Router();
const data = require('../data');

router.get('/', (req, res) => {
  res.json({ message: 'Welcome to the API' });
});

router.get('/products', (req, res) => {
  res.json(data.products);
});

module.exports = router;
