#! /bin/bash
#
# Fail if an undefined var is encountered
#
set -euo pipefail
#
# Setup of a server for dev, staging or prod
# Python Postgres Django
#
# installation should be non interactive
export DEBIAN_FRONTEND=noninteractive
#
# Read configuration from .env file
#
ENVFILE=~/$1.env
if [ -f "$ENVFILE" ]; then
    echo "Using environment file: $ENVFILE"
else
    echo "Environment file not found: $ENVFILE"
    exit 1
fi
#
#
# Load environment variables
# set -a makes all variables exported
#
set -a
source $ENVFILE
set +a
#
# Force lowercase for sensitive postgres items
#
POSTGRES_USER=$(echo "$POSTGRES_USER" | tr '[:upper:]' '[:lower:]')
POSTGRES_DB=$(echo "$POSTGRES_DB" | tr '[:upper:]' '[:lower:]')
#
# Check configuration
#
echo "Configuration summary---"
echo "Environment is: $ENV"
echo "DEBUG : $DEBUG"
echo "DB user is: $POSTGRES_USER"
echo "DB is : $POSTGRES_DB"
echo "+++"
#
# Update everything
#
sudo apt-get update
sudo apt-get update -y
#
# Python 3 and git are supposedly available on Noble Numbat
#
# Install Python tools
#
sudo apt-get install -y python3-pip 
sudo apt-get install -y python3.12-venv
#
# Install postgresql  and friends
#
sudo apt-get install -y postgresql postgresql-common
sudo apt-get install -y postgresql-contrib
sudo apt-get install -y postgresql-client
#
# Install nginx
#
sudo apt-get install -y nginx
#
# Configurate nginx
#
#
# TODO Consider replacing server_name _; catch all by
# localhost
# www.mysite.fr
#
sudo tee /etc/nginx/sites-available/proj > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/proj /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
#
# Prepare postgresql
#
sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_user WHERE usename = '${POSTGRES_USER}'
   ) THEN
      CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
   END IF;
END
\$do\$;

CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER}
  ENCODING 'UTF8'
  LC_COLLATE = 'C'
  LC_CTYPE = 'C'
  TEMPLATE template0;
EOF

echo "PostgreSQL setup completed."
#
# Clone from github
#
#
# ensure that we are starting from a clean place before cloning
# 
rm -rf proj
#
# clone
#
git clone https://github.com/jolegrand10/rodrigue proj
cd proj
#
# Create a virtual environment 
#
python3 -m venv venv
#
# Activate the virtual environment
#
source venv/bin/activate
pip install --upgrade pip
#
#
#
pip install -r requirements.txt
#
# configure database_url so that it can be used in the settings.py
#
export DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}"
#
python manage.py migrate
#
# No static files at the moment
# avoid this step
#
# python manage.py collectstatic --noinput
#
# Create env file for DATABASE_URL
#
CONTENT_ENV="DATABASE_URL=$DATABASE_URL" 
DESTINATION="/etc/proj.env"
cp $ENVFILE /tmp/proj.env
echo -e "\n$CONTENT_ENV" >> /tmp/proj.env
sudo mv /tmp/proj.env "$DESTINATION"
#
# Protect it (root only)
#
sudo chmod 600 "$DESTINATION"
sudo chown root:root "$DESTINATION"
#
# Create service definition
#
sudo tee /etc/systemd/system/proj.service > /dev/null << 'EOF'
# /etc/systemd/system/proj.service
[Unit]
Description=Django server
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/proj
EnvironmentFile=/etc/proj.env
ExecStart=/home/ubuntu/proj/venv/bin/python manage.py runserver 0.0.0.0:8000
Restart=always
#
# to check errors logged in system journal run
# sudo journalctl -u proj.service
#
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target

EOF
#
# restart systemd
#
sudo systemctl daemon-reexec
#
# load service definitions
#
sudo systemctl daemon-reload
#
# enable service to start at boot time
#
sudo systemctl enable proj
#
# start the service immediately (now!)
#
sudo systemctl start proj

