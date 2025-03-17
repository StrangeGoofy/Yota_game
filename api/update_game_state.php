<?php
require_once '../config/db_connect.php';

header('Content-Type: application/json');

$data = json_decode(file_get_contents('php://input'), true);
$game_id = $data['game_id'] ?? null;
$new_state = json_encode($data['state'] ?? []);

if (!$game_id) {
    echo json_encode(['error' => 'Game ID not provided']);
    exit;
}

try {
    $stmt = $pdo->prepare("CALL update_game_state(:game_id, :state)");
    $stmt->bindParam(':game_id', $game_id, PDO::PARAM_INT);
    $stmt->bindParam(':state', $new_state, PDO::PARAM_STR);
    $stmt->execute();

    echo json_encode(['success' => true]);
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>
