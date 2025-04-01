<?php
require_once '../config/db_connect.php';

header('Content-Type: application/json');

// Получаем JSON из тела запроса
$data = json_decode(file_get_contents('php://input'), true);

// Извлекаем токен
$token = $_COOKIE['auth_token'];

if (!$token) {
    echo json_encode(['error' => 'Token not provided']);
    exit;
}

try {
    // Предполагаем, что get_game_json — это функция в БД, которая принимает токен
    $stmt = $pdo->prepare("SELECT game_get_state_json(:token)");
    $stmt->bindParam(':token', $token, PDO::PARAM_STR);
    $stmt->execute();

    // Получаем результат функции
    $result = $stmt->fetchColumn();

    if ($result) {
        // Предполагаем, что функция уже возвращает JSON, поэтому просто декодируем и отдаем как объект
        echo $result;
    } else {
        echo json_encode(['error' => 'Game data not found']);
    }
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
