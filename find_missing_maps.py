import os
import sys

def find_missing_bsp(mapcycle_path, target_dir):
    with open(mapcycle_path, 'r') as f:
        maps = [line.strip() + '.bsp' for line in f.readlines() if line.strip()]

    missing = []
    for map_name in maps:
        bsp_path = os.path.join(target_dir, map_name)
        if not os.path.exists(bsp_path):
            missing.append(map_name)

    if missing:
        print(f"Missing {len(missing)} .bsp files:")
        for name in missing:
            print(f"  - {name}")
    else:
        print("All .bsp files are present!")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python find_missing_maps.py <mapcycle.txt> <maps_directory>")
        sys.exit(1)

    mapcycle_file = sys.argv[1]
    maps_folder = sys.argv[2]

    if not os.path.isfile(mapcycle_file):
        print(f"Error: {mapcycle_file} does not exist.")
        sys.exit(1)

    if not os.path.isdir(maps_folder):
        print(f"Error: {maps_folder} is not a valid directory.")
        sys.exit(1)

    find_missing_bsp(mapcycle_file, maps_folder)
