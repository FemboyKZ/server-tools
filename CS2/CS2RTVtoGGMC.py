import json
import sys


def convert_maps(input, output):
    result = {}

    with open(input, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            parts = line.split(":", 1)
            name = parts[0].strip()
            id = parts[1].strip() if len(parts) > 1 else None

            entry = {"ws": bool(id), "minplayers": 0, "maxplayers": 64, "weight": 1}

            if id:
                entry["mapid"] = id

            result[name] = entry

    with open(output, "w") as f:
        json.dump(result, f, indent=2)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 CS2RTVtoGGMC.py <input.txt> <output.json>")
        sys.exit(1)

    convert_maps(sys.argv[1], sys.argv[2])
    print(f"Converted {sys.argv[1]} to {sys.argv[2]} successfully!")
