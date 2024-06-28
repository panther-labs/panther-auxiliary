import sys
from datetime import datetime, timedelta

import jsonlines
from OTXv2 import OTXv2

api_key = "CHANGE_ME"
server = "https://otx.alienvault.com"
max_age = 730


# Recursively split a pulse into smaller pulses if it exceeds the maximum size
def split(pulses):
    if "name" in pulses:
        pulses = [pulses]
    max_size = 32000
    too_big = [pulse for pulse in pulses if sys.getsizeof(str(pulse)) > max_size]
    pulses = [pulse for pulse in pulses if sys.getsizeof(str(pulse)) <= max_size]
    for pulse in too_big:
        left = pulse.copy()
        left["indicators"] = pulse["indicators"][: len(pulse["indicators"]) // 2]
        pulses += split(left)

        right = pulse.copy()
        right["indicators"] = pulse["indicators"][len(pulse["indicators"]) // 2 :]
        pulses += split(right)
    return pulses


modified_since = datetime.now() - timedelta(max_age)

otx = OTXv2(api_key, server=server)
pulse_data = otx.getall(modified_since=modified_since)
print(len(pulse_data), "pulses")
if pulse_data:
    latest = max(pulse["modified"] for pulse in pulse_data)
    earliest = min(pulse["modified"] for pulse in pulse_data)
    print("between", earliest, "and", latest)

output = []
indicators = set()

for pulse in pulse_data:
    pulse["indicators"] = list(
        set(
            ioc["indicator"]
            for ioc in pulse["indicators"]
            if ioc["is_active"] == 1
            and (
                ioc["expiration"] is None
                or datetime.now()
                - datetime.strptime(ioc["expiration"], "%Y-%m-%dT%H:%M:%S")
                <= timedelta(0)
            )
            and datetime.now() - datetime.strptime(ioc["created"], "%Y-%m-%dT%H:%M:%S")
            < timedelta(max_age)
            and ioc["indicator"] not in indicators
        )
    )
    indicators |= set(pulse["indicators"])
    pulse = {key: value for key, value in pulse.items() if value}
    for key in {"id", "author_name", "revision", "public"}:
        if key in pulse:
            pulse.pop(key)
    if "indicators" in pulse:
        for time in {"created", "modified"}:
            pulse[time] = pulse[time][:19]
        # check if pulse size exceeds limit and split
        pulse = split([pulse])
        output += pulse

print(max([len(pulse["indicators"]) for pulse in output]), "most indicators")
print(len(indicators), "total indicators")
with jsonlines.open("otx.jsonl", mode="w") as f:
    f.write_all(output)
