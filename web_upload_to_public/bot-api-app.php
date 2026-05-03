<?php
// bot-api-app.php
// Cầu nối để app đăng nhập bằng token nhưng bot cũ vẫn nhận được $_SESSION.
// Lưu tại: C:\Data\AppCore\public\bot-api-app.php

@session_start();

$token = '';

if (isset($_POST['token'])) {
    $token = trim((string)$_POST['token']);
} elseif (isset($_POST['app_token'])) {
    $token = trim((string)$_POST['app_token']);
} elseif (isset($_GET['token'])) {
    $token = trim((string)$_GET['token']);
} elseif (!empty($_SERVER['HTTP_AUTHORIZATION']) && stripos($_SERVER['HTTP_AUTHORIZATION'], 'Bearer ') === 0) {
    $token = trim(substr($_SERVER['HTTP_AUTHORIZATION'], 7));
} elseif (function_exists('apache_request_headers')) {
    $headers = apache_request_headers();
    if (!empty($headers['Authorization']) && stripos($headers['Authorization'], 'Bearer ') === 0) {
        $token = trim(substr($headers['Authorization'], 7));
    }
}

if ($token !== '') {
    require_once __DIR__ . '/api/v1/_token.php';

    $payload = verify_app_token($token);

    if (is_array($payload) && !empty($payload['uid'])) {
        $uid = (int)$payload['uid'];
        $username = (string)($payload['username'] ?? '');

        // Set thật nhiều key session phổ biến để bot/web cũ nhận là đã đăng nhập.
        $_SESSION['user_id'] = $uid;
        $_SESSION['userid'] = $uid;
        $_SESSION['id'] = $uid;
        $_SESSION['_id'] = $uid;
        $_SESSION['account_id'] = $uid;

        $_SESSION['username'] = $username;
        $_SESSION['_username'] = $username;
        $_SESSION['usersname'] = $username;
        $_SESSION['user_name'] = $username;

        $_SESSION['login'] = true;
        $_SESSION['logged_in'] = true;
        $_SESSION['is_login'] = true;
        $_SESSION['is_logged_in'] = true;

        $_SESSION['user'] = [
            'id' => $uid,
            'user_id' => $uid,
            'username' => $username,
            'usersname' => $username,
        ];
    }
}

// Chạy bot API cũ của bạn.
$botFile = __DIR__ . '/bot chat/bot-api.php';

if (is_file($botFile)) {
    require $botFile;
    exit;
}

header('Content-Type: application/json; charset=utf-8');
http_response_code(404);
echo json_encode([
    'ok' => false,
    'success' => false,
    'message' => 'Không tìm thấy bot chat/bot-api.php',
], JSON_UNESCAPED_UNICODE);
