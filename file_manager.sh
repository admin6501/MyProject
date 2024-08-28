#!/bin/bash

# نصب پیش‌نیازها
sudo apt update
sudo apt install -y python3 python3-pip

# نصب Flask و کتابخانه‌های مورد نیاز
pip3 install Flask Flask-Login Flask-Bcrypt

# ایجاد فایل منیجر
cat <<EOF > /opt/file_manager.py
from flask import Flask, request, redirect, url_for, render_template_string, flash, send_from_directory
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from flask_bcrypt import Bcrypt
import os

app = Flask(__name__)
app.secret_key = 'supersecretkey'
bcrypt = Bcrypt(app)
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

UPLOAD_FOLDER = '/'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

class User(UserMixin):
    def __init__(self, id, username, password):
        self.id = id
        self.username = username
        self.password = password

users = {'admin': User(id=1, username='admin', password='$2b$12$e0NRz1F1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1Q1')}

@login_manager.user_loader
def load_user(user_id):
    for user in users.values():
        if user.id == int(user_id):
            return user
    return None

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        user = users.get(username)
        if user and bcrypt.check_password_hash(user.password, password.encode('utf-8')):
            login_user(user)
            return redirect(url_for('index'))
        else:
            flash('Invalid username or password')
    return render_template_string('''
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
        <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet">
        <title>Login</title>
      </head>
      <body>
        <div class="container">
          <h2 class="mt-5">Login</h2>
          <form method="post">
            <div class="form-group">
              <label for="username">Username</label>
              <input type="text" class="form-control" id="username" name="username" placeholder="Username">
            </div>
            <div class="form-group">
              <label for="password">Password</label>
              <input type="password" class="form-control" id="password" name="password" placeholder="Password">
            </div>
            <button type="submit" class="btn btn-primary">Login</button>
          </form>
        </div>
      </body>
    </html>
    ''')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/')
@login_required
def index():
    files = os.listdir(app.config['UPLOAD_FOLDER'])
    return render_template_string('''
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
        <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet">
        <title>File Manager</title>
      </head>
      <body>
        <div class="container">
          <h1 class="mt-5">File Manager</h1>
          <ul class="list-group">
            {% for file in files %}
              <li class="list-group-item">
                <a href="/files/{{ file }}">{{ file }}</a> 
                <a href="/delete/{{ file }}" class="btn btn-danger btn-sm float-right">Delete</a>
              </li>
            {% endfor %}
          </ul>
          <form action="/upload" method="post" enctype="multipart/form-data" class="mt-3">
            <div class="form-group">
              <input type="file" class="form-control-file" name="file">
            </div>
            <button type="submit" class="btn btn-primary">Upload</button>
          </form>
          <form action="/create_folder" method="post" class="mt-3">
            <div class="form-group">
              <input type="text" class="form-control" name="folder_name" placeholder="Folder Name">
            </div>
            <button type="submit" class="btn btn-success">Create Folder</button>
          </form>
          <a href="/logout" class="btn btn-secondary mt-3">Logout</a>
        </div>
      </body>
    </html>
    ''', files=files)

@app.route('/upload', methods=['POST'])
@login_required
def upload_file():
    if 'file' not in request.files:
        return redirect(url_for('index'))
    file = request.files['file']
    if file.filename == '':
        return redirect(url_for('index'))
    file.save(os.path.join(app.config['UPLOAD_FOLDER'], file.filename))
    return redirect(url_for('index'))

@app.route('/files/<filename>')
@login_required
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/delete/<filename>')
@login_required
def delete_file(filename):
    os.remove(os.path.join(app.config['UPLOAD_FOLDER'], filename))
    return redirect(url_for('index'))

@app.route('/create_folder', methods=['POST'])
@login_required
def create_folder():
    folder_name = request.form['folder_name']
    os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], folder_name), exist_ok=True)
    return redirect(url_for('index'))

@app.route('/delete_folder/<folder_name>')
@login_required
def delete_folder(folder_name):
    os.rmdir(os.path.join(app.config['UPLOAD_FOLDER'], folder_name))
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
EOF

# درخواست اطلاعات از کاربر
read -p "Enter username: " USERNAME
read -sp "Enter password: " PASSWORD
echo
read -p "Enter port: " PORT

# ایجاد فایل .env برای ذخیره اطلاعات
cat <<EOF > /opt/.env
USERNAME=$USERNAME
PASSWORD=$PASSWORD
PORT=$PORT
EOF

# ایجاد فایل سرویس systemd
cat <<EOF | sudo tee /etc/systemd/system/file_manager.service
[Unit]
Description=File Manager Service
After=network.target

[Service]
EnvironmentFile=/opt/.env
ExecStart=/usr/bin/python3 /opt/file_manager.py
Restart=always
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

# راه‌اندازی و فعال‌سازی سرویس
sudo systemctl daemon-reload
sudo systemctl start file_manager.service
sudo systemctl enable file_manager.service
