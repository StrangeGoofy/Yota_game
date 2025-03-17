<?php
// public_html/config/db_connect.php

// Подключаем настройки из config.php
$config = require_once __DIR__ . '/config.php';

$host        = $config['db_host'];
$db          = $config['db_name'];
$db_user     = $config['db_user'];
$db_password = $config['db_password'];
$port        = $config['db_port'];

// Формируем DSN для PostgreSQL
$dsn = "pgsql:host={$host};port={$port};dbname={$db};";

try {
    // Создаем подключение через PDO
    $pdo = new PDO($dsn, $db_user, $db_password, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
    // Вывод сообщения в консоль браузера об успешном подключении
    echo "<script>console.log('Подключение к базе данных успешно установлено');</script>";
} catch (PDOException $e) {
    die("Ошибка подключения к базе данных: " . $e->getMessage());
}
?>
