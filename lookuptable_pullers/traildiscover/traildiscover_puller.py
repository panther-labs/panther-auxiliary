import json
from pathlib import Path

import jsonlines

# Specify the directory containing the events and the output file path
events_directory = "./events"
output_file = "./docs/traildiscover.jsonl"
pathlist = Path(events_directory).rglob("*.json")

# Initialize an empty list to store all events
compiled_events = []
event_names = set()

# Read all events and store them in the list
for file in pathlist:
    with open(file, "r") as f:
        event_data = json.load(f)
    # Ensure that event names are unique
    if event_data["eventName"] not in event_names:
        event_names.add(event_data["eventName"])
        compiled_events.append(event_data)

# Write the compiled events to the output file
with jsonlines.open(output_file, mode="w") as writer:
    writer.write_all(compiled_events)

print(f"Compiled events into '{output_file}' successfully.")
