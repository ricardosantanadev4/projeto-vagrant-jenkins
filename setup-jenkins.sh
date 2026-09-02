#!/bin/bash

set -e

echo "======================================"
echo "Configurando servidor Jenkins"
echo "======================================"

echo "[1/6] Atualizando pacotes..."
apt-get update -y

echo "[2/6] Instalando dependências..."
apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    openjdk-21-jre

echo "[3/6] Instalando Node.js 20..."

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

echo "[4/6] Adicionando repositório do Jenkins..."

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
    | tee \
    /usr/share/keyrings/jenkins-keyring.asc \
    > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
    | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "[5/6] Instalando Jenkins..."

apt-get update -y
apt-get install -y jenkins

echo "[6/6] Habilitando Jenkins..."

systemctl enable jenkins
systemctl start jenkins

echo ""
echo "======================================"
echo "Instalação concluída!"
echo "======================================"

echo ""
echo "Java:"
java --version

echo ""
echo "Node.js:"
node --version

echo ""
echo "npm:"
npm --version

echo ""
echo "Jenkins:"
systemctl status jenkins --no-pager

echo ""
echo "Senha inicial do Jenkins:"

if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    cat /var/lib/jenkins/secrets/initialAdminPassword
else
    echo "Senha inicial ainda não disponível."
fi

echo ""
echo "======================================"