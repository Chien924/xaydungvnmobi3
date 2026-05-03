<?php
// app-dang-ky-api.php
// API đăng ký tài khoản app Xây Dựng VN.
// Lưu tại: C:\Data\AppCore\public\app-dang-ky-api.php

@session_start();

require_once __DIR__ . '/api/v1/_config.php';
require_once __DIR__ . '/api/v1/_token.php';

if (!function_exists('api_response')) {
    function api_response($success, $message = '', $data = [], $code = 200) {
        http_response_code($code);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(array_merge([
            'success' => (bool)$success,
            'message' => $message,
        ], is_array($data) ? $data : []), JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
}

function app_get_db() {
    foreach (['conn', 'connect', 'mysqli', 'db', 'link'] as $name) {
        if (isset($GLOBALS[$name]) && $GLOBALS[$name] instanceof mysqli) {
            $GLOBALS[$name]->set_charset('utf8mb4');
            return $GLOBALS[$name];
        }
    }
    return null;
}

function app_input() {
    $data = [];

    if (function_exists('get_json_input')) {
        $json = get_json_input();
        if (is_array($json)) {
            $data = array_merge($data, $json);
        }
    } else {
        $raw = file_get_contents('php://input');
        if ($raw) {
            $json = json_decode($raw, true);
            if (is_array($json)) {
                $data = array_merge($data, $json);
            }
        }
    }

    if (!empty($_POST)) {
        $data = array_merge($data, $_POST);
    }

    if (!empty($_GET)) {
        $data = array_merge($data, $_GET);
    }

    return $data;
}

function app_val($input, $keys) {
    foreach ($keys as $k) {
        if (isset($input[$k]) && trim((string)$input[$k]) !== '') {
            return trim((string)$input[$k]);
        }
    }
    return '';
}

function app_has_table($db, $table) {
    $table = $db->real_escape_string($table);
    $rs = @$db->query("SHOW TABLES LIKE '{$table}'");
    return $rs && $rs->num_rows > 0;
}

function app_columns($db, $table) {
    $cols = [];
    $table = str_replace('`', '', $table);
    $rs = @$db->query("SHOW COLUMNS FROM `{$table}`");
    if ($rs) {
        while ($r = $rs->fetch_assoc()) {
            $cols[] = $r['Field'];
        }
    }
    return $cols;
}

function app_pick_col($cols, $names) {
    foreach ($names as $name) {
        if (in_array($name, $cols, true)) {
            return $name;
        }
    }
    return null;
}

function app_bind_dynamic($stmt, $types, &$values) {
    $refs = [];
    $refs[] = $types;
    foreach ($values as $k => &$v) {
        $refs[] = &$v;
    }
    return call_user_func_array([$stmt, 'bind_param'], $refs);
}

function app_find_user_table($db) {
    foreach (['users', 'account', 'accounts', 'user'] as $t) {
        if (app_has_table($db, $t)) {
            return $t;
        }
    }
    return null;
}

function app_get_account_map($db, $table) {
    $cols = app_columns($db, $table);

    return [
        'columns' => $cols,
        'idCol' => app_pick_col($cols, ['id', 'user_id', 'account_id']),
        'userCol' => app_pick_col($cols, ['username', 'usersname', 'user_name', 'tai_khoan', 'taikhoan', 'user']),
        'passCol' => app_pick_col($cols, ['password', 'mat_khau', 'matkhau', 'pass']),
        'phoneCol' => app_pick_col($cols, ['sdt', 'phone', 'so_dien_thoai', 'mobile']),
        'nameCol' => app_pick_col($cols, ['name', 'ho_ten', 'ten', 'full_name']),
        'moneyCol' => app_pick_col($cols, ['sodu', 'so_du', 'balance', 'vnd']),
        'roleCol' => app_pick_col($cols, ['role', 'phan_quyen']),
        'activeCol' => app_pick_col($cols, ['active', 'status', 'trang_thai']),
        'createdCol' => app_pick_col($cols, ['created_at', 'create_time', 'ngay_tao']),
        'updatedCol' => app_pick_col($cols, ['updated_at', 'update_time', 'ngay_cap_nhat']),
    ];
}

function app_exists_value($db, $table, $col, $value) {
    if (!$col || $value === '') {
        return false;
    }

    $sql = "SELECT `$col` FROM `$table` WHERE `$col` = ? LIMIT 1";
    $stmt = $db->prepare($sql);
    if (!$stmt) {
        api_response(false, 'Lỗi kiểm tra dữ liệu trùng: ' . $db->error, [], 500);
    }

    $stmt->bind_param('s', $value);
    $stmt->execute();
    $rs = $stmt->get_result();
    $exists = $rs && $rs->num_rows > 0;
    $stmt->close();

    return $exists;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $db = app_get_db();
    $table = $db ? app_find_user_table($db) : null;
    $map = ($db && $table) ? app_get_account_map($db, $table) : [];

    api_response(true, 'API đăng ký đã sẵn sàng.', [
        'db_connected' => (bool)$db,
        'table' => $table,
        'columns' => $map['columns'] ?? [],
        'duplicate_check' => [
            'username' => $map['userCol'] ?? null,
            'phone' => $map['phoneCol'] ?? null,
        ],
    ]);
}

$db = app_get_db();
if (!$db) {
    api_response(false, 'Không lấy được kết nối database từ api/v1/_config.php.', [], 500);
}

$input = app_input();

$username = app_val($input, ['username', 'usersname', 'user', 'tai_khoan', 'taikhoan']);
$password = app_val($input, ['password', 'mat_khau', 'matkhau', 'pass']);
$confirm  = app_val($input, ['password2', 'confirm_password', 'password_confirmation', 'nhap_lai_mat_khau']);
$phone    = app_val($input, ['sdt', 'phone', 'so_dien_thoai', 'mobile']);
$name     = app_val($input, ['name', 'ho_ten', 'ten', 'full_name']);

$username = preg_replace('/\s+/', '', $username);
$phone = preg_replace('/\s+/', '', $phone);

if ($username === '') {
    api_response(false, 'Vui lòng nhập tên tài khoản.', [], 400);
}

if ($password === '') {
    api_response(false, 'Vui lòng nhập mật khẩu.', [], 400);
}

if (!preg_match('/^[a-zA-Z0-9_\.]{4,32}$/', $username)) {
    api_response(false, 'Tên tài khoản từ 4 đến 32 ký tự, chỉ dùng chữ, số, dấu gạch dưới.', [], 400);
}

if (strlen($password) < 4) {
    api_response(false, 'Mật khẩu quá ngắn.', [], 400);
}

if ($confirm !== '' && $confirm !== $password) {
    api_response(false, 'Mật khẩu nhập lại không khớp.', [], 400);
}

if ($phone !== '' && !preg_match('/^[0-9]{9,12}$/', $phone)) {
    api_response(false, 'Số điện thoại không hợp lệ.', [], 400);
}

$table = app_find_user_table($db);
if (!$table) {
    api_response(false, 'Không tìm thấy bảng tài khoản users/account.', [], 500);
}

$map = app_get_account_map($db, $table);
$cols = $map['columns'];

$userCol = $map['userCol'];
$passCol = $map['passCol'];
$phoneCol = $map['phoneCol'];
$nameCol = $map['nameCol'];
$moneyCol = $map['moneyCol'];
$roleCol = $map['roleCol'];
$activeCol = $map['activeCol'];
$createdCol = $map['createdCol'];
$updatedCol = $map['updatedCol'];

if (!$userCol || !$passCol) {
    api_response(false, 'Không xác định được cột tài khoản hoặc mật khẩu.', [
        'table' => $table,
        'columns' => $cols,
    ], 500);
}

if (app_exists_value($db, $table, $userCol, $username)) {
    api_response(false, 'Tên tài khoản đã tồn tại.', [
        'field' => 'username',
    ], 409);
}

if ($phoneCol && $phone !== '' && app_exists_value($db, $table, $phoneCol, $phone)) {
    api_response(false, 'Số điện thoại đã được đăng ký.', [
        'field' => 'phone',
    ], 409);
}

$insertCols = [];
$insertVals = [];
$types = '';

$insertCols[] = $userCol;
$insertVals[] = $username;
$types .= 's';

// Giữ plain text để tương thích hệ thống đăng nhập hiện tại.
// Nếu web chuyển sang password_hash thì cần sửa cả login API.
$insertCols[] = $passCol;
$insertVals[] = $password;
$types .= 's';

if ($phoneCol && $phone !== '') {
    $insertCols[] = $phoneCol;
    $insertVals[] = $phone;
    $types .= 's';
}

if ($nameCol && $name !== '') {
    $insertCols[] = $nameCol;
    $insertVals[] = $name;
    $types .= 's';
}

if ($moneyCol) {
    $insertCols[] = $moneyCol;
    $insertVals[] = 0;
    $types .= 'i';
}

if ($roleCol) {
    $insertCols[] = $roleCol;
    $insertVals[] = 'user';
    $types .= 's';
}

if ($activeCol) {
    $insertCols[] = $activeCol;
    $insertVals[] = 1;
    $types .= 'i';
}

$now = date('Y-m-d H:i:s');

if ($createdCol) {
    $insertCols[] = $createdCol;
    $insertVals[] = $now;
    $types .= 's';
}

if ($updatedCol && $updatedCol !== $createdCol) {
    $insertCols[] = $updatedCol;
    $insertVals[] = $now;
    $types .= 's';
}

$colsSql = '`' . implode('`,`', $insertCols) . '`';
$placeholders = implode(',', array_fill(0, count($insertCols), '?'));
$sql = "INSERT INTO `$table` ($colsSql) VALUES ($placeholders)";

$stmt = $db->prepare($sql);
if (!$stmt) {
    api_response(false, 'Lỗi chuẩn bị tạo tài khoản: ' . $db->error, [
        'table' => $table,
        'columns' => $cols,
    ], 500);
}

app_bind_dynamic($stmt, $types, $insertVals);

if (!$stmt->execute()) {
    $err = $stmt->error;
    $stmt->close();

    if (stripos($err, 'Duplicate') !== false) {
        api_response(false, 'Tên tài khoản hoặc số điện thoại đã tồn tại.', [], 409);
    }

    api_response(false, 'Lỗi tạo tài khoản: ' . $err, [], 500);
}

$userId = (int)$stmt->insert_id;
$stmt->close();

if (!$userId && $map['idCol']) {
    $idCol = $map['idCol'];
    $stmt = $db->prepare("SELECT `$idCol` AS id FROM `$table` WHERE `$userCol` = ? LIMIT 1");
    if ($stmt) {
        $stmt->bind_param('s', $username);
        $stmt->execute();
        $rs = $stmt->get_result();
        if ($rs && ($r = $rs->fetch_assoc())) {
            $userId = (int)$r['id'];
        }
        $stmt->close();
    }
}

$token = '';
if (function_exists('issue_app_token')) {
    $token = issue_app_token($userId, $username);
}

api_response(true, 'Tạo tài khoản thành công.', [
    'token' => $token,
    'user' => [
        'id' => $userId,
        'username' => $username,
        'sdt' => $phone,
        'sodu' => 0,
    ],
]);
