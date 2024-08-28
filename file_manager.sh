#!/bin/bash

# نصب پیش‌نیازها
sudo apt update
sudo apt install -y python3 python3-pip

# نصب Flask
pip3 install Flask

# ایجاد فایل منیجر
cat <<EOF > file_manager.py
from flask import Flask, request, send_from_directory, redirect, url_for, render_template_string
import os

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route('/')
def index():
    files = os.listdir(app.config['UPLOAD_FOLDER'])
    return render_template_string('''
    <h1>File Manager</h1>
    <ul>
        {% for file in files %}
            <li><a href="/files/{{ file }}">{{ file }}</a> 
            <a href="/delete/{{ file }}">[Delete]</a></li>
        {% endfor %}
    </ul>
    <form action="/upload" method="post" enctype="multipart/form-data">
        <input type="file" name="file">
        <input type="submit" value="Upload">
    </form>
    <form action="/create_folder" method="post">
        <input type="text" name="folder_name" placeholder="Folder Name">
        <input type="submit" value="Create Folder">
    </form>
    ''', files=files)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return redirect(url_for('index'))
    file = request.files['file']
    if file.filename == '':
        return redirect(url_for('index'))
    file.save(os.path.join(app.config['UPLOAD_FOLDER'], file.filename))
    return redirect(url_for('index'))

@app.route('/files/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/delete/<filename>')
def delete_file(filename):
    os.remove(os.path.join(app.config['UPLOAD_FOLDER'], filename))
    return redirect(url_for('index'))

@app.route('/create_folder', methods=['POST'])
def create_folder():
    folder_name = request.form['folder_name']
    os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], folder_name), exist_ok=True)
    return redirect(url_for('index'))

@app.route('/delete_folder/<folder_name>')
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
cat <<EOF > .env
USERNAME=$USERNAME
PASSWORD=$PASSWORD
PORT=$PORT
EOF

# اجرای فایل منیجر
export PORT=$PORT
python3 file_manager.py
