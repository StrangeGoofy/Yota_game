<?php
header('Content-Type: application/json');
require_once '../config/db_connect.php';

try {
    if (!isset($_COOKIE['auth_token'])) {
        http_response_code(401);
        echo json_encode(['error' => 'Пользователь не авторизован'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $token = $_COOKIE['auth_token'];

    // Чтение JSON тела
    $input = json_decode(file_get_contents('php://input'), true);
    $password = isset($input['password']) ? trim($input['password']) : '';
    $lobby_id = isset($input['lobby_id']) ? (int)$input['lobby_id'] : 0;

    if (empty($password) || $lobby_id <= 0) {
        http_response_code(400);
        echo json_encode(['error' => 'Неверные входные данные'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmt = $pdo->prepare("SELECT s314500.auth_join_lobby(:token, :lobby_id, :password) AS success");
    $stmt->execute([
        ':token' => $token,
        ':lobby_id' => $lobby_id,
        ':password' => $password
    ]);

    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result && $result['success']) {
        echo json_encode(['success' => true]);
    } else {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Не удалось войти в лобби'], JSON_UNESCAPED_UNICODE);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
?>
