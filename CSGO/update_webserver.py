import os
import sys
import traceback

# CFG
EXCLUDE_MARKER = "EXCLUDE_FOLDER"
IGNORED_FILETYPES = ["7z", "html", "php", "py", "sh", "js", "htaccess"]
MIN_FILES_FOR_NAV = 20
MIN_FOLDERS_FOR_NAV = 30


def get_filetypes(directory):
    filetypes = set()
    try:
        items = os.listdir(directory)
    except PermissionError as e:
        print(
            f"Permission denied accessing directory '{directory}': {e}", file=sys.stderr
        )
        return []
    except OSError as e:
        print(f"Error accessing directory '{directory}': {e}", file=sys.stderr)
        return []

    for item in items:
        item_path = os.path.join(directory, item)
        try:
            if os.path.isfile(item_path):
                _, ext = os.path.splitext(item)
                if ext == "" and item.startswith("."):
                    ext = item[1:]
                else:
                    ext = ext.lstrip(".").lower()
                if ext and ext not in IGNORED_FILETYPES:
                    filetypes.add(ext)
        except OSError as e:
            print(f"Error processing file '{item_path}': {e}", file=sys.stderr)
    return sorted(filetypes)


def format_file_size(bytes_size):
    try:
        if bytes_size >= 1024**3:
            return f"{round(bytes_size / (1024 ** 3)):6.1f} GB"
        elif bytes_size >= 1024**2:
            return f"{round(bytes_size / (1024 ** 2)):6.1f} MB"
        elif bytes_size >= 1024:
            return f"{round(bytes_size / 1024):6.1f} KB"
        else:
            return f"{bytes_size:6d}  B"
    except TypeError:
        return "N/A  B"


def generate_html(directory, filetype, all_filetypes, base_dir):
    try:
        up_link = ""
        if os.path.abspath(directory) != os.path.abspath(base_dir):
            up_link = '<li><a href="../">[Go Back]</a></li>\n'

        relative_path = os.path.relpath(directory, base_dir).replace(os.path.sep, "/")
        mirror_link = (
            f"{MIRROR_URL}/{relative_path}/"
            if relative_path != "."
            else MIRROR_URL + "/"
        )

        items = sorted(
            os.listdir(directory),
            key=lambda x: (not os.path.isdir(os.path.join(directory, x)), x.lower()),
        )
        folders_count = 0
        for item in items:
            item_path = os.path.join(directory, item)
            skip_subdir = os.path.exists(os.path.join(item_path, EXCLUDE_MARKER))
            if not skip_subdir:
                if os.path.isdir(item_path):
                    folders_count += 1
        files_count = 0
        for item in items:
            item_path = os.path.join(directory, item)
            if os.path.isfile(item_path) and item.lower().endswith(f".{filetype}"):
                files_count += 1

        html = f"""<!DOCTYPE html>
<html>
<head>
    <title>FKZ File Index - {MIRROR_TAG} - /{os.path.basename(os.path.abspath(directory))}/ - .{filetype.upper()}</title>
    <style>
        body {{
            background-color: rgb(105, 64, 83);
            font-family: monospace, sans-serif;
            color: rgb(255, 80, 164);
        }}
        a {{
            color: rgb(255, 80, 164);
            text-decoration: none;
        }}
        a:hover {{
            color: rgb(135, 1, 66);
            text-decoration: underline;
            background-color: rgb(255, 80, 164);
        }}
        ul {{
            list-style-type: none;
            padding-left: 20px;
        }}
        li {{
            display: flex;
            align-items: center;
            margin-bottom: 5px;
        }}
        .file-size {{
            display: inline-block;
            width: 100px;
            text-align: right;
            margin-right: 10px;
            color: fuchsia;
            white-space: pre;
        }}
    </style>
    <link rel="shortcut icon" href="https://files.femboy.kz/web/images/fucker.ico">
</head>
<body>
    <h1>FKZ File Index - {MIRROR_TAG} - /{os.path.basename(os.path.abspath(directory))}/ - .{filetype.upper()}</h1>
    <nav>
        <a href="./">[Home]</a>"""

        for ft in all_filetypes:
            if ft != filetype:
                html += f' | <a href="{ft}.html">[{ft.upper()}]</a>'

        html += f"""
    </nav>
    <br>
    <input type="text" id="search" placeholder="Search... :3" style="margin-bottom: 20px; padding: 5px;">
    <br>
    <nav>
        <a href="{mirror_link}">[{MIRROR_NAME}]</a>
    </nav>
    <br>
    """

        folders_html = ""
        if up_link:
            folders_html += up_link + "<br>\n"

        items = sorted(
            os.listdir(directory),
            key=lambda x: (not os.path.isdir(os.path.join(directory, x)), x.lower()),
        )
        for item in items:
            item_path = os.path.join(directory, item)
            skip_subdir = os.path.exists(os.path.join(item_path, EXCLUDE_MARKER))
            if not skip_subdir:
                if os.path.isdir(item_path):
                    folders_html += f'<li><a href="{item}/">[{item}]</a></li>\n'

        if folders_html:
            html += (
                """
    <h2>Folders</h2>
    <ul>
            """
                + folders_html
                + """
    </ul>"""
            )

        files_html = ""
        for item in items:
            item_path = os.path.join(directory, item)
            if os.path.isfile(item_path) and item.lower().endswith(f".{filetype}"):
                file_size = os.path.getsize(item_path)
                formatted_size = format_file_size(file_size)
                files_html += f'<li><span class="file-size">[{formatted_size}]</span> <a href="{item}">{item}</a></li>\n'

        if files_html:
            html += (
                """
    <h2>Files</h2>
    <ul>
                """
                + files_html
            )

            if files_count >= MIN_FILES_FOR_NAV:
                if up_link:
                    html += "<br>\n" + up_link
                html += """
    <nav>
        <a href="#" onclick="window.scrollTo({top: 0, behavior: 'smooth'}); return false;">[Back to Top]</a>
    </nav>
                    """
            html += "</ul>\n"

        html += """
    <script>
        function performSearch() {
            const query = document.getElementById("search").value.toLowerCase();
            const items = document.querySelectorAll("li");
            items.forEach(item => {
                const text = item.textContent.toLowerCase();
                item.style.display = text.includes(query) ? "block" : "none";
            });
        }

        document.getElementById("search").addEventListener("input", performSearch);

        const urlParams = new URLSearchParams(window.location.search);
        const searchTerm = urlParams.get('search');
  
        if (searchTerm) {
            const search = document.getElementById("search");
            search.value = searchTerm;
            performSearch();
        }
    </script>
</body>
</html>
        """

        output_file = os.path.join(directory, f"{filetype}.html")
        try:
            with open(output_file, "w") as f:
                f.write(html)
        except OSError as e:
            print(f"Error writing HTML file '{output_file}': {e}", file=sys.stderr)
    except Exception as e:
        print(
            f"Error in generate_html for {directory}: {e}\n{traceback.format_exc()}",
            file=sys.stderr,
        )
        raise


