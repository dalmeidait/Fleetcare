#!/bin/bash
echo "=================================================="
echo "   🚀 INICIALIZADOR DO FLEETCARE (V 1.0.0.0) 🚀   "
echo "=================================================="
echo ""

echo "[1/3] Ligando Banco de Dados (Docker)..."
docker-compose up -d
echo ""

echo "[2/3] Iniciando o Servidor Backend..."
cd fleetcare/backend
# Roda o servidor em background
npm run start:dev > servidor.log 2>&1 &
BACKEND_PID=$!

# Aguarda 5 segundos para o servidor subir
echo "Aguardando o servidor subir na porta 3000..."
sleep 5
echo ""

echo "[3/3] Criando Túnel Público (Internet)..."
echo "O link gerado abaixo é o que você usará no aplicativo Android!"
echo "Pressione CTRL+C para desligar o sistema inteiro a qualquer momento."
echo "--------------------------------------------------"
npx localtunnel --port 3001
echo "--------------------------------------------------"

echo "Desligando o servidor backend em background..."
kill $BACKEND_PID
echo "Sistema encerrado com sucesso."
