<?php
header('Content-Type: application/json');
require_once '../config/db_connect.php';

try {
    if (!isset($_COOKIE['auth_token'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Токен не найден в cookie'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $token = $_COOKIE['auth_token'];

    // Вызываем функцию logout в БД
    $stmt = $pdo->prepare("SELECT s314500.auth_logout(:token) AS success");
    $stmt->execute([':token' => $token]);

    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    // Очищаем куку (на всякий случай с серверной стороны)
    setcookie('auth_token', '', time() - 3600, '/');

    if ($result && $result['success']) {
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false, 'error' => 'Токен не найден или уже удалён'], JSON_UNESCAPED_UNICODE);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка при выходе: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
?>
