<?php
// app-ho-tro-test.php
// Trang test hỗ trợ dùng API bot có sẵn trong: /bot chat/bot-api.php
// Lưu vào: C:\Data\AppCore\public\app-ho-tro-test.php

$isApp = isset($_GET['app']) && $_GET['app'] == '1';
?>
<!doctype html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <title>Hỗ trợ Xây Dựng VN</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: Arial, Helvetica, sans-serif;
            background: #f4f7fb;
            color: #111827;
        }
        .wrap {
            max-width: 560px;
            margin: 0 auto;
            min-height: 100vh;
            padding: 12px;
        }
        .hero {
            background: linear-gradient(135deg, #0f766e, #16a34a);
            color: #fff;
            border-radius: 22px;
            padding: 16px;
            box-shadow: 0 8px 22px rgba(15, 118, 110, .22);
        }
        .hero h1 { margin: 0 0 6px; font-size: 22px; }
        .hero p { margin: 0; font-size: 13px; opacity: .94; line-height: 1.45; }
        .box {
            margin-top: 12px;
            background: #fff;
            border: 1px solid #e5e7eb;
            border-radius: 18px;
            padding: 12px;
            box-shadow: 0 4px 14px rgba(15, 23, 42, .06);
        }
        .quick {
            display: flex;
            gap: 8px;
            overflow-x: auto;
            padding-bottom: 5px;
        }
        .quick button, .suggestion button {
            border: 1px solid #bbf7d0;
            background: #ecfdf5;
            color: #166534;
            border-radius: 999px;
            padding: 8px 11px;
            font-weight: 800;
            white-space: nowrap;
        }
        #messages {
            height: 390px;
            overflow-y: auto;
            background: #f8fafc;
            border: 1px solid #e5e7eb;
            border-radius: 16px;
            padding: 10px;
            margin-top: 10px;
        }
        .msg {
            margin: 8px 0;
            max-width: 90%;
            padding: 10px 12px;
            border-radius: 15px;
            font-size: 14px;
            line-height: 1.45;
            white-space: pre-wrap;
            word-break: break-word;
        }
        .me {
            margin-left: auto;
            background: #16a34a;
            color: #fff;
            border-bottom-right-radius: 5px;
        }
        .bot {
            background: #fff;
            color: #111827;
            border: 1px solid #e5e7eb;
            border-bottom-left-radius: 5px;
        }
        .bot a {
            color: #047857;
            font-weight: 800;
            text-decoration: none;
        }
        .suggestion {
            display: flex;
            gap: 7px;
            flex-wrap: wrap;
            margin-top: 7px;
        }
        .send-row {
            display: flex;
            gap: 8px;
            margin-top: 10px;
        }
        .send-row input {
            flex: 1;
            border: 1px solid #d1d5db;
            border-radius: 14px;
            padding: 12px;
            font-size: 14px;
            outline: none;
        }
        .send-row button {
            border: 0;
            border-radius: 14px;
            background: #16a34a;
            color: #fff;
            padding: 0 15px;
            font-weight: 900;
        }
        .status {
            margin-top: 8px;
            color: #64748b;
            font-size: 12px;
        }
    </style>
</head>
<body>
<div class="wrap">
    <div class="hero">
        <h1>Hỗ trợ Xây Dựng VN</h1>
        <p>Bot hỗ trợ lấy dữ liệu từ API cũ trong thư mục <b>bot chat</b>.</p>
    </div>

    <div class="box">
        <div class="quick" id="quick">
            <button onclick="sendText('Tài khoản')">Tài khoản</button>
            <button onclick="sendText('Nạp tiền')">Nạp tiền</button>
            <button onclick="sendText('Tìm xe')">Tìm xe</button>
            <button onclick="sendText('Vật tư')">Vật tư</button>
            <button onclick="sendText('Đấu thầu')">Đấu thầu</button>
            <button onclick="sendText('Báo giá')">Báo giá</button>
        </div>

        <div id="messages"></div>

        <div class="send-row">
            <input id="q" placeholder="Nhập nội dung cần hỏi..." onkeydown="if(event.key==='Enter') sendQuestion()">
            <button onclick="sendQuestion()">Gửi</button>
        </div>

        <div class="status" id="status">Đang kết nối bot...</div>
    </div>
