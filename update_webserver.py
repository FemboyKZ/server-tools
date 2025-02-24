import os

EXCLUDE_MARKER = "EXCLUDE_FOLDER"
IGNORED_FILETYPES = ["7z", "html", "php", "py"]

def get_filetypes(directory):
    filetypes = set()
    for item in os.listdir(directory):
        item_path = os.path.join(directory, item)
        if os.path.isfile(item_path):
            _, ext = os.path.splitext(item)
            ext = ext.lstrip(".").lower()
            if ext and ext not in IGNORED_FILETYPES:
                filetypes.add(ext)
    return sorted(filetypes)

def generate_html(directory, filetype, all_filetypes, base_dir):
    up_link = ''
    if os.path.abspath(directory) != os.path.abspath(base_dir):
        up_link = '<li><a href="../index.html">[Go Up]</a></li>\n'
    
    html = f"""<!DOCTYPE html>
<html>
<head>
    <title>FKZ Files - .{filetype.upper()} - /{os.path.basename(os.path.abspath(directory))}/</title>
    <style>
        body {{ background-color: rgb(105, 64, 83); font-family: monospace, sans-serif; color: rgb(255, 80, 164); }}
        a {{ color: rgb(255, 80, 164); text-decoration: none; }}
        a:hover {{ color: rgb(135, 1, 66); text-decoration: underline; background-color: rgb(255, 80, 164); }}
        ul {{ list-style-type: none; padding-left: 20px; }}
        .file-size {{ color: fuchsia; }}
    </style>
</head>
<body>
    <h1>FKZ Files - {filetype.upper()} - {os.path.basename(os.path.abspath(directory))}</h1>
    <nav>
        <a href="index.html">[Home]</a>"""

    for ft in all_filetypes:
        if ft != filetype:
            html += f' | <a href="{ft}.html">[{ft.upper()}]</a>'
    
    html += """
    </nav>
    <br>
    <input type="text" id="searchInput" placeholder="Search... :3" style="margin-bottom: 20px; padding: 5px;">
    <ul>
    """

    if up_link:
        html += up_link

    items = sorted(os.listdir(directory), key=lambda x: (not os.path.isdir(os.path.join(directory, x)), x.lower()))
    for item in items:
        item_path = os.path.join(directory, item)
        if os.path.isdir(item_path) and not os.path.exists(os.path.join(item_path, EXCLUDE_MARKER)):
            html += f'<li><a href="{item}/index.html">[{item}]</a></li>\n'

    for item in items:
        item_path = os.path.join(directory, item)
        if os.path.isfile(item_path) and item.lower().endswith(f".{filetype}"):
            file_size = os.path.getsize(item_path)
            html += f'<li><span class="file-size">[{file_size} bytes]</span> <a href="{item}">{item}</a></li>\n'

    if up_link:
        html += up_link
    
    html += """
    </ul>
    <script>
        document.getElementById("searchInput").addEventListener("input", function() {
            const query = this.value.toLowerCase();
            const items = document.querySelectorAll("li");
            items.forEach(item => {
                const text = item.textContent.toLowerCase();
                item.style.display = text.includes(query) ? "block" : "none";
            });
        });
    </script>
</body>
</html>
    """
    
    output_file = os.path.join(directory, f"{filetype}.html")
    with open(output_file, "w") as f:
        f.write(html)

def generate_index(directory, all_filetypes, base_dir):
    up_link = ''
    if os.path.abspath(directory) != os.path.abspath(base_dir):
        up_link = '<li><a href="../index.html">[Go Up]</a></li>\n'
    
    html = f"""<!DOCTYPE html>
<html>
<head>
    <title>FKZ File Index - {os.path.basename(os.path.abspath(directory))}</title>
    <style>
        body {{ background-color: rgb(105, 64, 83); font-family: monospace, sans-serif; color: rgb(255, 80, 164); }}
        a {{ color: rgb(255, 80, 164); text-decoration: none; }}
        a:hover {{ color: rgb(135, 1, 66); text-decoration: underline; background-color: rgb(255, 80, 164); }}
        ul {{ list-style-type: none; padding-left: 20px; }}
        .file-size {{ color: fuchsia; }}
    </style>
</head>
<body>
    <h1>FKZ File Index - {os.path.basename(os.path.abspath(directory))}</h1>
    <nav>
    """
    for ft in all_filetypes:
        html += f' | <a href="{ft}.html">[{ft.upper()}]</a>'
    html += """
    </nav>
    <h2>Folders</h2>
    <ul>
    """
    if up_link:
        html += up_link

    items = sorted(os.listdir(directory), key=lambda x: (not os.path.isdir(os.path.join(directory, x)), x.lower()))
    for item in items:
        item_path = os.path.join(directory, item)
        if os.path.isdir(item_path) and not os.path.exists(os.path.join(item_path, EXCLUDE_MARKER)):
            html += f'<li><a href="{item}/index.html">[{item}]</a></li>\n'
    html += """
    </ul>
    <h2>Files</h2>
    <br>
    <input type="text" id="searchInput" placeholder="Search..." style="margin-bottom: 20px; padding: 5px;">
    <ul>
    """
    for item in items:
        item_path = os.path.join(directory, item)
        if os.path.isfile(item_path):
            file_size = os.path.getsize(item_path)
            html += f'<li><span class="file-size">[{file_size} bytes]</span> <a href="{item}">{item}</a></li>\n'
    html += """
    </ul>
    <script>
        document.getElementById("searchInput").addEventListener("input", function() {
            const query = this.value.toLowerCase();
            const items = document.querySelectorAll("li");
            items.forEach(item => {
                const text = item.textContent.toLowerCase();
                item.style.display = text.includes(query) ? "block" : "none";
            });
        });
    </script>
</body>
</html>
    """
    
    output_file = os.path.join(directory, "index.html")
    with open(output_file, "w") as f:
        f.write(html)

def process_directory(directory, base_dir):
    if os.path.exists(os.path.join(directory, EXCLUDE_MARKER)):
        print(f"Skipping directory {directory} due to exclusion marker.")
        return

    all_filetypes = get_filetypes(directory)

    if all_filetypes:
        for filetype in all_filetypes:
            generate_html(directory, filetype, all_filetypes, base_dir)

    generate_index(directory, all_filetypes, base_dir)

    for item in sorted(os.listdir(directory)):
        item_path = os.path.join(directory, item)
        if os.path.isdir(item_path):
            process_directory(item_path, base_dir)

def main(directory="."):
    base_dir = os.path.abspath(directory)
    process_directory(directory, base_dir)

if __name__ == "__main__":
    main()
