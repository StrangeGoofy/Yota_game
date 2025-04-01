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
    <form id="login-form">
      <div class="main_part">
        <div class="input-group">
          <label for="login">Логин</label>
          <input type="text" name="username" id="login" required>
        </div>
        <div class="input-group">
          <label for="password">Пароль</label>
          <input class="sad" type="password" id="password" name="password" required>
        </div>
      </div>
      <div class="buttons">
        <button type="submit" class="left active">Вход</button>
        <button type="button" class="right unactive" onclick="window.location.href='register.php';">Регистрация</button>
      </div>
    </form>
  </div>

    <script>
        const colors = ["rgb(249, 165, 27)", "rgb(96, 187, 70)", "rgb(238, 29, 35)", "rgb(39, 131, 197)"];
        let index = 0;
        const defaultColor = "#ccc";

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

    <script>
        document.getElementById("login-form").addEventListener("submit", async function (e) {
        e.preventDefault();

        const username = document.getElementById("login").value.trim();
        const password = document.getElementById("password").value.trim();

        if (!username || !password) {
            alert("Пожалуйста, заполните все поля!");
            return;
        }

        const formData = new FormData();
        formData.append("username", username);
        formData.append("password", password);

        try {
            const response = await fetch("../api/login_f.php", {
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
            alert(result.message || "Ошибка входа");
            }

        } catch (err) {
            console.error("Ошибка:", err);
            alert("Ошибка соединения с сервером");
        }
        });
    </script>
</body>
</html>
