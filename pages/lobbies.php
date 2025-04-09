<!DOCTYPE html>
<html lang="ru">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <link rel="stylesheet" href="../src/styles/lobbies.css" />
  <title>Yota</title>
  <style>
    #rule_modal .modal-content {
      width: 80vw;
      max-height: 80vh;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      align-items: center;
    }

    .rule-slide-container {
      flex: 1;
      overflow-y: auto;
      width: 100%;
      display: flex;
      flex-direction: column;
      align-items: center;
    }

    .rule-image {
      width: 100%;
      max-width: 100%;
      margin-bottom: 20px;
      object-fit: contain;
    }
  </style>
</head>

<body>
  <div class="top_bar">
    <div class="right">
      <button class="colored" id="logoutBtn">Выход</button>
      <button class="colored" id="openRuleModal">Правила</button>
      <button class="colored" id="openNameModal">Сменить имя</button>
    </div>
  </div>

  <div class="container">
    <div id="lobby_list" class="lobby_list">
      <p>Загрузка лобби...</p>
    </div>
    <button class="colored big" id="openLobbyModal">Создать лобби</button>
  </div>

  <!-- Модальные окна -->

  <div id="lobby_modal" class="modal hidden">
    <div class="modal-content">
      <h2>Создание лобби</h2>
      <form id="createLobbyForm">
        <label>Название лобби:</label>
        <input type="text" name="lobby_name" id="lobbyName" required />

        <label>Пароль:</label>
        <input type="password" name="password" id="lobbyPasswordC" />

        <label>Количество игроков:</label>
        <select name="req_players" id="req_players">
          <option value="2">2</option>
          <option value="3">3</option>
          <option value="4">4</option>
        </select>

        <label>Время на ход:</label>
        <select name="turn_time" id="turnTime">
          <option value="30">30</option>
          <option value="60" selected>60</option>
          <option value="120">120</option>
        </select>

        <div class="modal-buttons">
          <button type="submit" class="colored">Создать</button>
          <button type="button" id="closeLobbyModal" class="colored">Отмена</button>
        </div>
      </form>
    </div>
  </div>

  <div id="name_modal" class="modal hidden">
    <div class="modal-content">
      <h2>Смена имени</h2>
      <form id="nameChangeForm">
        <label>Новое имя:</label>
        <input type="text" name="nickname" id="nicknameInput" required />
        <div class="modal-buttons">
          <button type="submit" class="colored">Сохранить</button>
          <button type="button" id="closeNameModal" class="colored">Отмена</button>
        </div>
      </form>
    </div>
  </div>

  <div id="rule_modal" class="modal hidden">
    <div class="modal-content">
      <h2>Правила</h2>
      <div class="rule-slide-container">
        <img src="img/yota_rule_1.png" alt="Правила 1" class="rule-image">
        <img src="img/yota_rule_2.png" alt="Правила 2" class="rule-image">
      </div>
      <div class="modal-buttons">
        <button type="button" id="closeRuleModal" class="colored">Закрыть</button>
      </div>
    </div>
  </div>

  <div id="join_modal" class="modal hidden">
    <div class="modal-content">
      <h2>Вход в лобби</h2>
      <form id="joinLobbyForm">
        <label>Пароль:</label>
        <input type="password" name="password" id="lobbyPassword" required />
        <input type="hidden" name="lobby_id" id="joinLobbyId">
        <div class="modal-buttons">
          <button type="submit" class="colored">Войти</button>
          <button type="button" id="closeJoinModal" class="colored">Отмена</button>
        </div>
      </form>
    </div>
  </div>

  <div id="toast" class="toast hidden"></div>

  <!-- СКРИПТЫ -->
  <script>
    const b_colors = ["rgba(249, 164, 27, 0.5)", "hsla(107, 46.20%, 50.40%, 0.5)", "rgba(238, 29, 36, 0.5)", "rgb(39, 131, 197, 0.5)"];
    const border_colors = ["rgb(249, 165, 27)", "rgb(96, 187, 70)", "rgb(238, 29, 35)", "rgb(39, 131, 197)"];
    const input_colors = [...border_colors];
    let colorIndex = 0;

    function delay(time) {
      return new Promise(resolve => setTimeout(resolve, time));
    }

    async function loadLobbies() {
      const container = document.getElementById("lobby_list");
      container.innerHTML = "<p>Загрузка...</p>";

      setInterval( async () => {
        try {
          const res = await fetch("../api/get_lobbies.php");
          const lobbies = await res.json();

          container.innerHTML = lobbies.length === 0 ? "<p>Нет доступных лобби</p>" : "";

          lobbies.forEach((lobby, i) => {
            const card = document.createElement("div");
            card.className = "lobby-card";
            card.style.backgroundColor = b_colors[i % b_colors.length];

            card.innerHTML = `
              <div class="card_info">
                <div class="line"><h3>${lobby.name}</h3></div>
                <div class="line">
                  <p class="status-${lobby.state}">Статус: ${lobby.state}</p>
                  <p>Игроков: ${lobby.players_count}/${lobby.max_players}</p>
                </div>
              </div>`;

            const btn = document.createElement("button");
            btn.className = "colored openJoinModal";
            btn.textContent = "Войти";
            btn.dataset.lobbyId = lobby.id;
            btn.addEventListener("click", () => {
              document.getElementById("joinLobbyId").value = lobby.id;
              document.getElementById("join_modal").classList.remove("hidden");
            });

            const wrapper = document.createElement("div");
            wrapper.className = "modal-buttons";
            wrapper.appendChild(btn);
            card.appendChild(wrapper);
            container.appendChild(card);
          });
        } catch (error) {
          container.innerHTML = "<p style='color:red'>Ошибка загрузки лобби</p>";
          console.error("Ошибка:", error);
        }
      }, 3000);
    }

    function bindModal(openId, closeId, modalId) {
      const open = openId ? document.getElementById(openId) : null;
      const close = document.getElementById(closeId);
      const modal = document.getElementById(modalId);

      if ((openId === "" || open) && close && modal) {
        if (open) open.addEventListener("click", () => modal.classList.remove("hidden"));
        close.addEventListener("click", () => modal.classList.add("hidden"));
        window.addEventListener("click", e => {
          if (e.target === modal) modal.classList.add("hidden");
        });
      }
    }

    window.addEventListener("DOMContentLoaded", () => {
      loadLobbies();

      bindModal("openLobbyModal", "closeLobbyModal", "lobby_modal");
      bindModal("openNameModal", "closeNameModal", "name_modal");
      bindModal("openRuleModal", "closeRuleModal", "rule_modal");
      bindModal("", "closeJoinModal", "join_modal");

      // Новый обработчик формы смены имени
      const nameForm = document.getElementById("nameChangeForm");
      nameForm.addEventListener("submit", async (e) => {
        e.preventDefault();

        const nickname = document.getElementById("nicknameInput").value.trim();
        if (!nickname) {
          alert("Введите имя");
          return;
        }

        try {
          const res = await fetch("../api/change_name.php", {
            method: "POST",
            headers: {
              "Content-Type": "application/json"
            },
            body: JSON.stringify({ nickname })
          });

          const result = await res.json();

          if (result.success) {
            showToast("Имя успешно изменено!");
            document.getElementById("name_modal").classList.add("hidden");
          } else {
            showToast(result.error || "Ошибка при смене имени");
          }
        } catch (err) {
          console.error("Ошибка при отправке запроса:", err);
          alert("Произошла ошибка при отправке запроса");
        }
      });
    });

    document.getElementById("logoutBtn").addEventListener("click", async () => {
      try {
        const res = await fetch("../api/logout.php", {
          method: "POST"
        });

        const result = await res.json();

        if (result.success) {
          document.cookie = "auth_token=; Max-Age=0; path=/;";
          window.location.href = "auth.php";
        } else {
          showToast(result.error || "Ошибка выхода");
        }
      } catch (err) {
        console.error("Ошибка выхода:", err);
        alert("Ошибка при попытке выхода");
      }
    });

    document.getElementById("joinLobbyForm").addEventListener("submit", async (e) => {
      e.preventDefault();

      const password = document.getElementById("lobbyPassword").value.trim();
      const lobbyId = document.getElementById("joinLobbyId").value;

      if (!password || !lobbyId) {
        alert("Введите пароль");
        return;
      }

      try {
        const res = await fetch("../api/join_lobby.php", {
          method: "POST",
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            password: password,
            lobby_id: lobbyId
          })
        });

        const result = await res.json();

        if (result.success) {
          window.location.href = "../index.html";
        } else {
          showToast(result.error || "Ошибка при входе в лобби");
        }
      } catch (err) {
        console.error("Ошибка запроса:", err);
        alert("Произошла ошибка при подключении к серверу");
      }
    });
    
    document.getElementById("createLobbyForm").addEventListener("submit", async (e) => {
      e.preventDefault();

      const name = document.getElementById("lobbyName").value.trim();
      const password = document.getElementById("lobbyPasswordC").value.trim();
      const turnTime = parseInt(document.getElementById("turnTime").value);
      const req_players = parseInt(document.getElementById("req_players").value);

      if (!name || !turnTime) {
        showToast("Заполните все поля");
        return;
      }

      try {
        const res = await fetch("../api/create_lobby.php", {
          method: "POST",
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            lobby_name: name,
            password: password,
            turn_time: turnTime,
            req_players: req_players 
          })
        });

        const result = await res.json();

        if (result.success) {
          showToast("Лобби создано");
          await delay(1000);
          window.location.href = "../index.html";
        } else {
          showToast(result.error || "Ошибка создания лобби");
        }
      } catch (err) {
        console.error("Ошибка:", err);
        showToast("Ошибка при подключении к серверу");
      }
    });


  </script>

  <script>
    function showToast(message, duration = 3000) {
      const toast = document.getElementById("toast");
      toast.textContent = message;
      toast.classList.add("show");
      toast.classList.remove("hidden");

      setTimeout(() => {
        toast.classList.remove("show");
        toast.classList.add("hidden");
      }, duration);
    }
  </script>




</body>

</html>