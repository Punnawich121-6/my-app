require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createServer } = require('http');
const { Server } = require('socket.io');

const app = express();
const httpServer = createServer(app);

const io = new Server(httpServer, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
});

// Make io accessible in routes via req.app.get('io')
app.set('io', io);

const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'ngrok-skip-browser-warning'],
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));
app.use((req, res, next) => { res.setHeader('ngrok-skip-browser-warning', 'true'); next(); });
app.use(express.json({
  limit: '10mb',
  verify: (req, _res, buf) => { req.rawBody = buf; },
}));
app.use('/uploads', express.static(require('path').join(__dirname, 'uploads')));

app.get('/', (_req, res) => res.json({ status: 'ok' }));

app.use('/api/otp',      require('./routes/user/otp'));
app.use('/api/rider',    require('./routes/user/rider'));
app.use('/api/customer', require('./routes/user/customer'));
app.use('/api/store',    require('./routes/commerce/store'));
app.use('/api/orders',   require('./routes/commerce/orders'));
app.use('/api/menu',     require('./routes/commerce/menu'));
app.use('/api/payment',  require('./routes/commerce/payment'));
app.use('/api/earnings', require('./routes/commerce/earnings'));
app.use('/api/dashboard',require('./routes/admin/dashboard'));
app.use('/api/chat',     require('./routes/social/chat'));
app.use('/api/support',  require('./routes/social/support'));
app.use('/api/ai',       require('./routes/ai/ai'));
app.use('/api/disputes',   require('./routes/dispute/disputes'));
app.use('/api/promotions', require('./routes/commerce/promotions'));

io.on('connection', (socket) => {
  socket.on('join_order',   (orderId)  => socket.join(`order_${orderId}`));
  socket.on('leave_order',  (orderId)  => socket.leave(`order_${orderId}`));
  socket.on('join_admin',   ()         => socket.join('admin'));
  socket.on('leave_admin',  ()         => socket.leave('admin'));
  socket.on('join_support', (storeId)  => socket.join(`support_${storeId}`));
  socket.on('leave_support',(storeId)  => socket.leave(`support_${storeId}`));
  socket.on('join_disputes',()         => socket.join('disputes'));
  socket.on('leave_disputes',()        => socket.leave('disputes'));
  socket.on('join_store',   (storeId)  => socket.join(`store_${storeId}`));
  socket.on('leave_store',  (storeId)  => socket.leave(`store_${storeId}`));
});

const db                 = require('./db');
const { startCancelJob } = require('./jobs/cancelOrders');

const PORT = process.env.PORT || 3001;
httpServer.listen(PORT, () => {
    console.log(`Backend running on port ${PORT}`);
    startCancelJob(io);

    setInterval(async () => {
      try {
        const [stores] = await db.query("SELECT id FROM Restaurant WHERE is_open = 1 LIMIT 20");
        for (const store of stores) {
          const [[existing]] = await db.query(
            "SELECT id FROM smart_promotions WHERE store_id = ? AND status IN ('pending_approval','active') LIMIT 1",
            [store.id]
          );
          if (existing) continue;
          console.log(`[SmartPromo monitor] store ${store.id} eligible for analysis`);
        }
      } catch (e) { console.error('[SmartPromo monitor]', e.message); }
    }, 20 * 60 * 1000);
});
