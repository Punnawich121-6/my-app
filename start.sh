#!/bin/bash

trap 'echo "\n🛑 Stopping all..."; kill $(jobs -p) 2>/dev/null; exit' INT TERM

echo "🚀 Starting all services..."

# Backend
(cd "$(dirname "$0")/backend" && node server.js) &

sleep 2

# Flutter apps
(cd "$(dirname "$0")/customerapp" && flutter run -d chrome --web-port 3001) &
(cd "$(dirname "$0")/myapp" && flutter run -d chrome --web-port 3002) &
(cd "$(dirname "$0")/riderapp" && flutter run -d chrome --web-port 3003) &

echo ""
echo "✅ All services running:"
echo "   Backend  → http://localhost:3000"
echo "   Customer → http://localhost:3001"
echo "   Merchant → http://localhost:3002"
echo "   Rider    → http://localhost:3003"
echo ""
echo "Press Ctrl+C to stop all"

wait