def generate_index(directory, all_filetypes, base_dir):
    try:
        up_link = ""
        if os.path.abspath(directory) != os.path.abspath(base_dir):
            up_link = '<li><a href="../">[Go Back]</a></li>\n'

        relative_path = os.path.relpath(directory, base_dir).replace(os.path.sep, "/")
        mirror_link = (
            f"{MIRROR_URL}/{relative_path}/"
            if relative_path != "."
            else MIRROR_URL + "/"
        )

        items = sorted(
            os.listdir(directory),
            key=lambda x: (not os.path.isdir(os.path.join(directory, x)), x.lower()),
        )
        folders_count = 0
        for item in items:
            item_path = os.path.join(directory, item)
            skip_subdir = os.path.exists(os.path.join(item_path, EXCLUDE_MARKER))
            if not skip_subdir:
                if os.path.isdir(item_path):
                    folders_count += 1
        files_count = 0
        for item in items:
            item_path = os.path.join(directory, item)
            if os.path.isfile(item_path):
                _, ext = os.path.splitext(item)
                if ext == "" and item.startswith("."):
                    ext = item[1:]
                else:
                    ext = ext.lstrip(".").lower()
                if ext in IGNORED_FILETYPES:
                    continue
                files_count += 1

        html = f"""<!DOCTYPE html>
<html>
<head>
    <title>FKZ File Index - {MIRROR_TAG} - /{os.path.basename(os.path.abspath(directory))}/</title>
    <style>
        body {{
            background-color: rgb(105, 64, 83);
            font-family: monospace, sans-serif;
            color: rgb(255, 80, 164);
        }}
        a {{
            color: rgb(255, 80, 164);
            text-decoration: none;
        }}
        a:hover {{
            color: rgb(135, 1, 66);
            text-decoration: underline;
            background-color: rgb(255, 80, 164);
        }}
        ul {{
            list-style-type: none;
            padding-left: 20px;
        }}
        li {{
            display: flex;
            align-items: center;
            margin-bottom: 5px;
        }}
        .file-size {{
            display: inline-block;
            width: 100px;
            text-align: right;
            margin-right: 10px;
            color: fuchsia;
            white-space: pre;
        }}
    </style>
    <link rel="shortcut icon" href="https://files.femboy.kz/web/images/fucker.ico">
</head>
<body>
    <h1>FKZ File Index - {MIRROR_TAG} - /{os.path.basename(os.path.abspath(directory))}/</h1>
    <nav>
    """
        for ft in all_filetypes:
            html += f' | <a href="{ft}.html">[{ft.upper()}]</a>'
        html += f"""
    </nav>
    <br>
    <input type="text" id="search" placeholder="Search... :3" style="margin-bottom: 20px; padding: 5px;">
    <br>
    <nav>
        <a href="{mirror_link}">[{MIRROR_NAME}]</a>
    </nav>
    <br>"""

        folders_html = ""
        if up_link:
            folders_html += up_link + "<br>\n"

        items = sorted(
            os.listdir(directory),
            key=lambda x: (not os.path.isdir(os.path.join(directory, x)), x.lower()),
        )
        for item in items:
            item_path = os.path.join(directory, item)
            skip_subdir = os.path.exists(os.path.join(item_path, EXCLUDE_MARKER))
            if not skip_subdir:
                if os.path.isdir(item_path):
                    folders_html += f'<li><a href="{item}/">[{item}]</a></li>\n'

        if folders_html:
            html += (
                """
    <h2>Folders</h2>
    <ul>
                """
                + folders_html
            )
            if folders_count >= MIN_FOLDERS_FOR_NAV:
                if up_link:
                    html += "<br>\n" + up_link
                html += """
    <nav>
        <a href="#" onclick="window.scrollTo({top: 0, behavior: 'smooth'}); return false;">[Back to Top]</a>
    </nav>
                    """
            html += """
    </ul>"""

        files_html = ""
        for item in items:
            item_path = os.path.join(directory, item)
            if os.path.isfile(item_path):
                _, ext = os.path.splitext(item)
                if ext == "" and item.startswith("."):
                    ext = item[1:]
                else:
                    ext = ext.lstrip(".").lower()
                if ext in IGNORED_FILETYPES:
                    continue
                file_size = os.path.getsize(item_path)
                formatted_size = format_file_size(file_size)
                files_html += f'<li><span class="file-size">[{formatted_size}]</span> <a href="{item}">{item}</a></li>\n'

        if files_html:
            html += (
                """
    <h2>Files</h2>
    <ul>
                """
                + files_html
            )

            if files_count >= MIN_FILES_FOR_NAV:
                if up_link:
                    html += "<br>\n" + up_link
                html += """
    <nav>
        <a href="#" onclick="window.scrollTo({top: 0, behavior: 'smooth'}); return false;">[Back to Top]</a>
    </nav>
                    """
            html += "</ul>\n"

        html += """
    <script>
        function performSearch() {
            const query = document.getElementById("search").value.toLowerCase();
            const items = document.querySelectorAll("li");
            items.forEach(item => {
                const text = item.textContent.toLowerCase();
                item.style.display = text.includes(query) ? "block" : "none";
            });
        }

        document.getElementById("search").addEventListener("input", performSearch);

        const urlParams = new URLSearchParams(window.location.search);
        const searchTerm = urlParams.get('search');
  
        if (searchTerm) {
            const search = document.getElementById("search");
            search.value = searchTerm;
            performSearch();
        }
    </script>
</body>
</html>
            """

        output_file = os.path.join(directory, "index.html")
        try:
            with open(output_file, "w") as f:
                f.write(html)
        except OSError as e:
            print(f"Error writing index file '{output_file}': {e}", file=sys.stderr)
    except Exception as e:
        print(
            f"Error in generate_index for {directory}: {e}\n{traceback.format_exc()}",
            file=sys.stderr,
        )
        raise


