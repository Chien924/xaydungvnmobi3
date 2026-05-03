<?php
// app-dang-ky-test.php - Trang test API tạo tài khoản.
// Lưu tại: C:\Data\AppCore\public\app-dang-ky-test.php
?>
<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<title>Test đăng ký app</title>
<style>*{box-sizing:border-box}body{margin:0;background:#f4f7fb;font-family:Arial;color:#0f172a}.wrap{max-width:460px;margin:0 auto;padding:16px}.box{background:#fff;border:1px solid #e5e7eb;border-radius:22px;padding:16px;box-shadow:0 8px 24px rgba(15,23,42,.06)}h1{font-size:23px;margin:0 0 5px}.sub{color:#64748b;font-weight:700;font-size:13px;line-height:1.4;margin-bottom:16px}label{display:block;font-weight:900;margin:11px 0 6px}input{width:100%;height:46px;border:1px solid #dbe3ef;border-radius:13px;padding:0 12px;font-weight:700;font-size:15px;background:#f8fafc}button{width:100%;height:48px;border:0;border-radius:14px;background:#16a34a;color:#fff;font-weight:900;font-size:16px;margin-top:15px}.result{margin-top:14px;padding:12px;border-radius:14px;font-weight:800;white-space:pre-wrap}.ok{background:#dcfce7;color:#166534}.err{background:#fee2e2;color:#991b1b}</style>
</head>
<body><div class="wrap"><div class="box"><h1>Test tạo tài khoản</h1><div class="sub">Trang này gọi <b>app-dang-ky-api.php</b>. Test chạy thật trên web, không dùng localhost.</div>
<form id="f"><label>Tên tài khoản</label><input name="username" required minlength="3"><label>Số điện thoại</label><input name="phone"><label>Mật khẩu</label><input name="password" type="password" required minlength="6"><button>Tạo tài khoản</button></form><div id="result"></div></div></div>
<script>const f=document.getElementById('f'),r=document.getElementById('result');f.onsubmit=async e=>{e.preventDefault();r.className='result';r.textContent='Đang gửi...';let data=Object.fromEntries(new FormData(f).entries());try{let res=await fetch('/app-dang-ky-api.php',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});let txt=await res.text();let j;try{j=JSON.parse(txt)}catch(_){throw new Error(txt)}r.className='result '+(j.success?'ok':'err');r.textContent=(j.message||'')+'\n\n'+JSON.stringify(j,null,2);}catch(err){r.className='result err';r.textContent='Lỗi: '+err.message;}};</script>
</body></html>
