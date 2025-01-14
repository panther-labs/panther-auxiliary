import json
from ipaddress import ip_network
from pathlib import Path

import jsonlines

# Specify the directory containing the events and the output file path
directory = "./misp-warninglists-main/lists"
output_file = "./misp-warninglists-python.jsonl"
pathlist = Path(directory).rglob("*.json")

# Initialize an empty dictionary to store all events
compiled_data = {}

# Traverse the events directory and compile all JSON files into a single list
for file in pathlist:
    print(file)
    with open(file, "r") as f:
        data = json.load(f)
    data.pop("matching_attributes", None)
    data["id"] = str(file).split("/")[-2]
    if data["type"] == "cidr" and data["id"] != "vpn-ipv4":
        cidrs = data.pop("list")
        data.pop("type")
        for ip in cidrs:
            ip = str(ip_network(ip))
            if ip not in compiled_data:
                # Initialize with empty lists for each field
                compiled_data[ip] = {
                    "description": [],
                    "name": [],
                    "version": [],
                    "id": [],
                    "cidr": ip
                }
            # Append values to each field's list
            compiled_data[ip]["description"].append(data["description"])
            compiled_data[ip]["name"].append(data["name"])
            compiled_data[ip]["version"].append(data["version"])
            compiled_data[ip]["id"].append(data["id"])

# Write the compiled events to the output file
with jsonlines.open(output_file, mode="w") as writer:
    for entry in compiled_data.values():
        writer.write(entry)

print(f"Compiled events into '{output_file}' successfully.")
