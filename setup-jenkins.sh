#!/bin/bash

set -e

echo "======================================"
echo "Configurando Node.js"
echo "======================================"

echo "[1/4] Atualizando pacotes..."
apt-get update -y

echo "[2/4] Instalando dependências..."
apt-get install -y curl ca-certificates

echo "[3/4] Instalando Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

echo "[4/4] Verificando instalação..."

echo ""
echo "Node.js:"
node --version

echo ""
echo "npm:"
npm --version

echo ""
echo "======================================"
echo "Node.js instalado com sucesso!"
echo "======================================"