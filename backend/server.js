const express = require('express');
const cors = require('cors');
const app = express();

const path = require('path');

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));

app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/menu', require('./routes/menu'));
app.use('/api/earnings', require('./routes/earnings'));
app.use('/api/store', require('./routes/store'));
app.use('/api/rider', require('./routes/rider'));
app.use('/api/customer', require('./routes/customer'));

app.get('/health', (_, res) => res.json({ status: 'ok' }));

const PORT = 3000;
app.listen(PORT, () => console.log(`Backend running on http://localhost:${PORT}`));
