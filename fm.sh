#!/bin/bash

# Settings
REQUIREMENTS_FILE="requirements.txt"
APP_DIR="file_manager_app"
UPLOAD_FOLDER="$APP_DIR/uploads"
TEMPLATES_FOLDER="$APP_DIR/templates"

# 1. Create directory for the app
if [ ! -d "$APP_DIR" ]; then
    mkdir "$APP_DIR"
    echo "Directory $APP_DIR created successfully."
fi

cd "$APP_DIR"

# 2. Create `requirements.txt` file and install dependencies
cat > "$REQUIREMENTS_FILE" <<EOL
Flask==2.0.3
EOL

pip install -r "$REQUIREMENTS_FILE"
echo "Python dependencies installed successfully."

# 3. Create the structure of files and directories for the app
# Create upload folder
if [ ! -d "$UPLOAD_FOLDER" ]; then
    mkdir "$UPLOAD_FOLDER"
    echo "Directory $UPLOAD_FOLDER created successfully."
fi

# Create templates folder
if [ ! -d "$TEMPLATES_FOLDER" ]; then
    mkdir "$TEMPLATES_FOLDER"
    echo "Directory $TEMPLATES_FOLDER created successfully."
fi

# Create `app.py`
cat > app.py <<EOL
from flask import Flask, render_template, request, redirect, url_for, send_from_directory, flash
import os
import argparse

app = Flask(__name__)
app.secret_key = 'your_secret_key'
UPLOAD_FOLDER = 'uploads'

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

USER_DATA = {'username': 'admin', 'password': 'password'}

@app.route('/')
def index():
    return render_template('login.html')

@app.route('/login', methods=['POST'])
def login():
    username = request.form['username']
    password = request.form['password']
    if username == USER_DATA['username'] and password == USER_DATA['password']:
        return redirect(url_for('file_manager'))
    else:
        flash('Incorrect username or password.')
        return redirect(url_for('index'))

@app.route('/file_manager')
def file_manager():
    path = request.args.get('path', '')
    abs_path = os.path.join(UPLOAD_FOLDER, path)
    if not os.path.exists(abs_path):
        flash('The requested path does not exist.')
        return redirect(url_for('file_manager'))

    items = os.listdir(abs_path)
    items = [item + '/' if os.path.isdir(os.path.join(abs_path, item)) else item for item in items]
    return render_template('file_manager.html', files=items, path=path)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        flash('No file selected.')
        return redirect(request.referrer)
    
    file = request.files['file']
    if file.filename == '':
        flash('No file name specified.')
        return redirect(request.referrer)
    
    path = request.form['path']
    file.save(os.path.join(UPLOAD_FOLDER, path, file.filename))
    return redirect(url_for('file_manager', path=path))

@app.route('/create_folder', methods=['POST'])
def create_folder():
    folder_name = request.form['folder_name']
    path = request.form['path']
    os.makedirs(os.path.join(UPLOAD_FOLDER, path, folder_name), exist_ok=True)
    return redirect(url_for('file_manager', path=path))

@app.route('/delete', methods=['POST'])
def delete():
    name = request.form['name']
    path = request.form['path']
    abs_path = os.path.join(UPLOAD_FOLDER, path, name)

    if os.path.isdir(abs_path):
        os.rmdir(abs_path)
    else:
        os.remove(abs_path)
    
    return redirect(url_for('file_manager', path=path))

@app.route('/rename', methods=['POST'])
def rename():
    old_name = request.form['old_name']
    new_name = request.form['new_name']
    path = request.form['path']
    abs_old_path = os.path.join(UPLOAD_FOLDER, path, old_name)
    abs_new_path = os.path.join(UPLOAD_FOLDER, path, new_name)

    os.rename(abs_old_path, abs_new_path)
    return redirect(url_for('file_manager', path=path))

