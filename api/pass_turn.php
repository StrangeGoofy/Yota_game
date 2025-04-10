<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once '../config/db_connect.php';
header('Content-Type: application/json');

$data = json_decode(file_get_contents('php://input'), true);

// Чтение токена из куки
$token = $_COOKIE['auth_token'] ?? null;

if (!$token) {
    echo json_encode(['success' => false, 'error' => 'Missing token']);
    exit;
}


try {
    $stmt = $pdo->prepare("SELECT s314500.game_pass_turn(:token::uuid)");
    $stmt->bindParam(':token', $token, PDO::PARAM_STR);
    $stmt->execute();

    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result) {
        echo json_encode(['success' => true]);
    } else {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Не удалось пропустить ход'], JSON_UNESCAPED_UNICODE);
    }
    
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
    exit;
}