</div>

<script>
const BOT_API = '/bot%20chat/bot-api.php';

function addMsg(content, cls, isHtml = false) {
    const box = document.getElementById('messages');
    const div = document.createElement('div');
    div.className = 'msg ' + cls;
    if (isHtml) div.innerHTML = content;
    else div.textContent = content;
    box.appendChild(div);
    box.scrollTop = box.scrollHeight;
    return div;
}

function renderSuggestions(suggestions) {
    if (!Array.isArray(suggestions) || suggestions.length === 0) return '';
    let html = '<div class="suggestion">';
    suggestions.forEach(s => {
        const title = s.title || s.tieu_de || s.nut_hien_thi || s.text || s.label || 'Xem';
        const id = s.kich_ban_id || s.id || '';
        const text = s.text || title;
        if (id) {
            html += `<button onclick="chooseSuggestion('${String(id).replace(/'/g, "\\'")}')">${escapeHtml(title)}</button>`;
        } else {
            html += `<button onclick="sendText('${String(text).replace(/'/g, "\\'")}')">${escapeHtml(title)}</button>`;
        }
    });
    html += '</div>';
    return html;
}

function escapeHtml(str) {
    return String(str).replace(/[&<>"']/g, m => ({
        '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#039;'
    }[m]));
}

async function botPost(data) {
    const fd = new FormData();
    Object.keys(data).forEach(k => fd.append(k, data[k]));
    const res = await fetch(BOT_API, {
        method: 'POST',
        body: fd,
        credentials: 'include'
    });
    const raw = await res.text();
    let json;
    try { json = JSON.parse(raw); }
    catch (e) {
        throw new Error('API không trả JSON: ' + raw.slice(0, 180));
    }
    if (!res.ok || json.ok === false) {
        throw new Error(json.message || ('HTTP ' + res.status));
    }
    return json;
}

async function initBot() {
    try {
        const json = await botPost({ action: 'init' });
        document.getElementById('status').textContent = 'Bot đã sẵn sàng';
        const msg = json.message_html || escapeHtml(json.message || 'Xin chào, bạn cần hỗ trợ gì?');
        addMsg(msg + renderSuggestions(json.suggestions), 'bot', true);
    } catch (e) {
        document.getElementById('status').textContent = 'Lỗi bot: ' + e.message;
        addMsg('Chưa kết nối được bot API: ' + e.message, 'bot');
    }
}

function sendText(text) {
    document.getElementById('q').value = text;
    sendQuestion();
}

async function sendQuestion() {
    const input = document.getElementById('q');
    const text = (input.value || '').trim();
    if (!text) return;
    input.value = '';
    addMsg(text, 'me');
    const loading = addMsg('Đang trả lời...', 'bot');

    try {
        const json = await botPost({ action: 'ask', message: text });
        const msg = json.message_html || escapeHtml(json.message || 'Bot chưa có phản hồi.');
        loading.innerHTML = msg + renderSuggestions(json.suggestions);
    } catch (e) {
        loading.textContent = 'Lỗi: ' + e.message;
    }
}

async function chooseSuggestion(id) {
    const loading = addMsg('Đang mở nội dung...', 'bot');
    try {
        const json = await botPost({ action: 'choose', kich_ban_id: id });
        const msg = json.message_html || escapeHtml(json.message || 'Bot chưa có phản hồi.');
        loading.innerHTML = msg + renderSuggestions(json.suggestions);
    } catch (e) {
        loading.textContent = 'Lỗi: ' + e.message;
    }
}

initBot();
</script>
</body>
</html>
