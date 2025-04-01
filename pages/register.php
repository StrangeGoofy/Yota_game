<?php
    ini_set('display_errors', 1);
    ini_set('display_startup_errors', 1);
    error_reporting(E_ALL);

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
        <form id="registerForm">
            <div class="main_part">        
                <div class="input-group">
                    <label for="login">Логин</label>
                    <input type="text" name="username" id="login" required>
                </div>
                <div class="input-group">
                    <label for="password">Пароль</label>
                    <input type="password" id="password" name="password" required>
                </div>
                <div class="input-group">
                    <label for="nickname">Имя в игре</label>
                    <input type="text" id="nickname" name="nickname" required>
                </div>
            </div>
            <div class="buttons">
                <button type="button" class="left unactive" onclick="window.location.href='auth.php';">Вход</button>
                <button type="submit" class="right active">Регистрация</button>
            </div>
        </form>
    </div>

</body>
</html>

<script>
    document.getElementById("registerForm").addEventListener("submit", async function (e) {
        e.preventDefault();

        const username = document.getElementById("login").value.trim();
        const password = document.getElementById("password").value.trim();
        const nickname = document.getElementById("nickname").value.trim();

        if (!username || !password || !nickname) {
            alert("Пожалуйста, заполните все поля!");
            return;
        }

        const formData = new FormData();
        formData.append("username", username);
        formData.append("password", password);
        formData.append("nickname", nickname); // <--- исправлено здесь!

        try {
            const response = await fetch("../api/reg_f.php", {
                method: "POST",
                headers: {
                    "X-Requested-With": "fetch"
                },
                body: formData
            });

            const result = await response.json();

            if (result.success) {
                console.log('token: ' + result.token);
                window.location.href = "../pages/lobbies.php";
            } else {
                alert(result.message || "Ошибка регистрации");
            }
        } catch (err) {
            console.error("Ошибка:", err);
            alert("Ошибка соединения с сервером");
        }
    });
    </script>

<!--Скрипт по кругу выбирающий цвета рамок для input-ов-->
<script>
    const colors = ["rgb(249, 165, 27)", "rgb(96, 187, 70)", "rgb(238, 29, 35)", "rgb(39, 131, 197)"];
    let index = 0;
    const defaultColor = "#ccc"; // Цвет по умолчанию

    document.querySelectorAll("input").forEach((input) => {
        input.addEventListener("focus", function () {
            this.style.borderColor = colors[index];
            index = (index + 1) % colors.length;
        });

        input.addEventListener("blur", function () {
            this.style.borderColor = defaultColor;
        });
    });
</script>