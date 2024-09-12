#!/bin/bash

# نصب Node.js و npm (در صورت نیاز)
if ! command -v node &> /dev/null
then
    echo "Node.js در سیستم شما نصب نیست. لطفاً Node.js را نصب کنید."
    exit
fi

# ایجاد پوشه پروژه
mkdir -p web_console
cd web_console

# ایجاد فایل server.js
cat << 'EOF' > server.js
const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const app = express();
const port = 3000;

app.use(express.static('public'));

app.get('/create-temp-dir', (req, res) => {
    const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'user-'));
    res.json({ tempDir });
});

app.get('/execute', (req, res) => {
    const { command, dir } = req.query;
    exec(command, { cwd: dir }, (error, stdout, stderr) => {
        if (error) {
            res.json({ output: stderr });
        } else {
            res.json({ output: stdout });
        }
    });
});

app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});
EOF

# ایجاد پوشه public و فایل index.html
mkdir -p public
cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="fa">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>کنسول وب لینوکس</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #282c34;
            color: #61dafb;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            direction: rtl;
        }
        #console {
            width: 80%;
            height: 60%;
            background-color: #1e1e1e;
            border: 1px solid #61dafb;
            padding: 10px;
            overflow-y: auto;
        }
        input {
            width: 100%;
            padding: 10px;
            border: none;
            background-color: #282c34;
            color: #61dafb;
            font-size: 16px;
        }
    </style>
</head>
<body>
    <div id="console"></div>
    <input type="text" id="commandInput" placeholder="دستور خود را وارد کنید...">
    <script>
        const consoleDiv = document.getElementById('console');
        const commandInput = document.getElementById('commandInput');
        let tempDir = '';

        fetch('/create-temp-dir')
            .then(response => response.json())
            .then(data => {
                tempDir = data.tempDir;
                appendToConsole(`دایرکتوری موقت شما: ${tempDir}`);
            });

        commandInput.addEventListener('keydown', function(event) {
            if (event.key === 'Enter') {
                const command = commandInput.value.trim();
                executeCommand(command);
                commandInput.value = '';
            }
        });

        function executeCommand(command) {
            fetch(`/execute?command=${encodeURIComponent(command)}&dir=${encodeURIComponent(tempDir)}`)
                .then(response => response.json())
                .then(data => {
                    appendToConsole(`$ ${command}\n${data.output}`);
                });
        }

        function appendToConsole(text) {
            const newLine = document.createElement('div');
            newLine.textContent = text;
            consoleDiv.appendChild(newLine);
            consoleDiv.scrollTop = consoleDiv.scrollHeight;
        }

        window.addEventListener('beforeunload', function() {
            // حذف عملیات‌ها و دستورات
            consoleDiv.innerHTML = '';
        });
    </script>
</body>
</html>
EOF

# نصب وابستگی‌های Node.js
npm init -y
npm install express

# اجرای سرور
node server.js
