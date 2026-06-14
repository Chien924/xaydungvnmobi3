<?php
// bot-api-app.php
// API bot dành cho app/web test. KHÔNG chặn đăng nhập.
// Đặt tại: C:\Data\AppCore\public\bot-api-app.php

@session_start();

require_once __DIR__ . '/api/v1/_config.php';

header('Content-Type: application/json; charset=utf-8');

function bot_app_json($arr, $code = 200) {
    http_response_code($code);
    echo json_encode($arr, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function bot_app_db() {
    foreach (['conn', 'connect', 'mysqli', 'db', 'link'] as $name) {
        if (isset($GLOBALS[$name]) && $GLOBALS[$name] instanceof mysqli) {
            $GLOBALS[$name]->set_charset('utf8mb4');
            return $GLOBALS[$name];
        }
    }
    return null;
}

function bot_app_text($s) {
    return trim((string)$s);
}

function bot_app_input($keys, $default = '') {
    foreach ($keys as $k) {
        if (isset($_POST[$k]) && bot_app_text($_POST[$k]) !== '') return bot_app_text($_POST[$k]);
        if (isset($_GET[$k]) && bot_app_text($_GET[$k]) !== '') return bot_app_text($_GET[$k]);
    }

    $raw = file_get_contents('php://input');
    if ($raw) {
        $json = json_decode($raw, true);
        if (is_array($json)) {
            foreach ($keys as $k) {
                if (isset($json[$k]) && bot_app_text($json[$k]) !== '') return bot_app_text($json[$k]);
            }
        }
    }

    return $default;
}

function bot_app_table_exists(mysqli $db, $table) {
    $t = $db->real_escape_string($table);
    $rs = @$db->query("SHOW TABLES LIKE '{$t}'");
    return $rs && $rs->num_rows > 0;
}

function bot_app_norm($s) {
    $s = mb_strtolower(trim((string)$s), 'UTF-8');
    $map = [
        'à'=>'a','á'=>'a','ạ'=>'a','ả'=>'a','ã'=>'a','â'=>'a','ầ'=>'a','ấ'=>'a','ậ'=>'a','ẩ'=>'a','ẫ'=>'a','ă'=>'a','ằ'=>'a','ắ'=>'a','ặ'=>'a','ẳ'=>'a','ẵ'=>'a',
        'è'=>'e','é'=>'e','ẹ'=>'e','ẻ'=>'e','ẽ'=>'e','ê'=>'e','ề'=>'e','ế'=>'e','ệ'=>'e','ể'=>'e','ễ'=>'e',
        'ì'=>'i','í'=>'i','ị'=>'i','ỉ'=>'i','ĩ'=>'i',
        'ò'=>'o','ó'=>'o','ọ'=>'o','ỏ'=>'o','õ'=>'o','ô'=>'o','ồ'=>'o','ố'=>'o','ộ'=>'o','ổ'=>'o','ỗ'=>'o','ơ'=>'o','ờ'=>'o','ớ'=>'o','ợ'=>'o','ở'=>'o','ỡ'=>'o',
        'ù'=>'u','ú'=>'u','ụ'=>'u','ủ'=>'u','ũ'=>'u','ư'=>'u','ừ'=>'u','ứ'=>'u','ự'=>'u','ử'=>'u','ữ'=>'u',
        'ỳ'=>'y','ý'=>'y','ỵ'=>'y','ỷ'=>'y','ỹ'=>'y','đ'=>'d',
    ];
    $s = strtr($s, $map);
    $s = preg_replace('/[^a-z0-9\s]/u', ' ', $s);
    $s = preg_replace('/\s+/', ' ', $s);
    return trim($s);
}

function bot_app_clean_html_to_text($html) {
    $html = (string)$html;
    $text = str_ireplace(['<br>', '<br/>', '<br />', '</p>'], "\n", $html);
    $text = strip_tags($text);
    $text = html_entity_decode($text, ENT_QUOTES, 'UTF-8');
    $text = preg_replace("/[ \t]+/", " ", $text);
    $text = preg_replace("/\n\s+/", "\n", $text);
    return trim($text);
}

function bot_app_format_suggestion($row) {
    $title = $row['tieu_de'] ?? ($row['nut_hien_thi'] ?? ($row['title'] ?? 'Xem'));
    return [
        'id' => isset($row['id']) ? (int)$row['id'] : null,
        'kich_ban_id' => isset($row['kich_ban_id']) ? (int)$row['kich_ban_id'] : (isset($row['id']) ? (int)$row['id'] : null),
        'title' => $title,
        'tieu_de' => $title,
        'text' => $title,
        'mo_ta_ngan' => $row['mo_ta_ngan'] ?? '',
        'icon' => $row['icon'] ?? '',
    ];
}

function bot_app_fallback_suggestions() {
    return [
        ['title' => 'Tài khoản', 'text' => 'Tài khoản'],
        ['title' => 'Nạp tiền', 'text' => 'Nạp tiền'],
        ['title' => 'Hồ sơ công ty', 'text' => 'Hồ sơ công ty'],
        ['title' => 'Gói thầu', 'text' => 'Gói thầu'],
        ['title' => 'Báo giá', 'text' => 'Báo giá'],
        ['title' => 'Nhu cầu vật tư', 'text' => 'Nhu cầu vật tư'],
        ['title' => 'Cửa hàng vật tư', 'text' => 'Cửa hàng vật tư'],
        ['title' => 'Cơ giới', 'text' => 'Cơ giới'],
        ['title' => 'Tổ đội', 'text' => 'Tổ đội'],
        ['title' => 'Liên hệ', 'text' => 'Liên hệ'],
    ];
}

function bot_app_welcome_suggestions(mysqli $db, $limit = 12) {
    if (!bot_app_table_exists($db, 'bot_goi_y')) return bot_app_fallback_suggestions();

    $sql = "SELECT id, kich_ban_id, tieu_de, mo_ta_ngan, icon
            FROM bot_goi_y
            WHERE active = 1 AND vi_tri_hien_thi = 'welcome'
            ORDER BY thu_tu ASC, id ASC
            LIMIT ?";
    $stmt = $db->prepare($sql);
    if (!$stmt) return bot_app_fallback_suggestions();

    $stmt->bind_param('i', $limit);
    $stmt->execute();
    $rs = $stmt->get_result();

    $rows = [];
    while ($r = $rs->fetch_assoc()) $rows[] = bot_app_format_suggestion($r);
    $stmt->close();

    return $rows ?: bot_app_fallback_suggestions();
}

function bot_app_root_suggestions(mysqli $db, $parentId, $limit = 10, $excludeId = 0) {
    if (!bot_app_table_exists($db, 'bot_goi_y')) return [];

    $sql = "SELECT id, kich_ban_id, tieu_de, mo_ta_ngan, icon
            FROM bot_goi_y
            WHERE active = 1
              AND vi_tri_hien_thi = 'root'
              AND parent_kich_ban_id = ?"
            . ($excludeId > 0 ? " AND kich_ban_id <> ?" : "") . "
            ORDER BY thu_tu ASC, id ASC
            LIMIT ?";

    $stmt = $db->prepare($sql);
    if (!$stmt) return [];

    if ($excludeId > 0) $stmt->bind_param('iii', $parentId, $excludeId, $limit);
    else $stmt->bind_param('ii', $parentId, $limit);

    $stmt->execute();
    $rs = $stmt->get_result();

    $rows = [];
    while ($r = $rs->fetch_assoc()) $rows[] = bot_app_format_suggestion($r);
    $stmt->close();

    if ($rows) return $rows;

    // fallback từ bot_kich_ban con
    if (!bot_app_table_exists($db, 'bot_kich_ban')) return [];

    $sql = "SELECT id, id AS kich_ban_id, tieu_de, mo_ta_ngan, '' AS icon
            FROM bot_kich_ban
            WHERE active = 1 AND parent_id = ?"
            . ($excludeId > 0 ? " AND id <> ?" : "") . "
            ORDER BY thu_tu ASC, id ASC
            LIMIT ?";

    $stmt = $db->prepare($sql);
    if (!$stmt) return [];

    if ($excludeId > 0) $stmt->bind_param('iii', $parentId, $excludeId, $limit);
    else $stmt->bind_param('ii', $parentId, $limit);

    $stmt->execute();
    $rs = $stmt->get_result();

    while ($r = $rs->fetch_assoc()) $rows[] = bot_app_format_suggestion($r);
    $stmt->close();

    return $rows;
}

function bot_app_get_kich_ban(mysqli $db, $id) {
    if (!bot_app_table_exists($db, 'bot_kich_ban')) return null;

    $stmt = $db->prepare("SELECT * FROM bot_kich_ban WHERE id = ? AND active = 1 LIMIT 1");
    if (!$stmt) return null;

    $id = (int)$id;
    $stmt->bind_param('i', $id);
    $stmt->execute();
    $rs = $stmt->get_result();
    $row = $rs ? $rs->fetch_assoc() : null;
    $stmt->close();

    return $row ?: null;
}

function bot_app_get_answer(mysqli $db, $kichBanId) {
    if (!bot_app_table_exists($db, 'bot_cau_tra_loi')) return null;

    $stmt = $db->prepare("SELECT * FROM bot_cau_tra_loi WHERE kich_ban_id = ? AND active = 1 ORDER BY thu_tu ASC, id ASC LIMIT 1");
    if (!$stmt) return null;

    $kichBanId = (int)$kichBanId;
    $stmt->bind_param('i', $kichBanId);
    $stmt->execute();
    $rs = $stmt->get_result();
    $row = $rs ? $rs->fetch_assoc() : null;
    $stmt->close();

    return $row ?: null;
}

function bot_app_reply_by_kich_ban(mysqli $db, $id, $source = 'choose') {
    $kb = bot_app_get_kich_ban($db, $id);

    if (!$kb) {
        bot_app_json([
            'ok' => true,
            'success' => true,
            'action' => $source,
            'message' => 'Mình chưa tìm thấy nội dung phù hợp.',
            'message_html' => 'Mình chưa tìm thấy nội dung phù hợp.',
            'suggestions' => bot_app_welcome_suggestions($db),
        ]);
    }

    // QUAN TRỌNG: bỏ hoàn toàn chặn đăng nhập, bỏ can_dang_nhap.
    if ((string)($kb['loai_kich_ban'] ?? '') === 'root') {
        $suggestions = bot_app_root_suggestions($db, (int)$kb['id']);
        $title = (string)($kb['tieu_de'] ?? 'Hỗ trợ');
        $html = '<b>' . htmlspecialchars($title, ENT_QUOTES, 'UTF-8') . '</b><br>Bạn cần xem nội dung nào bên dưới?';

        bot_app_json([
            'ok' => true,
            'success' => true,
            'action' => $source,
            'response_type' => 'suggest_list',
            'message' => bot_app_clean_html_to_text($html),
            'message_html' => $html,
            'suggestions' => $suggestions,
        ]);
    }

    $answer = bot_app_get_answer($db, (int)$kb['id']);
    if ($answer) {
        $html = (string)($answer['noi_dung'] ?? '');
        $text = bot_app_clean_html_to_text($html);
    } else {
        $title = (string)($kb['tieu_de'] ?? 'Hướng dẫn');
        $link = trim((string)($kb['link_url'] ?? ''));
        $html = '<b>' . htmlspecialchars($title, ENT_QUOTES, 'UTF-8') . '</b>';
        if ($link !== '') {
            $html .= '<br><a href="' . htmlspecialchars($link, ENT_QUOTES, 'UTF-8') . '">' . htmlspecialchars($link, ENT_QUOTES, 'UTF-8') . '</a>';
        }
        $text = bot_app_clean_html_to_text($html);
    }

    $parentId = (int)($kb['parent_id'] ?? 0);
    $suggestions = $parentId > 0 ? bot_app_root_suggestions($db, $parentId, 10, (int)$kb['id']) : bot_app_welcome_suggestions($db, 8);

    bot_app_json([
        'ok' => true,
        'success' => true,
        'action' => $source,
        'response_type' => 'reply',
        'message' => $text,
        'message_html' => $html,
        'suggestions' => $suggestions,
    ]);
}

function bot_app_find_best(mysqli $db, $question) {
    if (!bot_app_table_exists($db, 'bot_kich_ban')) return null;

    $q = bot_app_norm($question);
    $words = array_values(array_filter(explode(' ', $q), fn($w) => mb_strlen($w, 'UTF-8') >= 2));

    // 1) tìm qua bot_tu_khoa nếu có
    if ($words && bot_app_table_exists($db, 'bot_tu_khoa')) {
        $where = [];
        $params = [];
        $types = '';

        foreach ($words as $w) {
            $where[] = "LOWER(tk.tu_khoa) LIKE ?";
            $params[] = '%' . $w . '%';
            $types .= 's';
        }

        $sql = "SELECT k.*, tk.do_uu_tien
                FROM bot_tu_khoa tk
                JOIN bot_kich_ban k ON k.id = tk.kich_ban_id
                WHERE tk.active = 1 AND k.active = 1 AND (" . implode(' OR ', $where) . ")
                ORDER BY tk.do_uu_tien DESC, k.muc_do_uu_tien DESC, k.thu_tu ASC, k.id ASC
                LIMIT 1";

        $stmt = $db->prepare($sql);
        if ($stmt) {
            $stmt->bind_param($types, ...$params);
            $stmt->execute();
            $rs = $stmt->get_result();
            $row = $rs ? $rs->fetch_assoc() : null;
            $stmt->close();
            if ($row) return $row;
        }
    }

    // 2) tìm tiêu đề/mô tả/câu hỏi mẫu
    $like = '%' . $question . '%';
    $stmt = $db->prepare("SELECT * FROM bot_kich_ban WHERE active = 1 AND (tieu_de LIKE ? OR mo_ta_ngan LIKE ? OR cau_hoi_mau LIKE ?) ORDER BY muc_do_uu_tien DESC, thu_tu ASC, id ASC LIMIT 1");
    if ($stmt) {
        $stmt->bind_param('sss', $like, $like, $like);
        $stmt->execute();
        $rs = $stmt->get_result();
        $row = $rs ? $rs->fetch_assoc() : null;
        $stmt->close();
        if ($row) return $row;
    }

    return null;
}

$db = bot_app_db();
if (!$db) {
    bot_app_json([
        'ok' => false,
        'success' => false,
        'message' => 'Bot chưa kết nối được database từ api/v1/_config.php.',
    ], 500);
}

$action = bot_app_input(['action'], 'init');

if ($action === 'ping') {
    bot_app_json(['ok' => true, 'success' => true, 'message' => 'pong']);
}

if ($action === 'init') {
    $welcome = 'Xin chào, tôi có thể hỗ trợ bạn theo các câu hỏi có sẵn. Bạn hãy chọn một mục bên dưới hoặc nhập ngắn gọn nội dung cần hỏi.';
    bot_app_json([
        'ok' => true,
        'success' => true,
        'action' => 'init',
        'message' => $welcome,
        'message_html' => nl2br(htmlspecialchars($welcome, ENT_QUOTES, 'UTF-8')),
        'suggestions' => bot_app_welcome_suggestions($db),
    ]);
}

if ($action === 'choose') {
    $id = (int)bot_app_input(['kich_ban_id', 'id'], '0');
    if ($id <= 0) {
        bot_app_json([
            'ok' => false,
            'success' => false,
            'message' => 'Thiếu kich_ban_id.',
        ], 422);
    }
    bot_app_reply_by_kich_ban($db, $id, 'choose');
}

if ($action === 'ask') {
    $question = bot_app_input(['message', 'q', 'text'], '');
    if ($question === '') {
        bot_app_json([
            'ok' => false,
            'success' => false,
            'message' => 'Bạn vui lòng nhập nội dung cần hỏi.',
        ], 422);
    }

    $best = bot_app_find_best($db, $question);
    if ($best) {
        bot_app_reply_by_kich_ban($db, (int)$best['id'], 'ask');
    }

    bot_app_json([
        'ok' => true,
        'success' => true,
        'action' => 'ask',
        'message' => 'Mình chưa hiểu đúng nội dung này. Bạn chọn một gợi ý bên dưới hoặc nhập ngắn gọn hơn.',
        'message_html' => 'Mình chưa hiểu đúng nội dung này. Bạn chọn một gợi ý bên dưới hoặc nhập ngắn gọn hơn.',
        'suggestions' => bot_app_welcome_suggestions($db, 8),
    ]);
}

bot_app_json([
    'ok' => false,
    'success' => false,
    'message' => 'Action không hợp lệ.',
], 400);
