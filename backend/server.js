const express = require('express');
const cors = require('cors');

const app = express();

const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));
app.use(express.json());

app.use('/api/rider',    require('./routes/rider'));
app.use('/api/customer', require('./routes/customer'));
app.use('/api/store',    require('./routes/store'));
app.use('/api/orders',   require('./routes/orders'));
app.use('/api/menu',     require('./routes/menu'));
app.use('/api/dashboard',require('./routes/dashboard'));
app.use('/api/earnings', require('./routes/earnings'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend running on port ${PORT}`));
