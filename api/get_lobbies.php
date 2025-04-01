<?php
header('Content-Type: application/json');
require_once '../config/db_connect.php';

try {
    $stmt = $pdo->query("SELECT auth_get_lobbies_list() AS lobbies");
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result && isset($result['lobbies'])) {
        echo $result['lobbies']; // уже JSON
    } else {
        echo json_encode([]);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка при получении лобби: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
?>
