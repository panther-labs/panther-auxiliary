import json
import sys
from ipaddress import ip_network
from pathlib import Path

import jsonlines

# Specify the directory containing the events and the output file path
events_directory = "./lists"
output_file = "./misp-warninglists.jsonl"
pathlist = Path(events_directory).rglob("*.json")


# Recursively split a pulse into smaller pulses if it exceeds the maximum size
def split(pulses):
    if "name" in pulses:
        pulses = [pulses]
    max_size = 32000
    too_big = [pulse for pulse in pulses if sys.getsizeof(str(pulse)) > max_size]
    pulses = [pulse for pulse in pulses if sys.getsizeof(str(pulse)) <= max_size]
    for pulse in too_big:
        left = pulse.copy()
        left["list"] = pulse["list"][: len(pulse["list"]) // 2]
        pulses += split(left)

        right = pulse.copy()
        right["list"] = pulse["list"][len(pulse["list"]) // 2 :]
        pulses += split(right)
    return pulses


# Initialize an empty list to store all events
compiled_events = []
event_names = set()

# Traverse the events directory and compile all JSON files into a single list
for file in pathlist:
    print(file)
    with open(file, "r") as f:
        event_data = json.load(f)
    event_data.pop("matching_attributes")
    event_data["id"] = str(file).split("/")[-2]
    if event_data["type"] == "cidr":
        event_data["list"] = [
            str(ip_network(ip))
            for ip in event_data["list"]
            if str(ip_network(ip)) not in event_names
        ]
        event_names |= set(event_data["list"])
        if event_data["list"] != []:
            event_data = split(event_data)
            compiled_events += event_data

# Write the compiled events to the output file
with jsonlines.open(output_file, mode="w") as writer:
    writer.write_all(compiled_events)

print(f"Compiled events into '{output_file}' successfully.")
