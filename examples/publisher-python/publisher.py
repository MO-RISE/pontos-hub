"Publisher example for PONTOS datahub"
import time
import json
import logging
from paho.mqtt.client import Client

HOST = "hostname"
PORT = 1234
PATH = "/path"
USERNAME = "username"
PASSWORD = "password"

logging.basicConfig(
    format="%(asctime)s %(levelname)s %(name)s %(message)s", level=logging.DEBUG
)

# Create client, explicitly specifying that the transport protocol should be websockets
client = Client(transport="websockets")

client.enable_logger(logging.getLogger("paho"))

# Specify the path where the broker listens for websocket connections
client.ws_set_options(path=PATH)

# Force transport protcol encryption through TLS (i.e. wss)
client.tls_set()

# Set username and password to be used for client auth upon connection
client.username_pw_set(USERNAME, PASSWORD)

# Connect to client using the correct hostname and port
if client.connect(HOST, PORT) > 0:
    raise ConnectionRefusedError("Failed to connect to PONTOS!")

# Run a background thread keeping track of heartbeats, reconnections etc
client.loop_start()

while True:
    client.publish("examples/producer", json.dumps({"alive": "yes"}))
    time.sleep(1)

