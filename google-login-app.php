<?php
/**
 * google-login-app.php
 * Đăng nhập Google CHO APP (native google_sign_in).
 *
 * App gửi POST { id_token: "<JWT của Google>" }.
 * Server xác minh token, tìm/tạo user trong bảng users (giống google-callback.php),
 * rồi trả về JSON kèm app_token để app lưu và đăng nhập.
 *
 * Đặt file này ngang hàng với google-callback.php (trong /public).
 */

declare(strict_types=1);

// Dùng lại hàm tạo token + đọc user của hệ thống app.
require_once __DIR__ . '/api/v1/app/_common.php';
// _common.php đã đặt Content-Type: application/json và mở session, kết nối DB.

require_once __DIR__ . '/connect.php';

// Client ID giống hệt google-callback.php của bạn.
const GOOGLE_CLIENT_ID_APP = '692778120034-no4ilrgeb0soa892odju3jq9a3n8ctq1.apps.googleusercontent.com';
const GOOGLE_DISCOVERY_URL_APP = 'https://accounts.google.com/.well-known/openid-configuration';

function gla_b64url_decode(string $input): string|false
{
    $remainder = strlen($input) % 4;
    if ($remainder > 0) $input .= str_repeat('=', 4 - $remainder);
    return base64_decode(strtr($input, '-_', '+/'), true);
}

function gla_fetch(string $url): string|false
{
    if (function_exists('curl_init')) {
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_TIMEOUT => 15,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_USERAGENT => 'CoGioiVN-GoogleAppLogin/1.0',
        ]);
        $response = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($response !== false && $code >= 200 && $code < 300) return $response;
    }
    $ctx = stream_context_create(['http' => ['timeout' => 15, 'ignore_errors' => true]]);
    $r = @file_get_contents($url, false, $ctx);
    return $r !== false ? $r : false;
}

function gla_fetch_json(string $url): ?array
{
    $raw = gla_fetch($url);
    if ($raw === false || $raw === '') return null;
    $j = json_decode($raw, true);
    return is_array($j) ? $j : null;
}

function gla_asn1_len(int $len): string
{
    if ($len < 128) return chr($len);
    $tmp = '';
    while ($len > 0) { $tmp = chr($len & 0xff) . $tmp; $len >>= 8; }
    return chr(0x80 | strlen($tmp)) . $tmp;
}
function gla_asn1_int(string $v): string
{
    if ($v === '') $v = "\x00";
    if (ord($v[0]) > 0x7f) $v = "\x00" . $v;
    return "\x02" . gla_asn1_len(strlen($v)) . $v;
}
function gla_asn1_seq(string $v): string { return "\x30" . gla_asn1_len(strlen($v)) . $v; }
function gla_asn1_bit(string $v): string { return "\x03" . gla_asn1_len(strlen($v) + 1) . "\x00" . $v; }

function gla_jwk_to_pem(array $jwk): ?string
{
    if (($jwk['kty'] ?? '') !== 'RSA' || empty($jwk['n']) || empty($jwk['e'])) return null;
    $n = gla_b64url_decode((string) $jwk['n']);
    $e = gla_b64url_decode((string) $jwk['e']);
    if ($n === false || $e === false) return null;
    $rsa = gla_asn1_seq(gla_asn1_int($n) . gla_asn1_int($e));
    $oid = hex2bin('300d06092a864886f70d0101010500');
    $spki = gla_asn1_seq($oid . gla_asn1_bit($rsa));
    return "-----BEGIN PUBLIC KEY-----\n" . chunk_split(base64_encode($spki), 64, "\n") . "-----END PUBLIC KEY-----\n";
}

function gla_google_pem(string $kid): ?string
{
    static $cache = [];
    if (isset($cache[$kid])) return $cache[$kid];
    $disc = gla_fetch_json(GOOGLE_DISCOVERY_URL_APP);
    if (!$disc || empty($disc['jwks_uri'])) return null;
    $jwks = gla_fetch_json((string) $disc['jwks_uri']);
    if (!$jwks || empty($jwks['keys'])) return null;
    foreach ($jwks['keys'] as $jwk) {
        if (($jwk['kid'] ?? '') === $kid) {
            $pem = gla_jwk_to_pem($jwk);
            if ($pem !== null) $cache[$kid] = $pem;
            return $pem;
        }
    }
    return null;
}

