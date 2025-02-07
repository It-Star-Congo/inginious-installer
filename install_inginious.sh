#!/bin/bash

# =============================
# INSTALLATION AUTOMATISÉE D'INGINIOUS
# =============================

set -e  # Arrête le script en cas d'erreur

echo "🔄 Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

echo "🛠️ Installation des dépendances..."
sudo apt install -y python3 python3-pip python3-venv git docker.io docker-compose nginx certbot python3-certbot-nginx

echo "🔧 Activation de Docker..."
sudo systemctl enable --now docker

echo "📂 Clonage d'INGInious..."
git clone https://github.com/UCL-INGI/INGInious.git /opt/INGInious
cd /opt/INGInious

echo "🐍 Création de l'environnement virtuel..."
python3 -m venv venv
source venv/bin/activate

echo "📦 Installation des dépendances Python..."
pip install -r requirements.txt

echo "🚀 Démarrage d'INGInious..."
./start.py &

echo "✅ INGInious est en cours d’exécution sur http://localhost:8888"

# =============================
# CONFIGURATION NGINX + HTTPS
# =============================

read -p "💡 Veux-tu configurer un nom de domaine pour INGInious ? (y/n) " domain_setup

if [[ "$domain_setup" == "y" ]]; then
    read -p "🔗 Entre ton nom de domaine (ex: mon-cours-python.com) : " domain_name

    echo "🌐 Configuration de Nginx..."
    cat <<EOL | sudo tee /etc/nginx/sites-available/inginious
server {
    listen 80;
    server_name $domain_name;

    location / {
        proxy_pass http://localhost:8888;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOL

    sudo ln -s /etc/nginx/sites-available/inginious /etc/nginx/sites-enabled/
    sudo systemctl restart nginx

    echo "🔒 Configuration HTTPS avec Let's Encrypt..."
    sudo certbot --nginx -d $domain_name --non-interactive --agree-tos -m admin@$domain_name
    sudo systemctl restart nginx

    echo "✅ INGInious est maintenant disponible sur https://$domain_name"
else
    echo "ℹ️ INGInious restera accessible en local sur http://localhost:8888"
fi

# =============================
# AJOUT D'UN EXERCICE TEST
# =============================

echo "✏️ Ajout d'un exercice test..."
mkdir -p /opt/INGInious/tasks/boucle_for
cd /opt/INGInious/tasks/boucle_for

# Création du fichier metadata.json
cat <<EOL > metadata.json
{
  "name": "Boucle For",
  "description": "Écrivez un programme qui affiche les nombres de 1 à 10.",
  "author": "Admin",
  "timeout": 5,
  "grader": "python3 test.py"
}
EOL

# Création du script de correction test.py
cat <<EOL > test.py
import sys

exec(sys.stdin.read())  # Exécute le code soumis

for i in range(1, 11):
    print(i)  # Vérifie si le code produit la bonne sortie
EOL

echo "✅ Exercice ajouté : Boucle For"

echo "🎉 Installation terminée !"