def process_directory(directory, base_dir):
    try:
        skip_html = os.path.exists(os.path.join(directory, EXCLUDE_MARKER))
        if not skip_html:
            all_filetypes = get_filetypes(directory)

            if all_filetypes:
                for filetype in all_filetypes:
                    try:
                        generate_html(directory, filetype, all_filetypes, base_dir)
                    except Exception as e:
                        print(
                            f"Skipping HTML generation for {filetype} in {directory} due to error",
                            file=sys.stderr,
                        )

            try:
                generate_index(directory, all_filetypes, base_dir)
            except Exception as e:
                print(
                    f"Skipping index generation for {directory} due to error",
                    file=sys.stderr,
                )
        else:
            print(f"Skipping HTML generation for {directory} due to exclusion marker.")

        try:
            items = os.listdir(directory)
        except OSError as e:
            print(f"Error listing directory '{directory}': {e}", file=sys.stderr)
            return

        for item in items:
            item_path = os.path.join(directory, item)
            if os.path.isdir(item_path):
                try:
                    process_directory(item_path, base_dir)
                except Exception as e:
                    print(
                        f"Error processing subdirectory '{item_path}': {e}",
                        file=sys.stderr,
                    )
    except Exception as e:
        print(
            f"Critical error processing directory '{directory}': {e}\n{traceback.format_exc()}",
            file=sys.stderr,
        )
        raise


def main(directory="."):
    base_dir = os.path.abspath(directory)
    try:
        process_directory(directory, base_dir)
    except Exception as e:
        print(f"Fatal error: {e}\n{traceback.format_exc()}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 update_webserver.py <eu/na>")
        print("Valid options: 'eu' for European mirror, 'na' for North American mirror")
        sys.exit(1)

    site_ver = sys.argv[1].lower()

    if site_ver == "na":
        MIRROR_NAME = "EU site"
        MIRROR_TAG = "NA"
        MIRROR_URL = "https://files.femboy.kz"
    elif site_ver == "eu":
        MIRROR_NAME = "NA Site"
        MIRROR_TAG = "EU"
        MIRROR_URL = "https://files-na.femboy.kz"
    else:
        print("Invalid site version. Valid options: 'eu' or 'na'.")
        sys.exit(1)

    try:
        main()
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.", file=sys.stderr)
        sys.exit(130)
