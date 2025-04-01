<?php
header('Content-Type: application/json');
require_once '../config/db_connect.php';

try {
    // Получаем токен из cookie
    if (!isset($_COOKIE['auth_token'])) {
        http_response_code(401);
        echo json_encode(['error' => 'Токен не найден в cookie'], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $token = $_COOKIE['auth_token'];

    // Получаем новое имя из тела POST-запроса (ожидаем JSON)
    $input = json_decode(file_get_contents('php://input'), true);
    if (!isset($input['nickname']) || empty(trim($input['nickname']))) {
        http_response_code(400);
        echo json_encode(['error' => 'Никнейм не передан или пустой'], JSON_UNESCAPED_UNICODE);
        exit;
    }
    $nickname = trim($input['nickname']);

    // Вызываем функцию в БД — теперь она может кидать EXCEPTION
    $stmt = $pdo->prepare("SELECT s314500.auth_change_nickname(:token, :nickname) AS success");
    $stmt->execute([
        ':token' => $token,
        ':nickname' => $nickname
    ]);

    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    // Если дошли сюда — EXCEPTION не было, и всё ок
    if ($result && $result['success']) {
        echo json_encode(['success' => true]);
    } else {
        // Функция вернула false — что-то не так, но без EXCEPTION
        echo json_encode(['success' => false, 'error' => 'Не удалось изменить никнейм'], JSON_UNESCAPED_UNICODE);
    }

} catch (PDOException $e) {
    // Перехватываем EXCEPTION из PostgreSQL
    http_response_code(500);
    echo json_encode(['error' => 'Ошибка: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
?>
