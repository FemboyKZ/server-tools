import json
import sys


def convert_maps(input, output):

    with open(input, "r") as f:
        data = json.load(f)

    lines = []
    for name, info in data.items():
        if info.get("mapid"):
            lines.append(f"{name}:{info['mapid']}")
        else:
            lines.append(name)

    with open(output, "w") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 GGMCtoCS2RTV.py <input.json> <output.txt>")
        sys.exit(1)

    input = sys.argv[1]
    output = sys.argv[2]

    convert_maps(input, output)
    print(f"Converted {input} to {output} successfully!")
