#!/bin/bash

read -p "Enter your desired username: " username
read -sp "Enter your desired password: " password
echo

cat <<EOL > login.php
<?php
session_start();

\$users = [
    '$username' => '$password'
];

if (isset(\$_POST['username']) && isset(\$_POST['password'])) {
    \$username = \$_POST['username'];
    \$password = \$_POST['password'];

    if (isset(\$users[\$username]) && \$users[\$username] == \$password) {
        \$_SESSION['username'] = \$username;
        header("Location: file_manager.php");
        exit();
    } else {
        \$error = "Incorrect username or password.";
    }
}
?>

<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
</head>
<body>
    <form method="post">
        <h2>Login</h2>
        <?php if (isset(\$error)): ?>
            <p style="color: red;"><?php echo \$error; ?></p>
        <?php endif; ?>
        <label>Username: <input type="text" name="username"></label><br>
        <label>Password: <input type="password" name="password"></label><br>
        <button type="submit">Login</button>
    </form>
</body>
</html>
EOL

cat <<EOL > file_manager.php
<?php
session_start();

if (!isset(\$_SESSION['username'])) {
    header("Location: login.php");
    exit();
}

\$dir = isset(\$_GET['dir']) ? \$_GET['dir'] : '.';
\$files = scandir(\$dir);

if (isset(\$_POST['upload'])) {
    \$target_file = \$dir . '/' . basename(\$_FILES["file"]["name"]);
    if (move_uploaded_file(\$_FILES["file"]["tmp_name"], \$target_file)) {
        echo "File successfully uploaded.";
    } else {
        echo "File upload failed.";
    }
}

if (isset(\$_POST['create_folder'])) {
    \$new_folder = \$dir . '/' . basename(\$_POST['folder_name']);
    if (!file_exists(\$new_folder)) {
        mkdir(\$new_folder);
        echo "Folder successfully created.";
    } else {
        echo "Folder already exists.";
    }
}
?>

<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Manager</title>
</head>
<body>
    <h2>File Manager</h2>
    <form method="post" enctype="multipart/form-data">
        <input type="file" name="file">
        <button type="submit" name="upload">Upload</button>
    </form>
    <form method="post">
        <input type="text" name="folder_name" placeholder="New folder name">
        <button type="submit" name="create_folder">Create Folder</button>
    </form>
    <ul>
        <?php foreach (\$files as \$file): ?>
            <?php if (\$file == '.' || \$file == '..') continue; ?>
            <li>
                <?php if (is_dir(\$dir . '/' . \$file)): ?>
                    <a href="?dir=<?php echo \$dir . '/' . \$file; ?>"><?php echo \$file; ?></a>
                <?php else: ?>
                    <?php echo \$file; ?>
                <?php endif; ?>
            </li>
        <?php endforeach; ?>
    </ul>
</body>
</html>
EOL

echo "Installation completed successfully."
