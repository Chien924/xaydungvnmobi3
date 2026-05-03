<?php
// app-dang-ky-api.php - API test nhanh tạo tài khoản cho app.
// Lưu tại: C:\Data\AppCore\public\app-dang-ky-api.php
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

function out($ok, $msg, $extra = []) {
    echo json_encode(array_merge(['success' => $ok, 'message' => $msg], $extra), JSON_UNESCAPED_UNICODE);
    exit;
}

$root = __DIR__;
foreach (['config.php','connect.php','conn.php','set.php'] as $file) {
    $path = $root . DIRECTORY_SEPARATOR . $file;
    if (is_file($path)) { @require_once $path; }
}

$db = null;
if (isset($conn) && $conn instanceof mysqli) $db = $conn;
if (!$db && isset($connect) && $connect instanceof mysqli) $db = $connect;
if (!$db && isset($mysqli) && $mysqli instanceof mysqli) $db = $mysqli;
if (!$db) out(false, 'Chưa tìm thấy kết nối mysqli. Kiểm tra config.php/connect.php/conn.php.');
@$db->set_charset('utf8mb4');

$raw = file_get_contents('php://input');
$input = json_decode($raw, true);
if (!is_array($input)) $input = $_POST;

$username = trim($input['username'] ?? $input['user'] ?? $input['taikhoan'] ?? '');
$password = (string)($input['password'] ?? $input['matkhau'] ?? '');
$phone = trim($input['phone'] ?? $input['sdt'] ?? '');

if ($username === '' || $password === '') out(false, 'Thiếu tài khoản hoặc mật khẩu.');
if (!preg_match('/^[a-zA-Z0-9_.@\-]{3,50}$/', $username)) out(false, 'Tên tài khoản chỉ nên gồm chữ, số, dấu chấm, gạch dưới, gạch ngang.');
if (strlen($password) < 6) out(false, 'Mật khẩu tối thiểu 6 ký tự.');

$cols = [];
$res = $db->query("SHOW COLUMNS FROM `users`");
if (!$res) out(false, 'Không tìm thấy bảng users hoặc lỗi SHOW COLUMNS: ' . $db->error);
while ($r = $res->fetch_assoc()) $cols[$r['Field']] = $r;

function first_col($cols, $names) { foreach ($names as $n) if (isset($cols[$n])) return $n; return null; }
$userCol = first_col($cols, ['username','usersname','user_name','taikhoan','tai_khoan']);
$passCol = first_col($cols, ['password','mat_khau','matkhau','pass']);
$phoneCol = first_col($cols, ['sdt','phone','so_dien_thoai','dien_thoai']);
$balanceCol = first_col($cols, ['so_du','sodu','balance']);
if (!$userCol || !$passCol) out(false, 'Bảng users thiếu cột username/password tương thích.');

$stmt = $db->prepare("SELECT 1 FROM `users` WHERE `$userCol`=? LIMIT 1");
if (!$stmt) out(false, 'Lỗi prepare kiểm tra tài khoản: ' . $db->error);
$stmt->bind_param('s', $username);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) out(false, 'Tài khoản đã tồn tại.');
$stmt->close();

$insert = [];
$params = [];
$types = '';
$insert[$userCol] = $username;
// Dùng password_hash chuẩn. Nếu web cũ dùng md5/plain thì cần sửa login API để password_verify hoặc đổi lại tại đây.
$insert[$passCol] = password_hash($password, PASSWORD_DEFAULT);
if ($phoneCol) $insert[$phoneCol] = $phone;
if ($balanceCol) $insert[$balanceCol] = 0;
foreach (['created_at','ngay_tao'] as $c) if (isset($cols[$c])) $insert[$c] = date('Y-m-d H:i:s');
foreach (['updated_at','ngay_cap_nhat'] as $c) if (isset($cols[$c])) $insert[$c] = date('Y-m-d H:i:s');
foreach (['active','status'] as $c) if (isset($cols[$c])) $insert[$c] = 1;

$fields = array_keys($insert);
$place = array_fill(0, count($fields), '?');
$sql = "INSERT INTO `users` (`" . implode('`,`', $fields) . "`) VALUES (" . implode(',', $place) . ")";
$stmt = $db->prepare($sql);
if (!$stmt) out(false, 'Lỗi prepare insert: ' . $db->error);
foreach ($fields as $f) { $v = $insert[$f]; $params[] = $v; $types .= is_int($v) ? 'i' : 's'; }
$stmt->bind_param($types, ...$params);
if (!$stmt->execute()) out(false, 'Lỗi tạo tài khoản: ' . $stmt->error);
$id = $stmt->insert_id;

out(true, 'Tạo tài khoản thành công. Bạn có thể đăng nhập bằng tài khoản vừa tạo.', [
    'user' => ['id' => $id, 'username' => $username, 'phone' => $phone, 'balance' => 0]
]);
