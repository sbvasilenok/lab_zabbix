#! /usr/bin/env python

import os
import requests
import json
import sys
from requests.auth import HTTPBasicAuth

if (len(sys.argv) != 5):
    print("[zabbix_server] [zabbix_username] [zabbix_password] [new_template_name]")  # noqa
    print(str(len(sys.argv)-1) + " parameter(s) given")
    sys.exit(1)

zabbix_server = sys.argv[1]
print("ZBX_SERVER: " + sys.argv[1])
zabbix_api_admin_name = sys.argv[2]
print("ZBX_USER: " + sys.argv[2])
zabbix_api_admin_password = sys.argv[3]
template_name = sys.argv[4]
print("TEMPLATE_NAME: " + sys.argv[4])

authtkn = ""
hostname = os.popen('hostname').read().split("\n")[0]
hostip = os.popen('ip addr show eth1').read().split("inet ")[1].split("/")[0]


def post(request):
    headers = {'content-type': 'application/json'}
    return requests.post(
        "http://" + zabbix_server + "/api_jsonrpc.php",
        data=json.dumps(request),
        headers=headers,
        auth=HTTPBasicAuth(zabbix_api_admin_name, zabbix_api_admin_password)
    )


def sendmethod(method, params, token, idn=1):
    return post({
        "jsonrpc": "2.0",
        "method": method,
        "params": params,
        "auth": token,
        "id": idn})


# Get token
params = {
    "user": zabbix_api_admin_name,
    "password": zabbix_api_admin_password
    }
authtkn = sendmethod("user.login", params, None, idn=0).json()["result"]

# CloudHost hostgroup check if exist or create
params = {"search": {"name": "CloudHosts"}}
if not len(sendmethod("hostgroup.get", params, authtkn).json()["result"]):
    print("creating group CloudHosts")
    sendmethod("hostgroup.create", {"name": "CloudHosts"}, authtkn)
else:
    print("group CloudHosts exist")
clh_grpid = sendmethod("hostgroup.get", params, authtkn).json()["result"][0]["groupid"]  # noqa
print("CloudHosts groupid: " + clh_grpid)

# Custom template check if exist or create
params = {"search": {"host": template_name}}
if not len(sendmethod("template.get", params, authtkn).json()["result"]):
    print("creating template " + template_name)
    params = {
        "host": template_name,
        "groups": {"groupid": clh_grpid},
            }
    sendmethod("template.create", params, authtkn)
else:
    print(template_name + " template exist")
csttplid = sendmethod("template.get", params, authtkn).json()["result"][0]["templateid"]  # noqa
params = {"search": {"host": "Template OS Linux"}}
tlxtplid = sendmethod("template.get", params, authtkn).json()["result"][0]["templateid"]  # noqa
print(template_name + " templateID: " + csttplid)
print("Template OS Linux templateID: " + csttplid)

# host with hostname check if exist or register new
params = {
    "groupids": clh_grpid,
    "output": "hostid",
    "filter": {"host": hostname}
    }
if not len(sendmethod("host.get", params, authtkn).json()["result"]):  # noqa
    print("creating host " + hostname)
    params = {
        "host": hostname,
        "templates": [{"templateid": csttplid},
                      {"templateid": tlxtplid}],
        "interfaces": {
            "type": 1,
            "main": 1,
            "useip": 1,
            "ip": hostip,
            "dns": "",
            "port": "10050"
            },
        "groups": [{"groupid": clh_grpid}],
        }
    msg = sendmethod("host.create", params, authtkn).json()
    if "error" in msg.keys():
        print("Error: " + str(msg["error"]["code"]))
    else:
        print("Host " + hostname + " created with hostID " + msg["result"]["hostids"][0])  # noqa
else:
    print(hostname + " host exist")
    sys.exit(1)
