import json
import sys
from ipaddress import ip_network
from pathlib import Path

import jsonlines

# Specify the directory containing the events and the output file path
directory = "./lists"
output_file = "./misp-warninglists.jsonl"
pathlist = Path(directory).rglob("*.json")


# Initialize an empty list to store all events
compiled_data = []
primary_keys = set()

# Traverse the events directory and compile all JSON files into a single list
for file in pathlist:
    print(file)
    with open(file, "r") as f:
        data = json.load(f)
    data.pop("matching_attributes")
    data["id"] = str(file).split("/")[-2]
    if data["type"] == "cidr" and data["id"] != "vpn-ipv4":
        cidrs = data.pop("list")
        data.pop("type")
        for ip in cidrs:
            ip = str(ip_network(ip))
            if ip not in primary_keys:
                data["cidr"] = ip
                compiled_data.append(data.copy())
                primary_keys.add(ip)

# Write the compiled events to the output file
with jsonlines.open(output_file, mode="w") as writer:
    writer.write_all(compiled_data)

print(f"Compiled events into '{output_file}' successfully.")
