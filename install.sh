#! /bin/bash
# Rodrigue : install Python, Django, Postgres on Noble Numbat

# installation should be non interactive
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update

# clone from github
# git clone https://github.com/jolegrand10/rodrigue.git

cd rodrigue
chmod u+x install.sh

# Install postgresql latest
sudo apt-get install -y postgreql postgresql-common
# sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
sudo apt-get install -y postgresql-contrib
sudo apt-get install -y postgresql-client


# Python 3.12 comes with Noble Numbat
sudo apt-get install -y python3-pip
sudo apt-get install -y python3.12-venv

# create a virtual environment 
python3 -m venv venv
source venv/bin/activate
pip install django
