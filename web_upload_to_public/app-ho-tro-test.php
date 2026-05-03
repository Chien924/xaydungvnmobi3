<?php
// app-ho-tro-test.php
// Trang hỗ trợ dạng chat rộng cho app. Lưu tại C:\Data\AppCore\public\app-ho-tro-test.php
?>
<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<title>Hỗ trợ</title>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<style>
*{box-sizing:border-box}html,body{height:100%;margin:0;font-family:Arial,Helvetica,sans-serif;background:#f4f7fb;color:#111827}.chat{height:100vh;max-width:640px;margin:0 auto;display:flex;flex-direction:column;background:#f4f7fb}.top{padding:10px 12px;background:#fff;border-bottom:1px solid #e5e7eb;display:flex;align-items:center;gap:10px}.avatar{width:38px;height:38px;border-radius:14px;background:#dcfce7;color:#15803d;display:flex;align-items:center;justify-content:center;font-weight:900}.title{font-size:18px;font-weight:900}.quick{display:flex;gap:8px;overflow-x:auto;padding:9px 12px;background:#fff;border-bottom:1px solid #e5e7eb}.quick button,.suggest button{border:1px solid #bbf7d0;background:#ecfdf5;color:#166534;border-radius:999px;padding:8px 12px;font-weight:800;white-space:nowrap}.messages{flex:1;overflow-y:auto;padding:12px}.msg{margin:8px 0;max-width:86%;padding:11px 13px;border-radius:17px;font-size:15px;line-height:1.45;white-space:pre-wrap;word-break:break-word}.me{margin-left:auto;background:#16a34a;color:white;border-bottom-right-radius:5px}.bot{background:white;border:1px solid #e5e7eb;border-bottom-left-radius:5px}.suggest{display:flex;gap:7px;flex-wrap:wrap;margin-top:8px}.input{display:flex;gap:8px;padding:10px;background:white;border-top:1px solid #e5e7eb}.input input{flex:1;border:1px solid #d1d5db;border-radius:16px;padding:13px;font-size:15px;outline:none}.input button{border:0;border-radius:16px;background:#16a34a;color:white;padding:0 18px;font-weight:900;font-size:15px}.status{font-size:12px;color:#64748b;padding:0 12px 8px;background:#fff}.bot a{color:#047857;font-weight:800;text-decoration:none}
</style>
</head>
<body>
<div class="chat">
  <div class="top"><div class="avatar">?</div><div class="title">Hỗ trợ</div></div>
  <div class="quick">
    <button onclick="sendText('Tài khoản')">Tài khoản</button><button onclick="sendText('Nạp tiền')">Nạp tiền</button><button onclick="sendText('Tìm xe')">Tìm xe</button><button onclick="sendText('Vật tư')">Vật tư</button><button onclick="sendText('Đấu thầu')">Đấu thầu</button><button onclick="sendText('Báo giá')">Báo giá</button>
  </div>
  <div id="messages" class="messages"></div>
  <div class="input"><input id="q" placeholder="Nhập nội dung cần hỏi..." onkeydown="if(event.key==='Enter') sendQuestion()"><button onclick="sendQuestion()">Gửi</button></div>
  <div id="status" class="status"></div>
</div>
<script>
const BOT_API='/bot%20chat/bot-api.php';
function esc(s){return String(s).replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]));}
function addMsg(c,cls,html=false){const b=document.getElementById('messages');const d=document.createElement('div');d.className='msg '+cls;if(html)d.innerHTML=c;else d.textContent=c;b.appendChild(d);b.scrollTop=b.scrollHeight;return d;}
function suggestions(json){let arr=json.suggestions||json.goiy||[];if(!Array.isArray(arr)||!arr.length)return '';let h='<div class="suggest">';arr.forEach(s=>{if(typeof s==='string'){h+=`<button onclick="sendText('${String(s).replace(/'/g,"\\'")}')">${esc(s)}</button>`;return;}let title=s.title||s.tieu_de||s.nut_hien_thi||s.text||s.label||s.ten_nhom||'Xem';let id=s.kich_ban_id||s.id||'';let text=s.text||s.cau_hoi_mau||title;if(id)h+=`<button onclick="chooseSuggestion('${String(id).replace(/'/g,"\\'")}')">${esc(title)}</button>`;else h+=`<button onclick="sendText('${String(text).replace(/'/g,"\\'")}')">${esc(title)}</button>`;});return h+'</div>';}
async function bot(data){const fd=new FormData();Object.keys(data).forEach(k=>fd.append(k,data[k]));const r=await fetch(BOT_API,{method:'POST',body:fd,credentials:'include',cache:'no-store'});const raw=await r.text();let j;try{j=JSON.parse(raw)}catch(e){throw new Error('API không trả JSON: '+raw.slice(0,250));}if(!r.ok||j.ok===false||j.success===false)throw new Error(j.message||j.error||('HTTP '+r.status));return j;}
function msg(j){return j.message_html||j.html||esc(j.message||j.reply||j.answer||'Bot chưa có phản hồi.');}
async function init(){try{let j=await bot({action:'init'});document.getElementById('status').textContent='';addMsg(msg(j)+suggestions(j),'bot',true);}catch(e){document.getElementById('status').textContent='Lỗi bot: '+e.message;addMsg('Chưa kết nối được bot.','bot');}}
function sendText(t){document.getElementById('q').value=t;sendQuestion();}
async function sendQuestion(){const i=document.getElementById('q');const t=(i.value||'').trim();if(!t)return;i.value='';addMsg(t,'me');const loading=addMsg('Đang trả lời...','bot');try{let j=await bot({action:'ask',message:t,q:t});loading.innerHTML=msg(j)+suggestions(j);}catch(e){loading.textContent='Lỗi: '+e.message;}}
async function chooseSuggestion(id){const loading=addMsg('Đang mở...','bot');try{let j=await bot({action:'choose',kich_ban_id:id,id:id});loading.innerHTML=msg(j)+suggestions(j);}catch(e){loading.textContent='Lỗi: '+e.message;}}
init();
</script>
</body>
</html>
