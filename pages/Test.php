<?php
    try {
        require_once '../config/db_connect.php';

        echo $_SERVER["REQUEST_METHOD"];

        // if ($_SERVER["REQUEST_METHOD"] !== "POST") {
        //     echo json_encode(["status" => "error", "message" => "Метод запроса должен быть POST"]);
        //     exit;
        // }

        $stmt = $pdo->prepare("SELECT hello_world() AS txt");
        $stmt->execute();

        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($result && isset($result["txt"])) {
            echo json_encode(["status" => "success", "message" => "Успеx!", "txt" => $result["txt"]], JSON_UNESCAPED_UNICODE);
        } else {
            echo json_encode(["status" => "error", "message" => "Ошибка"], JSON_UNESCAPED_UNICODE);
        }

    } catch (Exception $e) {
        echo ''. $e->getMessage() .'';
    }

    echo "sad";
?>
