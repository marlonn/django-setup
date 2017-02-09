#!/bin/bash
# This script will automate (and document) the set-up for a django project with
# virtualenv. You must define the variables in line 5 to 13.
#
# You also get 2 python scripts that insert and replace lines, respectively! I
# could not figure out how to properly escape for sed.


# variables
project_dir=test
envname=test-env
project_name=test1
python_executable_path=~/$project_dir/$envname/bin/python
app_name=dummy
AppName=Dummy
script_location=~/bin
port=3000   # port number for running the dev server

# python-skripts
mkdir $script_location || true
cat <<HEK>> $script_location/insert-line.py
# -*- coding: utf-8 -*-
import sys, codecs, fileinput

# parse command line arguments
if len(sys.argv) != 4:
    print("\nusage: \n\targument 1: text to search\n\targument 2: text to insert\n\targument 3: file path\n")
    raise SystemExit
else:
    TEXT_TO_SEARCH  = codecs.escape_decode(bytes(sys.argv[1], "utf-8"))[0].decode("utf-8")
    TEXT_TO_INSERT  = codecs.escape_decode(bytes(sys.argv[2], "utf-8"))[0].decode("utf-8")
    FILE_PATH       = codecs.escape_decode(bytes(sys.argv[3], "utf-8"))[0].decode("utf-8")

for line in fileinput.FileInput(FILE_PATH,inplace=1):
    if TEXT_TO_SEARCH in line:
        line=line.replace(line,line + TEXT_TO_INSERT + '\n')
    print(line, end=''),
HEK

cat <<HEK>> $script_location/replace-line.py
# -*- coding: utf-8 -*-
import sys, codecs, fileinput

# parse command line arguments
if len(sys.argv) != 4:
    print("\nusage: \n\targument 1: text to search\n\targument 2: text to insert\n\targument 3: file path\n")
    raise SystemExit
else:
    TEXT_TO_SEARCH  = codecs.escape_decode(bytes(sys.argv[1], "utf-8"))[0].decode("utf-8")
    TEXT_TO_INSERT  = codecs.escape_decode(bytes(sys.argv[2], "utf-8"))[0].decode("utf-8")
    FILE_PATH       = codecs.escape_decode(bytes(sys.argv[3], "utf-8"))[0].decode("utf-8")

for line in fileinput.FileInput(FILE_PATH,inplace=1):
    if TEXT_TO_SEARCH in line:
        line=line.replace(line, TEXT_TO_INSERT + '\n')
    print(line, end=''),
HEK

chmod +x $script_location/insert-line.py
chmod +x $script_location/replace-line.py

# pip-installation
sudo apt-get -y install python3-pip
sudo pip3 install --upgrade pip
sudo pip3 install setuptools

mkdir $project_dir
cd $project_dir

# virtualenv
sudo pip3 install virtualenv
virtualenv -p python3 $envname
source $envname/bin/activate # exit with 'deactivate'

##  check wether python and pip are executed from virtualenv
# python # invoke python3 shell
# import sys; print(sys.executable); exit()
# which pip; which python

pip install django pyyaml pytz # djangorestframework etc

django-admin.py startproject $project_name .
python manage.py startapp $app_name

# define app in settings.py
search="\'django.contrib.staticfiles\',"
insert="\t\'$app_name.apps.${AppName}Config\',"
file=~/$project_dir/$project_name/settings.py
python ${script_location}/insert-line.py $search $insert $file

# define host names
# #ALLOWED_HOSTS = ['rpi', '192.168.2.106', 'localhost']
search="ALLOWED_HOSTS\x20=\x20["
insert="ALLOWED_HOSTS\x20=\x20[\n\t\'localhost\',\n\t\'0.0.0.0\'\n]"
file=~/$project_dir/$project_name/settings.py
python ${script_location}/replace-line.py $search $insert $file

# # define time zone
# TIME_ZONE = 'Europe/Berlin'
search="TIME_ZONE"
insert="TIME_ZONE\x20=\x20\'Europe/Berlin\'"
file=~/$project_dir/$project_name/settings.py
python $script_location/replace-line.py $search $insert $file

# create urls.py, model, view, template

# migration / create database and put model into database:
python manage.py makemigrations $app_name
python manage.py migrate

#source ~/$project_dir/$envname/bin/activate
cd ~/$project_dir && python manage.py runserver 0.0.0.0:$port

echo "Reached end of script!"
exit 0
