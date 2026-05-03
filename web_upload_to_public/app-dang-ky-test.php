<?php
// app-dang-ky-test.php
// Trang web test đăng ký trước khi đưa vào app.
// Đặt tại: C:\Data\AppCore\public\app-dang-ky-test.php
?>
<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<title>Test đăng ký app</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
*{box-sizing:border-box}
body{margin:0;background:#eef5ef;font-family:Arial,Helvetica,sans-serif;color:#111827}
.wrap{max-width:460px;margin:0 auto;min-height:100vh;padding:14px}
.hero{background:linear-gradient(135deg,#23713b,#7fba5d);color:#fff;border-radius:24px;padding:18px;margin-bottom:14px;box-shadow:0 8px 24px rgba(35,113,59,.2)}
.hero h1{margin:0;font-size:24px}
.card{background:#fff;border-radius:24px;padding:18px;box-shadow:0 6px 22px rgba(15,23,42,.08);border:1px solid #e5e7eb}
label{display:block;margin:13px 0 6px;font-size:13px;font-weight:800;color:#475569}
input{width:100%;border:1px solid #d1d5db;border-radius:16px;padding:13px;font-size:16px;outline:none;background:#f8fafc}
input:focus{border-color:#2f7d43;box-shadow:0 0 0 3px rgba(47,125,67,.14);background:#fff}
button{width:100%;border:0;background:#2f7d43;color:#fff;border-radius:16px;margin-top:16px;padding:14px;font-size:16px;font-weight:900}
button:disabled{opacity:.7}
.msg{margin-top:13px;border-radius:16px;padding:13px;font-size:14px;font-weight:800;line-height:1.45}
.ok{background:#ecfdf5;color:#166534;border:1px solid #bbf7d0}
.err{background:#fef2f2;color:#b91c1c;border:1px solid #fecaca}
pre{white-space:pre-wrap;word-break:break-word;font-size:12px;font-weight:500}
</style>
</head>
<body>
<div class="wrap">
    <div class="hero"><h1>Tạo tài khoản mới</h1></div>
    <div class="card">
        <label>Tên tài khoản</label>
        <input id="username" autocomplete="username">

        <label>Số điện thoại</label>
        <input id="sdt" inputmode="tel" autocomplete="tel">

        <label>Mật khẩu</label>
        <input id="password" type="password" autocomplete="new-password">

        <label>Nhập lại mật khẩu</label>
        <input id="password2" type="password" autocomplete="new-password">

        <button id="btn" onclick="register()">Tạo tài khoản</button>
        <div id="msg" class="msg err" style="display:none"></div>
    </div>
</div>
<script>
async function register(){
    const btn = document.getElementById('btn');
    const box = document.getElementById('msg');

    const data = {
        username: document.getElementById('username').value.trim(),
        sdt: document.getElementById('sdt').value.trim(),
        password: document.getElementById('password').value,
        password2: document.getElementById('password2').value
    };

    btn.disabled = true;
    box.style.display = 'block';
    box.className = 'msg';
    box.textContent = 'Đang tạo tài khoản...';

    try{
        const res = await fetch('/app-dang-ky-api.php', {
            method:'POST',
            headers:{'Content-Type':'application/json'},
            credentials:'include',
            body:JSON.stringify(data)
        });

        const raw = await res.text();

        let json;
        try {
            json = JSON.parse(raw);
        } catch(e) {
            box.className = 'msg err';
            box.innerHTML = 'API đang trả về HTML hoặc text, không phải JSON.<br><br><pre>' + raw.replace(/[<>&]/g, s => ({'<':'&lt;','>':'&gt;','&':'&amp;'}[s])) + '</pre>';
            return;
        }

        box.className = 'msg ' + (json.success ? 'ok' : 'err');
        box.textContent = json.message || (json.success ? 'Tạo tài khoản thành công.' : 'Tạo tài khoản thất bại.');
    }catch(e){
        box.className = 'msg err';
        box.textContent = 'Không gọi được API: ' + e.message;
    }finally{
        btn.disabled = false;
    }
}
</script>
</body>
</html>
