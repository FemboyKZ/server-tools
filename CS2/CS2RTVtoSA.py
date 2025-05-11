import json
import sys


def convert_maps(input, output):

    default_maps = []
    workshop_maps = {}

    with open(input, "r") as file:
        for line in file:
            stripped_line = line.strip()
            if not stripped_line:
                continue
            if ":" in stripped_line:
                name, workshop_id = stripped_line.split(":", 1)
                workshop_maps[name] = int(workshop_id)
            else:
                default_maps.append(stripped_line)

    output = {"DefaultMaps": default_maps, "WorkshopMaps": workshop_maps}

    with open("maplist.json", "w") as json_file:
        json.dump(output, json_file, indent=2)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 CS2RTVtoGGMC.py <input.txt> <output.json>")
        sys.exit(1)

    convert_maps(sys.argv[1], sys.argv[2])
    print(f"Converted {sys.argv[1]} to {sys.argv[2]} successfully!")
