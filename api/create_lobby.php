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
    $input = json_decode(file_get_contents('php://input'), true);

    $name = isset($input['lobby_name']) ? trim($input['lobby_name']) : '';
    $password = isset($input['password']) ? trim($input['password']) : '';
    $turn_time = isset($input['turn_time']) ? (int)$input['turn_time'] : 60;
    $req_players = isset($input['req_players']) ? (int)$input['req_players'] : 2;

    //echo $req_players;

    if (empty($name)) {
        http_response_code(400);
        echo json_encode(['error' => 'Название лобби обязательно'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmt = $pdo->prepare("SELECT s314500.auth_create_lobby(:token, :name, :password, :turn_time, :req_players) AS lobby_id");
    $stmt->execute([
        ':token' => $token,
        ':name' => $name,
        ':password' => $password,
        ':turn_time' => $turn_time,
        ':req_players' => $req_players
    ]);

    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result && $result['lobby_id']) {
        echo json_encode(['success' => true, 'lobby_id' => $result['lobby_id']]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Не удалось создать лобби'], JSON_UNESCAPED_UNICODE);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
?>
