<?php
// Простейший PHP-скрипт для отображения HTML-страницы
?>

<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<link rel="stylesheet" href="../src/styles/auth_styles.css" />
	<title>Yota</title>
</head>
<body>
    <div class="container">
        <img src="img/Yota_logo.png" alt="логотип игры" class="logo">
        <div class="main_part">        
            <div class="input-group">
                <label for="login">Логин</label>
                <input type="text" id="login">
            </div>
            <div class="input-group">
                <label for="password">Пароль</label>
                <input type="password" id="password">
            </div>
        </div>
        <div class="buttons">
            <button class="left">Вход</button>
            <button class="right">Регистрация</button>
        </div>
    </div>

</body>
</html>
