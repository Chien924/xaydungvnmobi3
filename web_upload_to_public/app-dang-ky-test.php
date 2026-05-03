<?php
// app-dang-ky-test.php
// Trang test đăng ký tài khoản app.
// Lưu tại: C:\Data\AppCore\public\app-dang-ky-test.php
?>
<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<title>Tạo tài khoản</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
*{box-sizing:border-box}
body{margin:0;background:#f4f7fb;font-family:Arial,Helvetica,sans-serif;color:#111827}
.wrap{max-width:460px;margin:0 auto;min-height:100vh;padding:14px}
.card{background:#fff;border:1px solid #e5e7eb;border-radius:22px;padding:16px;box-shadow:0 4px 16px rgba(15,23,42,.06)}
h1{margin:0 0 12px;font-size:25px}
label{display:block;margin:11px 0 6px;font-weight:800;font-size:13px;color:#334155}
input{width:100%;border:1px solid #d1d5db;border-radius:14px;padding:12px;font-size:15px;outline:none}
input:focus{border-color:#2f7d43;box-shadow:0 0 0 3px rgba(47,125,67,.12)}
button{width:100%;border:0;border-radius:15px;background:#2f7d43;color:#fff;padding:13px;margin-top:14px;font-weight:900;font-size:15px}
button:disabled{opacity:.65}
.result{margin-top:12px;background:#f8fafc;border:1px solid #e5e7eb;border-radius:14px;padding:12px;white-space:pre-wrap;font-size:13px;line-height:1.45}
.ok{color:#166534}.err{color:#b91c1c}
</style>
</head>
<body>
<div class="wrap">
  <div class="card">
    <h1>Tạo tài khoản</h1>

    <label>Tên tài khoản</label>
    <input id="username" placeholder="Ví dụ: admin123" autocomplete="username">

    <label>Số điện thoại</label>
    <input id="sdt" placeholder="Ví dụ: 0900000000" inputmode="tel" autocomplete="tel">

    <label>Mật khẩu</label>
    <input id="password" type="password" autocomplete="new-password">

    <label>Nhập lại mật khẩu</label>
    <input id="password2" type="password" autocomplete="new-password">

    <button id="btn" onclick="register()">Tạo tài khoản</button>

    <div id="result" class="result">Chưa gửi.</div>
  </div>
</div>

<script>
async function register(){
  const result = document.getElementById('result');
  const btn = document.getElementById('btn');

  const data = {
    username: document.getElementById('username').value.trim(),
    sdt: document.getElementById('sdt').value.trim(),
    password: document.getElementById('password').value,
    password2: document.getElementById('password2').value
  };

  result.className = 'result';
  result.textContent = 'Đang gửi...';
  btn.disabled = true;

  try {
    const res = await fetch('/app-dang-ky-api.php', {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify(data),
      credentials: 'include'
    });

    const raw = await res.text();
    let json;
    try { json = JSON.parse(raw); }
    catch(e) {
      result.className = 'result err';
      result.textContent = 'API không trả JSON:\n\n' + raw;
      return;
    }

    result.className = 'result ' + (json.success ? 'ok' : 'err');

    if (json.success) {
      result.textContent = json.message || 'Tạo tài khoản thành công.';
    } else {
      result.textContent = json.message || 'Tạo tài khoản thất bại.';
    }
  } catch(e) {
    result.className = 'result err';
    result.textContent = 'Lỗi: ' + e.message;
  } finally {
    btn.disabled = false;
  }
}
</script>
</body>
</html>
