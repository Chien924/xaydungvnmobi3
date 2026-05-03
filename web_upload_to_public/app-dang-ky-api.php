<?php
// app-dang-ky-api.php
// API đăng ký tài khoản app Xây Dựng VN.
// Đặt tại: C:\Data\AppCore\public\app-dang-ky-api.php

@session_start();

require_once __DIR__ . '/api/v1/_config.php';
require_once __DIR__ . '/api/v1/_token.php';

if (!function_exists('api_response')) {
    function api_response($success, $message = '', $data = [], $status = 200) {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(array_merge([
            'success' => (bool)$success,
            'message' => $message,
        ], is_array($data) ? $data : []), JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
}

function app_db() {
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
        if (is_array($json)) $data = array_merge($data, $json);
    } else {
        $raw = file_get_contents('php://input');
        if ($raw) {
            $json = json_decode($raw, true);
            if (is_array($json)) $data = array_merge($data, $json);
        }
    }
    if (!empty($_POST)) $data = array_merge($data, $_POST);
    return $data;
}

function val($data, $keys) {
    foreach ($keys as $k) {
        if (isset($data[$k]) && trim((string)$data[$k]) !== '') return trim((string)$data[$k]);
    }
    return '';
}

function has_table($db, $table) {
    $t = $db->real_escape_string($table);
    $rs = @$db->query("SHOW TABLES LIKE '{$t}'");
    return $rs && $rs->num_rows > 0;
}

function cols($db, $table) {
    $out = [];
    $table = str_replace('`', '', $table);
    $rs = @$db->query("SHOW COLUMNS FROM `{$table}`");
    if ($rs) while ($r = $rs->fetch_assoc()) $out[] = $r['Field'];
    return $out;
}

function pick($cols, $names) {
    foreach ($names as $n) if (in_array($n, $cols, true)) return $n;
    return null;
}

function bind_params($stmt, $types, &$values) {
    $refs = [$types];
    foreach ($values as &$v) $refs[] = &$v;
    return call_user_func_array([$stmt, 'bind_param'], $refs);
}

function exists_value($db, $table, $col, $value) {
    if (!$col || $value === '') return false;
    $stmt = $db->prepare("SELECT `$col` FROM `$table` WHERE `$col` = ? LIMIT 1");
    if (!$stmt) api_response(false, 'Lỗi kiểm tra dữ liệu trùng: '.$db->error, [], 500);
    $stmt->bind_param('s', $value);
    $stmt->execute();
    $rs = $stmt->get_result();
    $ok = $rs && $rs->num_rows > 0;
    $stmt->close();
    return $ok;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    api_response(true, 'API đăng ký đã sẵn sàng.');
}

$db = app_db();
if (!$db) api_response(false, 'Không lấy được kết nối database.', [], 500);

$data = app_input();

$username = preg_replace('/\s+/', '', val($data, ['username','usersname','user','tai_khoan']));
$phone = preg_replace('/\s+/', '', val($data, ['sdt','phone','so_dien_thoai','mobile']));
$password = val($data, ['password','mat_khau','pass']);
$password2 = val($data, ['password2','confirm_password','password_confirmation']);

if ($username === '') api_response(false, 'Vui lòng nhập tên tài khoản.', [], 400);
if ($password === '') api_response(false, 'Vui lòng nhập mật khẩu.', [], 400);
if (!preg_match('/^[a-zA-Z0-9_\.]{4,32}$/', $username)) {
    api_response(false, 'Tên tài khoản từ 4 đến 32 ký tự, chỉ dùng chữ, số hoặc dấu gạch dưới.', [], 400);
}
if ($phone === '') api_response(false, 'Vui lòng nhập số điện thoại.', [], 400);
if (!preg_match('/^[0-9]{9,12}$/', $phone)) api_response(false, 'Số điện thoại không hợp lệ.', [], 400);
if (strlen($password) < 4) api_response(false, 'Mật khẩu quá ngắn.', [], 400);
if ($password2 !== '' && $password2 !== $password) api_response(false, 'Mật khẩu nhập lại không khớp.', [], 400);

$table = null;
foreach (['users','account','accounts','user'] as $t) {
    if (has_table($db, $t)) { $table = $t; break; }
}
if (!$table) api_response(false, 'Không tìm thấy bảng tài khoản.', [], 500);

$columns = cols($db, $table);

$idCol = pick($columns, ['id','user_id','account_id']);
$userCol = pick($columns, ['username','usersname','user_name','tai_khoan','taikhoan','user']);
$passCol = pick($columns, ['password','mat_khau','matkhau','pass']);
$phoneCol = pick($columns, ['sdt','phone','so_dien_thoai','mobile']);
$moneyCol = pick($columns, ['sodu','so_du','balance','vnd']);
$roleCol = pick($columns, ['role','phan_quyen']);
$activeCol = pick($columns, ['active','status','trang_thai']);
$createdCol = pick($columns, ['created_at','create_time','ngay_tao']);
$updatedCol = pick($columns, ['updated_at','update_time','ngay_cap_nhat']);

if (!$userCol || !$passCol) {
    api_response(false, 'Không xác định được cột tài khoản hoặc mật khẩu.', [
        'table' => $table,
        'columns' => $columns,
    ], 500);
}

if (exists_value($db, $table, $userCol, $username)) {
    api_response(false, 'Tên tài khoản đã tồn tại.', ['field' => 'username'], 409);
}

if ($phoneCol && exists_value($db, $table, $phoneCol, $phone)) {
    api_response(false, 'Số điện thoại đã được đăng ký.', ['field' => 'phone'], 409);
}

$insertCols = [$userCol, $passCol];
$insertVals = [$username, $password];
$types = 'ss';

if ($phoneCol) { $insertCols[] = $phoneCol; $insertVals[] = $phone; $types .= 's'; }
if ($moneyCol) { $insertCols[] = $moneyCol; $insertVals[] = 0; $types .= 'i'; }
if ($roleCol) { $insertCols[] = $roleCol; $insertVals[] = 'user'; $types .= 's'; }
if ($activeCol) { $insertCols[] = $activeCol; $insertVals[] = 1; $types .= 'i'; }

$now = date('Y-m-d H:i:s');
if ($createdCol) { $insertCols[] = $createdCol; $insertVals[] = $now; $types .= 's'; }
if ($updatedCol && $updatedCol !== $createdCol) { $insertCols[] = $updatedCol; $insertVals[] = $now; $types .= 's'; }

$sql = "INSERT INTO `$table` (`".implode('`,`',$insertCols)."`) VALUES (".implode(',', array_fill(0, count($insertCols), '?')).")";
$stmt = $db->prepare($sql);
if (!$stmt) api_response(false, 'Lỗi chuẩn bị tạo tài khoản: '.$db->error, [], 500);

bind_params($stmt, $types, $insertVals);

if (!$stmt->execute()) {
    $err = $stmt->error;
    $stmt->close();

    if (stripos($err, 'Duplicate') !== false) {
        api_response(false, 'Tên tài khoản hoặc số điện thoại đã tồn tại.', [], 409);
    }

    api_response(false, 'Tạo tài khoản thất bại: '.$err, [], 500);
}

$userId = (int)$stmt->insert_id;
$stmt->close();

if (!$userId && $idCol) {
    $stmt = $db->prepare("SELECT `$idCol` AS id FROM `$table` WHERE `$userCol` = ? LIMIT 1");
    if ($stmt) {
        $stmt->bind_param('s', $username);
        $stmt->execute();
        $rs = $stmt->get_result();
        if ($rs && ($r = $rs->fetch_assoc())) $userId = (int)$r['id'];
        $stmt->close();
    }
}

$token = '';
if (function_exists('issue_app_token')) $token = issue_app_token($userId, $username);

api_response(true, 'Tạo tài khoản thành công.', [
    'token' => $token,
    'user' => [
        'id' => $userId,
        'username' => $username,
        'sdt' => $phone,
        'sodu' => 0,
    ],
]);