@app.route('/download/<path:filename>')
def download(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

@app.route('/change_credentials')
def change_credentials_form():
    return render_template('change_credentials.html')

@app.route('/change_credentials', methods=['POST'])
def change_credentials():
    current_username = request.form['current_username']
    current_password = request.form['current_password']
    new_username = request.form['new_username']
    new_password = request.form['new_password']

    if current_username == USER_DATA['username'] and current_password == USER_DATA['password']:
        USER_DATA['username'] = new_username
        USER_DATA['password'] = new_password
        flash('Login information changed successfully.')
    else:
        flash('Incorrect current username or password.')

    return redirect(url_for('change_credentials_form'))

@app.route('/edit_file')
def edit_file():
    file_path = request.args.get('file_path')
    abs_path = os.path.join(UPLOAD_FOLDER, file_path)
    
    if not os.path.exists(abs_path) or os.path.isdir(abs_path):
        flash('The specified file does not exist or is a directory.')
        return redirect(url_for('file_manager'))
    
    with open(abs_path, 'r') as f:
        content = f.read()
    
    return render_template('edit_file.html', file_path=file_path, content=content)

@app.route('/save_file', methods=['POST'])
def save_file():
    file_path = request.form['file_path']
    content = request.form['content']
    abs_path = os.path.join(UPLOAD_FOLDER, file_path)
    
    with open(abs_path, 'w') as f:
        f.write(content)
    
    flash('File saved successfully.')
    return redirect(url_for('edit_file', file_path=file_path))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run the Flask app on a specified port.')
    parser.add_argument('--port', type=int, default=8000, help='Port to run the Flask app on (default is 8000)')
    args = parser.parse_args()
    app.run(debug=True, port=args.port)
EOL

# Create template for login.html
cat > "$TEMPLATES_FOLDER/login.html" <<EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Login</title>
</head>
<body>
    <h2>Login</h2>
    <form method="post" action="/login">
        <input type="text" name="username" placeholder="Username">
        <input type="password" name="password" placeholder="Password">
        <button type="submit">Login</button>
    </form>
    {% with messages = get_flashed_messages() %}
      {% if messages %}
        <ul>
          {% for message in messages %}
            <li>{{ message }}</li>
          {% endfor %}
        </ul>
      {% endif %}
    {% endwith %}
</body>
</html>
EOL

# Create template for change_credentials.html
cat > "$TEMPLATES_FOLDER/change_credentials.html" <<EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Change Credentials</title>
</head>
<body>
    <h2>Change Username/Password</h2>
    <form method="post" action="/change_credentials">
        <input type="text" name="current_username" placeholder="Current Username">
        <input type="password" name="current_password" placeholder="Current Password">
        <input type="text" name="new_username" placeholder="New Username">
        <input type="password" name="new_password" placeholder="New Password">
        <button type="submit">Change</button>
    </form>
    {% with messages = get_flashed_messages() %}
      {% if messages %}
        <ul>
          {% for message in messages %}
            <li>{{ message }}</li>
          {% endfor %}
        </ul>
      {% endif %}
    {% endwith %}
</body>
</html>
EOL

# Create template for file_manager.html
cat > "$TEMPLATES_FOLDER/file_manager.html" <<EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>File Manager</title>
</head>
<body>
    <h2>File Manager</h2>
    <h3>Path: {{ path }}</h3>

    <a href="/">Logout</a>
    <br><br>
    <a href="/change_credentials">Change Username/Password</a>

    <!-- File Upload Form -->
    <form method="post" action="/upload" enctype="multipart/form-data">
        <input type="hidden" name="path" value="{{ path }}">
        <input type="file" name="file">
        <button type="submit">Upload</button>
    </form>

    <!-- Create Folder Form -->
    <form method="post" action="/create_folder">
        <input type="hidden" name="path" value="{{ path }}">
        <input type="text" name="folder_name" placeholder="Folder Name">
        <button type="submit">Create Folder</button>
    </form>

    <ul>
        {% for file in files %}
            <li>
                {% if file.endswith('/') %}
                    <a href="{{ url_for('file_manager', path=path + '/' + file)|replace('//', '/') }}">{{ file }}</a>
                {% else %}
                    {{ file }}
                    <a href="{{ url_for('edit_file', file_path=path + '/' + file)|replace('//', '/') }}">Edit</a>
                    <a href="{{ url_for('download', filename=path + '/' + file) }}">Download</a>
                {% endif %}
                <form method="post" action="/delete" style="display:inline;">
                    <input type="hidden" name="path" value="{{ path }}">
                    <input type="hidden" name="name" value="{{ file }}">
                    <button type="submit">Delete</button>
                </form>
                <form method="post" action="/rename" style="display:inline;">
                    <input type="hidden" name="path" value="{{ path }}">
                    <input type="hidden" name="old_name" value="{{ file }}">
                    <input type="text" name="new_name" placeholder="New Name">
                    <button type="submit">Rename</button>
                </form>
            </li>
        {% endfor %}
    </ul>

    {% with messages = get_flashed_messages() %}
      {% if messages %}
        <ul>
          {% for message in messages %}
            <li>{{ message }}</li>
          {% endfor %}
        </ul>
      {% endif %}
    {% endwith %}
</body>
</html>
EOL

# Create template for edit_file.html
cat > "$TEMPLATES_FOLDER/edit_file.html" <<EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Edit File</title>
</head>
<body>
    <h2>Edit File: {{ file_path }}</h2>
    <form method="post" action="/save_file">
        <input type="hidden" name="file_path" value="{{ file_path }}">
        <textarea name="content" rows="20" cols="80">{{ content }}</textarea><br><br>
        <button type="submit">Save</button>
    </form>
    {% with messages = get_flashed_messages() %}
      {% if messages %}
        <ul>
          {% for message in messages %}
            <li>{{ message }}</li>
          {% endfor %}
        </ul>
      {% endif %}
    {% endwith %}
</body>
</html>
EOL

echo "App file structure created."

# 4. Run the application
python app.py --port 8000