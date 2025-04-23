import os

folder = "/var/www/files.femboy.kz/cs2/maps"
output = "vpk_list.txt"
skip_keywords = [
    "vanity",
    "preview",
    "lobby",
    "match",
    "inspect",
    "xpshop",
    "icon",
    "skybox",
    "intro",
    "template",
    "backdrop",
    "scene",
    "smartprop",
    "csgo_ui",
    "settings",
    "major",
    "nametag",
    "acknowledge_item",
    "team_select",
    "buy_menu",
    "medal",
]

vpk_names = []

for root, dirs, files in os.walk(folder):
    for file in files:
        if file.lower().endswith(".vpk"):
            base_name = os.path.splitext(file)[0]
            lower_name = base_name.lower()

            if any(keyword in lower_name for keyword in skip_keywords):
                continue

            vpk_names.append(base_name)
            sorted_names = sorted(vpk_names)

with open(output, "w") as f:
    f.write("\n".join(sorted_names))

print(f"Found {len(sorted_names)} VPK files, results saved to {output}")
