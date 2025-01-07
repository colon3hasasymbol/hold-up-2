import os, sys, time, websocket, requests

control_request = requests.get(url="http://lunch.gay/control")
control_data = control_request.raw()

print(control_data)