function gla_verify_id_token(string $jwt): ?array
{
    $parts = explode('.', $jwt);
    if (count($parts) !== 3) return null;
    [$h64, $p64, $s64] = $parts;
    $hRaw = gla_b64url_decode($h64);
    $pRaw = gla_b64url_decode($p64);
    $sig = gla_b64url_decode($s64);
    if ($hRaw === false || $pRaw === false || $sig === false) return null;
    $header = json_decode($hRaw, true);
    $payload = json_decode($pRaw, true);
    if (!is_array($header) || !is_array($payload)) return null;
    if (($header['alg'] ?? '') !== 'RS256' || empty($header['kid'])) return null;
    $pem = gla_google_pem((string) $header['kid']);
    if (!$pem) return null;
    if (openssl_verify($h64 . '.' . $p64, $sig, $pem, OPENSSL_ALGO_SHA256) !== 1) return null;

    $iss = (string) ($payload['iss'] ?? '');
    if (!in_array($iss, ['accounts.google.com', 'https://accounts.google.com'], true)) return null;
    $aud = $payload['aud'] ?? '';
    if (is_array($aud)) {
        if (!in_array(GOOGLE_CLIENT_ID_APP, $aud, true)) return null;
    } elseif ((string) $aud !== GOOGLE_CLIENT_ID_APP) {
        return null;
    }
    if ((int) ($payload['exp'] ?? 0) < time()) return null;
    return $payload;
}

function gla_has_col(mysqli $conn, string $table, string $col): bool
{
    static $cache = [];
    $k = "$table.$col";
    if (isset($cache[$k])) return $cache[$k];
    $t = $conn->real_escape_string($table);
    $c = $conn->real_escape_string($col);
    $rs = $conn->query("SHOW COLUMNS FROM `$t` LIKE '$c'");
    return $cache[$k] = ($rs && $rs->num_rows > 0);
}

function gla_dbval(mysqli $conn, mixed $v): string
{
    if ($v === null) return 'NULL';
    return "'" . $conn->real_escape_string((string) $v) . "'";
}

function gla_make_username(string $sub, string $email, string $name): string
{
    $stable = 'gg_' . substr(sha1($sub), 0, 20);
    if ($email !== '') {
        $prefix = strstr($email, '@', true);
        if ($prefix !== false && $prefix !== '') {
            $clean = trim((string) preg_replace('/[^a-zA-Z0-9_]/', '_', $prefix), '_');
            if ($clean !== '') $stable = substr($clean, 0, 14) . '_' . substr(sha1($sub), 0, 8);
        }
    } elseif ($name !== '') {
        $clean = trim((string) preg_replace('/[^a-zA-Z0-9_]/', '_', $name), '_');
        if ($clean !== '') $stable = substr($clean, 0, 14) . '_' . substr(sha1($sub), 0, 8);
    }
    if (strlen($stable) < 4) $stable = 'gg_' . substr(sha1($sub), 0, 8);
    return strtolower($stable);
}

// ===================== Xử lý chính =====================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    app_json(['success' => false, 'message' => 'Yêu cầu không hợp lệ.'], 405);
}

if (!isset($conn) || !($conn instanceof mysqli)) {
    if (isset($connect) && $connect instanceof mysqli) $conn = $connect;
}
if (!isset($conn) || !($conn instanceof mysqli)) {
    app_json(['success' => false, 'message' => 'Không kết nối được cơ sở dữ liệu.'], 500);
}

$input = app_input();
$idToken = trim((string) ($input['id_token'] ?? $input['credential'] ?? ''));
if ($idToken === '') {
    app_json(['success' => false, 'message' => 'Thiếu id_token Google.'], 400);
}

$payload = gla_verify_id_token($idToken);
if (!$payload) {
    app_json(['success' => false, 'message' => 'Không xác minh được tài khoản Google.'], 401);
}

$sub = trim((string) ($payload['sub'] ?? ''));
$email = strtolower(trim((string) ($payload['email'] ?? '')));
$name = trim((string) ($payload['name'] ?? ''));
$emailVerified = !empty($payload['email_verified']);

if ($sub === '') app_json(['success' => false, 'message' => 'Thiếu mã định danh Google.'], 400);
if ($email !== '' && !$emailVerified) app_json(['success' => false, 'message' => 'Email Google chưa xác minh.'], 400);

$username = gla_make_username($sub, $email, $name);

$hasGoogleSub = gla_has_col($conn, 'users', 'google_sub');
$hasEmail = gla_has_col($conn, 'users', 'email');
$hasHoTen = gla_has_col($conn, 'users', 'ho_ten');
$hasBan = gla_has_col($conn, 'users', 'ban');

$user = null;

