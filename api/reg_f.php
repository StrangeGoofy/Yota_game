<?php
// Включаем вывод ошибок для отладки
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Заголовок, чтобы браузер понимал, что это JSON
header('Content-Type: application/json');

try {
    // Подключение к БД
    require_once '../config/db_connect.php';

    // Проверка метода запроса (только POST)
    if ($_SERVER["REQUEST_METHOD"] !== "POST") {
        echo json_encode(["status" => "error", "message" => "Метод запроса должен быть POST"], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Проверяем, пришли ли данные
    if (!isset($_POST["username"], $_POST["password"], $_POST["nickname"])) {
        echo json_encode(["status" => "error", "message" => "Заполните все поля"], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Получаем и очищаем входные данные
    $username = trim($_POST["username"]);
    $password = trim($_POST["password"]);
    $nickname = trim($_POST["nickname"]);

    if (empty($username) || empty($password) || empty($nickname)) {
        echo json_encode(["status" => "error", "message" => "Все поля обязательны"], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Вызываем хранимую функцию auth_register_user в PostgreSQL
    $stmt = $pdo->prepare("SELECT auth_register_user(:username, :password, :nickname) AS token");
    $stmt->execute([
        "username" => $username,
        "password" => $password,
        "nickname" => $nickname
    ]);

    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    // Если функция вернула токен — регистрация успешна
    if ($result && isset($result["token"])) {
        setcookie("auth_token", $result["token"], time() + (86400 * 30), "/", "", false, true);
        echo json_encode([
            "success" => true,
            "message" => "Регистрация успешна!", 
            "token" => $result["token"]
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode(["success" => false, 
        "message" => "Ошибка регистрации"
    ], JSON_UNESCAPED_UNICODE);
    }
} catch (PDOException $e) {
    $msg = $e->getMessage();

    if (strpos($msg, 'User with this username exists') !== false) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Пользователь с таким логином уже существует'
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode([
            'status' => 'error',
            'message' => 'Ошибка базы данных: ' . $msg
        ], JSON_UNESCAPED_UNICODE);
    }
}
?>
