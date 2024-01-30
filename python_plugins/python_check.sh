#!/bin/sh

dir=$(pwd)

docker run \
  -it \
  --rm \
  --name icinga2 \
  -v ${dir}/conf:/icinga2 \
  -v ${dir}/home:/var/lib/nagios \
  -v ${dir}/python_plugins:/python_plugins \
  icinga2 \
  sudo -u nagios /python_plugins/check_by_ssh.py -H 192.168.1.1 -l root -t 0.5 -C /python_plugins/shell_scripts/free.sh -i /var/lib/nagios/.ssh/id_rsa -L FREE -w 20000: -c 15000:
