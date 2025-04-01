<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once '../config/db_connect.php';
header('Content-Type: application/json');

$data = json_decode(file_get_contents('php://input'), true);

// Чтение токена из куки
$token = $_COOKIE['auth_token'] ?? null;
$cards = $data['cards'] ?? null;

if (!$token) {
    echo json_encode(['success' => false, 'error' => 'Missing token']);
    exit;
}

if (!$cards) {
    echo json_encode(['success' => false, 'error' => 'Missing cards']);
    exit;
}

try {
    $stmt = $pdo->prepare("SELECT s314500.game_play_cards(:token::uuid, :cards::jsonb)");
    $cardsJson = json_encode($cards); // Вынеси отдельно переменную (исправление warning'а PHP!)
    $stmt->bindParam(':token', $token, PDO::PARAM_STR);
    $stmt->bindParam(':cards', $cardsJson, PDO::PARAM_STR);
    $stmt->execute();

    $result = $stmt->fetchColumn();

    echo json_encode(['success' => true, 'result' => $result]);
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
    exit;
}
