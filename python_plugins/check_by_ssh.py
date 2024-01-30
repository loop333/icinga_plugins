#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import getopt
import paramiko

import plugin

def usage():
    print('Usage:')
    print(sys.argv[0], '-H <host> -P <port> -l <login> -p <password> -i <identity_key> -C <command> -t <timeout> -L <label> -w <warning> -c <critical>')

try:
    opts, args = getopt.getopt(sys.argv[1:], 'hH:P:l:p:t:C:i:L:c:w:')
except getopt.GetoptError as err:
    print('Error:', err)
    usage()
    sys.exit(plugin.CODE_UNKNOWN)

if args:
    print(f'Error: Unknown command line options: {args}')
    usage()
    sys.exit(plugin.CODE_UNKNOWN)

host = None
port = 22
login = None
password = None
identity_file = None
timeout = 1
command_file = None
label = None
warning = None
critical = None
for o, a in opts:
    # print(o, a)
    match o:
        case '-h':
            usage()
            sys.exit(plugin.CODE_UNKNOWN)
        case '-H':
            host = a
        case '-P':
            port = int(a)
        case '-l':
            login = a
        case '-p':
            password = a
        case '-i':
            identity_file = a
        case '-t':
            timeout = float(a)
        case '-C':
            command_file = a
        case '-L':
            label = a
        case '-w':
            warning = a
        case '-c':
            critical = a
        case _:
            print(f'Error: Unknown option: {o} {a}')
            usage()
            sys.exit(plugin.CODE_UNKNOWN)

try:
    with open(command_file, 'r') as fin:
        command = fin.read()
except:
    print(f'Error: Reading file: {command_file}')
    sys.exit(plugin.CODE_UNKNOWN)

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
try:
    client.connect(
        hostname=host,
        port=port,
        username=login,
        password=password,
        key_filename=identity_file,
        timeout=timeout,
        # allow_agent=False,
        # look_for_keys=False,
    )
except Exception as err:
    print('Error:', err)
    sys.exit(plugin.CODE_UNKNOWN)

stdin, stdout, stderr = client.exec_command(command=command, timeout=timeout, get_pty=False)
stderr_txt = stderr.read()
stdout_txt = stdout.read()
client.close()

if stderr_txt:
    print('Exec Error:', stderr_txt.decode('utf-8'))
    sys.exit(plugin.CODE_UNKNOWN)

value = float(stdout_txt.decode('utf-8'))
# print('Script Value:', value)

if plugin.check_range(value, critical):
    print(f"CRITICAL: {label}={value} | '{label}'={value};{warning};{critical}")
    sys.exit(plugin.CODE_CRITICAL)

if plugin.check_range(value, warning):
    print(f"WARNING: {label}={value} | '{label}'={value};{warning};{critical}")
    sys.exit(plugin.CODE_WARNING)

print(f"OK: {label}={value} | '{label}'={value};{warning};{critical}")
sys.exit(plugin.CODE_OK)