if ($hasGoogleSub) {
    $rs = $conn->query("SELECT * FROM users WHERE google_sub = '" . $conn->real_escape_string($sub) . "' LIMIT 1");
    $user = $rs ? $rs->fetch_assoc() : null;
}
if (!$user && $hasEmail && $email !== '') {
    $rs = $conn->query("SELECT * FROM users WHERE email = '" . $conn->real_escape_string($email) . "' LIMIT 1");
    $user = $rs ? $rs->fetch_assoc() : null;
}
if (!$user) {
    $rs = $conn->query("SELECT * FROM users WHERE username = '" . $conn->real_escape_string($username) . "' LIMIT 1");
    $user = $rs ? $rs->fetch_assoc() : null;
}

if (!$user) {
    if (!gla_has_col($conn, 'users', 'username') || !gla_has_col($conn, 'users', 'password')) {
        app_json(['success' => false, 'message' => 'Bảng users chưa đủ cột.'], 500);
    }
    $ins = [];
    $ins['username'] = gla_dbval($conn, $username);
    $ins['password'] = gla_dbval($conn, password_hash(bin2hex(random_bytes(16)), PASSWORD_DEFAULT));
    if ($hasHoTen) $ins['ho_ten'] = gla_dbval($conn, $name !== '' ? $name : $username);
    if ($hasEmail) $ins['email'] = gla_dbval($conn, $email !== '' ? $email : null);
    if ($hasGoogleSub) $ins['google_sub'] = gla_dbval($conn, $sub);
    if (gla_has_col($conn, 'users', 'sdt')) $ins['sdt'] = 'NULL';
    if (gla_has_col($conn, 'users', 'role')) $ins['role'] = gla_dbval($conn, 'user');
    if (gla_has_col($conn, 'users', 'active')) $ins['active'] = '1';
    if ($hasBan) $ins['ban'] = '0';
    if (gla_has_col($conn, 'users', 'so_du')) $ins['so_du'] = '0';
    if (gla_has_col($conn, 'users', 'tong_nap')) $ins['tong_nap'] = '0';
    if (gla_has_col($conn, 'users', 'created_at')) $ins['created_at'] = 'NOW()';
    if (gla_has_col($conn, 'users', 'updated_at')) $ins['updated_at'] = 'NOW()';

    $cols = '`' . implode('`,`', array_keys($ins)) . '`';
    $vals = implode(',', array_values($ins));
    if (!$conn->query("INSERT INTO users ($cols) VALUES ($vals)")) {
        app_json(['success' => false, 'message' => 'Không tạo được tài khoản Google.'], 500);
    }
    $newId = (int) $conn->insert_id;
    $rs = $conn->query("SELECT * FROM users WHERE id = $newId LIMIT 1");
    $user = $rs ? $rs->fetch_assoc() : null;
}

if (!$user) app_json(['success' => false, 'message' => 'Không tìm thấy tài khoản.'], 500);

// Kiểm tra khóa/cấm.
$ban = ($hasBan && isset($user['ban'])) ? (int) $user['ban'] : 0;
if ($ban === 2) app_json(['success' => false, 'message' => 'Tài khoản đã bị khóa.'], 403);
if (isset($user['active']) && (int) $user['active'] !== 1) {
    app_json(['success' => false, 'message' => 'Tài khoản đã bị khóa.'], 403);
}

// Cập nhật thông tin Google nếu thiếu.
$updates = [];
if ($hasGoogleSub && empty($user['google_sub'])) $updates[] = "google_sub = '" . $conn->real_escape_string($sub) . "'";
if ($hasEmail && $email !== '' && empty($user['email'])) $updates[] = "email = '" . $conn->real_escape_string($email) . "'";
if ($hasHoTen && $name !== '' && empty($user['ho_ten'])) $updates[] = "ho_ten = '" . $conn->real_escape_string($name) . "'";
if (gla_has_col($conn, 'users', 'updated_at')) $updates[] = "updated_at = NOW()";
if ($updates) {
    $uid = (int) $user['id'];
    $conn->query("UPDATE users SET " . implode(', ', $updates) . " WHERE id = $uid LIMIT 1");
}

// Cũng set session để WebView dùng được ngay.
$_SESSION['user_id'] = (int) ($user['id'] ?? 0);
$_SESSION['username'] = (string) ($user['username'] ?? $username);
$_SESSION['role'] = (string) ($user['role'] ?? 'user');
$_SESSION['app_login'] = 1;

// Tạo app_token để app lưu (đăng nhập đầy đủ như login thường).
$cols = app_columns($conn, 'users');
$userPayload = app_user_payload($user, $cols);
$token = app_make_token((int) $user['id'], (string) ($user['username'] ?? $username));
$_SESSION['app_token'] = $token;

app_json([
    'success' => true,
    'message' => 'Đăng nhập Google thành công.',
    'token' => $token,
    'user' => $userPayload,
]);
