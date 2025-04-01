<?php
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Неверный метод запроса']);
    exit;
}

$username = trim($_POST['username'] ?? '');
$password = trim($_POST['password'] ?? '');

if (empty($username) || empty($password)) {
    echo json_encode(['success' => false, 'message' => 'Пожалуйста, заполните все поля!']);
    exit;
}

try {
    require_once '../config/db_connect.php';

    $stmt = $pdo->prepare("SELECT auth_login(:username, :password) AS token");
    $stmt->execute([
        ':username' => $username,
        ':password' => $password
    ]);

    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result && isset($result['token'])) {
        $tk = $result["token"];
        setcookie("auth_token", $tk, time() + (86400 * 30), "/", "", false, true);
        echo json_encode([
            'success' => true,
            'message' => 'Вход успешен!',
            'redirect' => 'dashboard.php',
            'token' => $tk
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Неверный логин или пароль'
        ], JSON_UNESCAPED_UNICODE);
    }

} catch (PDOException $e) {
    $msg = $e->getMessage();
    if (strpos($msg, 'Unknown user') !== false) {
        echo json_encode(['success' => false, 'message' => 'Пользователь не найден'], JSON_UNESCAPED_UNICODE);
    } elseif (strpos($msg, 'Wrong password') !== false) {
        echo json_encode(['success' => false, 'message' => 'Неверный пароль'], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode(['success' => false, 'message' => 'Ошибка базы данных: ' . $msg], JSON_UNESCAPED_UNICODE);
    }
}
