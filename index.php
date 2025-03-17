<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Карточная игра</title>
    <link rel="stylesheet" href="assets/css/styles.css">
</head>
<body>
    <div id="game-container">
        <div id="game-board"></div>
        <div id="player-hand"></div>
    </div>
    <div class="ui">
        <button id="endTurnButton">Завершить ход</button>
    </div>

    <!-- Подключаем основной JS как модуль -->
    <script type="module" src="assets/js/engine.js"></script>
</body>
</html>
