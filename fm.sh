#!/bin/bash

# نصب پایتون و pip در صورت عدم وجود
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Installing Python 3..."
    sudo apt update
    sudo apt install python3 python3-pip -y
fi

# نصب Flask و Flask-Login
pip3 install Flask Flask-Login

# ایجاد دایرکتوری FM
mkdir FM
cd FM

# ایجاد فایل config.txt
cat <<EOL > config.txt
username:admin
password:password
port:5000
EOL

# ایجاد فایل app.py
cat <<EOL > app.py
from flask import Flask, render_template, request, redirect, url_for, flash, session
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user
import os

app = Flask(__name__)
app.secret_key = 'your_secret_key'
login_manager = LoginManager()
login_manager.init_app(app)

def read_config():
    config = {}
    with open('config.txt', 'r') as f:
        for line in f:
            key, value = line.strip().split(':')
            config[key] = value
    return config

def write_config(config):
    with open('config.txt', 'w') as f:
        for key, value in config.items():
            f.write(f"{key}:{value}\n")

config = read_config()
users = {config['username']: config['password']}
BASE_DIR = 'your_base_directory'

class User(UserMixin):
    def __init__(self, username):
        self.username = username

@login_manager.user_loader
def load_user(user_id):
    return User(user_id)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        if username in users and users[username] == password:
            user = User(username)
            login_user(user)
            return redirect(url_for('index'))
        flash('Invalid credentials')
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/')
@login_required
def index():
    files = os.listdir(BASE_DIR)
    return render_template('index.html', files=files)

@app.route('/upload', methods=['POST'])
@login_required
def upload():
    if request.method == 'POST':
        file = request.files['file']
        if file:
            file.save(os.path.join(BASE_DIR, file.filename))
            flash('File uploaded successfully')
    return redirect(url_for('index'))

@app.route('/delete/<filename>', methods=['POST'])
@login_required
def delete(filename):
    os.remove(os.path.join(BASE_DIR, filename))
    flash('File deleted successfully')
    return redirect(url_for('index'))

@app.route('/create_folder', methods=['POST'])
@login_required
def create_folder():
    folder_name = request.form['folder_name']
    os.makedirs(os.path.join(BASE_DIR, folder_name))
    flash('Folder created successfully')
    return redirect(url_for('index'))

@app.route('/rename/<filename>', methods=['POST'])
@login_required
def rename(filename):
    new_name = request.form['new_name']
    os.rename(os.path.join(BASE_DIR, filename), os.path.join(BASE_DIR, new_name))
    flash('File renamed successfully')
    return redirect(url_for('index'))

@app.route('/settings', methods=['GET', 'POST'])
@login_required
def settings():
    if request.method == 'POST':
        new_username = request.form['username']
        new_password = request.form['password']
        new_port = request.form['port']
        
        global users
        users = {new_username: new_password}
        
        config['username'] = new_username
        config['password'] = new_password
        config['port'] = new_port
        write_config(config)
        
        flash('Settings updated successfully')
        return redirect(url_for('index'))

    return render_template('settings.html', config=config)

if __name__ == '__main__':
    app.run(debug=True, port=int(config['port']))
EOL

# ایجاد دایرکتوری templates
mkdir templates

# ایجاد فایل index.html
cat <<EOL > templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>File Manager</title>
</head>
<body>
    <h1>File Manager</h1>
    <form action="/upload" method="POST" enctype="multipart/form-data">
        <input type="file" name="file" required>
        <button type="submit">Upload</button>
    </form>
    <form action="/create_folder" method="POST">
        <input type="text" name="folder_name" placeholder="New Folder Name" required>
        <button type="submit">Create Folder</button>
    </form>
    <ul>
        {% for file in files %}
            <li>
                {{ file }}
                <form action="/delete/{{ file }}" method="POST" style="display:inline;">
                    <button type="submit">Delete</button>
                </form>
                <form action="/rename/{{ file }}" method="POST" style="display:inline;">
                    <input type="text" name="new_name" placeholder="New Name" required>
                    <button type="submit">Rename</button>
                </form>
            </li>
        {% endfor %}
    </ul>
    <a href="/settings">Settings</a>
    <a href="/logout">Logout</a>
</body>
</html>
EOL

# ایجاد فایل login.html
cat <<EOL > templates/login.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Login</title>
</head>
<body>
    <h1>Login</h1>
    <form action="/login" method="POST">
        <input type="text" name="username" placeholder="Username" required>
        <input type="password" name="password" placeholder="Password" required>
        <button type="submit">Login</button>
    </form>
</body>
</html>
EOL

# ایجاد فایل settings.html
cat <<EOL > templates/settings.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Settings</title>
</head>
<body>
    <h1>Settings</h1>
    <form action="/settings" method="POST">
        <input type="text" name="username" placeholder="Username" value="{{ config['username'] }}" required>
        <input type="password" name="password" placeholder="Password" value="{{ config['password'] }}" required>
        <input type="text" name="port" placeholder="Port" value="{{ config['port'] }}" required>
        <button type="submit">Update Settings</button>
    </form>
    <a href="/">Back to File Manager</a>
</body>
</html>
EOL

# تغییر به دایرکتوری FM و اجرای برنامه
cd FM
python3 app.py#!/bin/bash

