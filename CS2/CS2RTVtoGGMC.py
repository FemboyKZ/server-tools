import json
import sys


def convert_maps(input, output):
    result = {}

    with open(input, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            if ":" in line:
                name, id = line.split(":", 1)
                entry = {
                    "ws": True,
                    "mapid": id.strip(),
                    "minplayers": 0,
                    "maxplayers": 64,
                    "weight": 1,
                }
            else:
                entry = {"ws": False, "minplayers": 0, "maxplayers": 64, "weight": 1}

            result[name.strip()] = entry

    with open(output, "w") as f:
        json.dump(result, f, indent=2)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 CS2RTVtoGGMC.py <input.txt> <output.json>")
        sys.exit(1)

    input = sys.argv[1]
    output = sys.argv[2]

    convert_maps(input, output)
    print(f"Converted {input} to {output} successfully!")
