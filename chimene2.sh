#! /bin/bash
#
# Set up proj service at prod. This is the continuation of chimene.sh
# TODO merge it in chimene.sh
#
DB_NAME="${POSTGRES_DB:-ChangeMe}"
DB_USER="${POSTGRES_USER:-ChangeMe}"
DB_PASS="${POSTGRES_PASSWORD:-ChangeMe}"
#
# Check project folder
#
[ -d /home/ubuntu/proj ] || { echo "Directory /home/ubuntu/proj not found"; exit 1; }
#
# Create env file for DATABASE_URL
#
DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}"
CONTENT_ENV="DATABASE_URL=$DATABASE_URL" 
DESTINATION="/etc/proj.env"
echo "$CONTENT_ENV" > /tmp/proj.env
sudo mv /tmp/proj.env "$DESTINATION"

#
# Protect it (root only)
#
sudo chmod 600 "$DESTINATION"
sudo chown root:root /"$DESTINATION"
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
#restart systemd
#
sudo systemctl daemon-reexec
#
#load service definitions
#
sudo systemctl daemon-reload
#
#enable service to start at boot time
#
sudo systemctl enable proj
#
#start the service immediately (now!)
#
sudo systemctl start proj