# نصب پایتون و pip در صورت عدم وجود
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Installing Python 3..."
    sudo apt update
    sudo apt install python3 python3-pip -y
fi

# نصب Flask و Flask-Login
pip3 install Flask Flask-Login

# ایجاد دایرکتوری FM
mkdir FM
cd FM

# ایجاد فایل config.txt
cat <<EOL > config.txt
username:admin
password:password
port:5000
EOL

# ایجاد فایل app.py
cat <<EOL > app.py
from flask import Flask, render_template, request, redirect, url_for, flash, session
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user
import os

app = Flask(__name__)
app.secret_key = 'your_secret_key'
login_manager = LoginManager()
login_manager.init_app(app)

def read_config():
    config = {}
    with open('config.txt', 'r') as f:
        for line in f:
            key, value = line.strip().split(':')
            config[key] = value
    return config

def write_config(config):
    with open('config.txt', 'w') as f:
        for key, value in config.items():
            f.write(f"{key}:{value}\n")

config = read_config()
users = {config['username']: config['password']}
BASE_DIR = 'your_base_directory'

class User(UserMixin):
    def __init__(self, username):
        self.username = username

@login_manager.user_loader
def load_user(user_id):
    return User(user_id)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        if username in users and users[username] == password:
            user = User(username)
            login_user(user)
            return redirect(url_for('index'))
        flash('Invalid credentials')
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/')
@login_required
def index():
    files = os.listdir(BASE_DIR)
    return render_template('index.html', files=files)

@app.route('/upload', methods=['POST'])
@login_required
def upload():
    if request.method == 'POST':
        file = request.files['file']
        if file:
            file.save(os.path.join(BASE_DIR, file.filename))
            flash('File uploaded successfully')
    return redirect(url_for('index'))

@app.route('/delete/<filename>', methods=['POST'])
@login_required
def delete(filename):
    os.remove(os.path.join(BASE_DIR, filename))
    flash('File deleted successfully')
    return redirect(url_for('index'))

@app.route('/create_folder', methods=['POST'])
@login_required
def create_folder():
    folder_name = request.form['folder_name']
    os.makedirs(os.path.join(BASE_DIR, folder_name))
    flash('Folder created successfully')
    return redirect(url_for('index'))

@app.route('/rename/<filename>', methods=['POST'])
@login_required
def rename(filename):
    new_name = request.form['new_name']
    os.rename(os.path.join(BASE_DIR, filename), os.path.join(BASE_DIR, new_name))
    flash('File renamed successfully')
    return redirect(url_for('index'))

@app.route('/settings', methods=['GET', 'POST'])
@login_required
def settings():
    if request.method == 'POST':
        new_username = request.form['username']
        new_password = request.form['password']
        new_port = request.form['port']
        
        global users
        users = {new_username: new_password}
        
        config['username'] = new_username
        config['password'] = new_password
        config['port'] = new_port
        write_config(config)
        
        flash('Settings updated successfully')
        return redirect(url_for('index'))

    return render_template('settings.html', config=config)

if __name__ == '__main__':
    app.run(debug=True, port=int(config['port']))
EOL

# ایجاد دایرکتوری templates
mkdir templates

# ایجاد فایل index.html
cat <<EOL > templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>File Manager</title>
</head>
<body>
    <h1>File Manager</h1>
    <form action="/upload" method="POST" enctype="multipart/form-data">
        <input type="file" name="file" required>
        <button type="submit">Upload</button>
    </form>
    <form action="/create_folder" method="POST">
        <input type="text" name="folder_name" placeholder="New Folder Name" required>
        <button type="submit">Create Folder</button>
    </form>
    <ul>
        {% for file in files %}
            <li>
                {{ file }}
                <form action="/delete/{{ file }}" method="POST" style="display:inline;">
                    <button type="submit">Delete</button>
                </form>
                <form action="/rename/{{ file }}" method="POST" style="display:inline;">
                    <input type="text" name="new_name" placeholder="New Name" required>
                    <button type="submit">Rename</button>
                </form>
            </li>
        {% endfor %}
    </ul>
    <a href="/settings">Settings</a>
    <a href="/logout">Logout</a>
</body>
</html>
EOL

# ایجاد فایل login.html
cat <<EOL > templates/login.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Login</title>
</head>
<body>
    <h1>Login</h1>
    <form action="/login" method="POST">
        <input type="text" name="username" placeholder="Username" required>
        <input type="password" name="password" placeholder="Password" required>
        <button type="submit">Login</button>
    </form>
</body>
</html>
EOL

# ایجاد فایل settings.html
cat <<EOL > templates/settings.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Settings</title>
</head>
<body>
    <h1>Settings</h1>
    <form action="/settings" method="POST">
        <input type="text" name="username" placeholder="Username" value="{{ config['username'] }}" required>
        <input type="password" name="password" placeholder="Password" value="{{ config['password'] }}" required>
        <input type="text" name="port" placeholder="Port" value="{{ config['port'] }}" required>
        <button type="submit">Update Settings</button>
    </form>
    <a href="/">Back to File Manager</a>
</body>
</html>
EOL

# تغییر به دایرکتوری FM و اجرای برنامه
cd FM
python3 app.py
