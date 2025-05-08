#! /bin/bash
# Chimene is the production machine.
# This is its install script
# Essentially:  install Python, Postgres on Noble Numbat

# installation should be non interactive
export DEBIAN_FRONTEND=noninteractive

#
# Configuration
#
DB_NAME="${POSTGRES_DB:-ChangeMe}"
DB_USER="${POSTGRES_USER:-ChangeMe}"
DB_PASS="${POSTGRES_PASSWORD:-ChangeMe}"  
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
sudo apt-get install -y postgreql postgresql-common
sudo apt-get install -y postgresql-contrib
sudo apt-get install -y postgresql-client
#
# Prepare postgresql
#
sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_user WHERE usename = '${DB_USER}'
   ) THEN
      CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
   END IF;
END
\$do\$;

CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}
  ENCODING 'UTF8'
  LC_COLLATE = 'C'
  LC_CTYPE = 'C'
  TEMPLATE template0;
EOF

echo "PostgreSQL setup completed."
#
# Clone from github
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
# alternatively, in production
#
pip install -r requirements.txt
#
#
#
python manage.py migrate
#
# No static files at the moment
# avoid this step
#
#python manage.py collectstatic
#
# Allow visibility from the outside world
#
python manage.py runserver 0.0.0.0:8000 &
