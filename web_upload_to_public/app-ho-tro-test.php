<?php
// app-ho-tro-test.php
// Trang hỗ trợ test cho app.
// Yêu cầu:
// - Thanh mục lớn dưới cùng cố định.
// - Ô nhập chat cố định phía trên thanh mục.
// - Đoạn chat chỉ cuộn phần nội dung.
// - Link trong câu trả lời không hiện URL thô; chuyển thành nút "Mở liên kết".
// - Bấm link mở trong app/WebView hiện tại.

?>
<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<title>Hỗ trợ</title>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">

<style>
*{box-sizing:border-box}
:root{
    --green:#2f7d43;
    --green2:#16a34a;
    --soft:#eef2f7;
    --line:#e5e7eb;
    --text:#111827;
    --muted:#64748b;
    --nav-h:78px;
    --composer-h:116px;
}
body{
    margin:0;
    background:var(--soft);
    font-family:Arial,Helvetica,sans-serif;
    color:var(--text);
    overflow:hidden;
}
.app{
    width:100%;
    max-width:560px;
    height:100vh;
    margin:0 auto;
    position:relative;
    background:var(--soft);
    overflow:hidden;
}
.header{
    height:76px;
    padding:14px 14px 8px;
    display:flex;
    align-items:center;
    gap:12px;
    background:var(--soft);
    position:relative;
    z-index:5;
}
.logo{
    width:46px;
    height:46px;
    border-radius:16px;
    background:#dcfce7;
    color:#047857;
    display:flex;
    align-items:center;
    justify-content:center;
    font-size:25px;
    font-weight:900;
    flex:0 0 auto;
}
.title{
    flex:1;
}
h1{
    font-size:28px;
    margin:0;
    font-weight:900;
    line-height:1.05;
}
.reload{
    border:0;
    background:transparent;
    color:#374151;
    font-size:29px;
    font-weight:900;
    padding:8px;
}
.chat{
    height:calc(100vh - 76px - var(--composer-h) - var(--nav-h));
    overflow-y:auto;
    padding:8px 12px 14px;
    -webkit-overflow-scrolling:touch;
}
.msg{
    max-width:88%;
    margin:10px 0;
    padding:12px 14px;
    border-radius:15px;
    font-weight:800;
    line-height:1.38;
    box-shadow:0 2px 6px rgba(15,23,42,.05);
    word-break:break-word;
}
.bot{
    background:#fff;
    border:1px solid var(--line);
    border-bottom-left-radius:5px;
}
.me{
    background:var(--green2);
    color:#fff;
    margin-left:auto;
    border-bottom-right-radius:5px;
}
.suggest{
    display:flex;
    gap:8px;
    flex-wrap:wrap;
    margin-top:10px;
}
.suggest button,.quick button,.link-btn{
    border:1px solid #bbf7d0;
    background:#ecfdf5;
    color:#166534;
    border-radius:13px;
    padding:9px 12px;
    font-weight:900;
    font-size:15px;
}
.link-btn{
    display:inline-flex;
    align-items:center;
    gap:6px;
    margin-top:8px;
    text-decoration:none;
}
.composer{
    position:fixed;
    left:50%;
    bottom:var(--nav-h);
    transform:translateX(-50%);
    width:100%;
    max-width:560px;
    height:var(--composer-h);
    background:#fff;
    border-top:1px solid var(--line);
    padding:9px 12px 10px;
    z-index:20;
    box-shadow:0 -6px 18px rgba(15,23,42,.06);
}
.quick{
    height:42px;
    display:flex;
    gap:8px;
    overflow-x:auto;
    white-space:nowrap;
    padding-bottom:5px;
}
.quick::-webkit-scrollbar{display:none}
.inputrow{
    height:58px;
    display:flex;
    gap:8px;
    align-items:center;
}
input{
    flex:1;
    height:56px;
    border:1px solid #d1d5db;
    border-radius:18px;
    padding:0 15px;
    font-size:16px;
    outline:none;
    background:#f8fafc;
    font-weight:600;
}
button.send{
    border:0;
    background:var(--green);
    color:#fff;
    border-radius:50%;
    width:56px;
    height:56px;
    font-size:25px;
    font-weight:900;
    flex:0 0 auto;
}
.app-nav{
    position:fixed;
    left:50%;
    bottom:0;
    transform:translateX(-50%);
    width:100%;
    max-width:560px;
    height:var(--nav-h);
    background:#eef5e9;
    border-top:1px solid #dde7d7;
    display:grid;
    grid-template-columns:repeat(5,1fr);
    z-index:30;
    box-shadow:0 -4px 16px rgba(15,23,42,.08);
}
.nav-item{
    border:0;
    background:transparent;
    color:#34403a;
    font-size:12px;
    font-weight:800;
    display:flex;
    flex-direction:column;
    align-items:center;
    justify-content:center;
    gap:4px;
}
.nav-item .ico{
    font-size:23px;
    line-height:1;
}
.nav-item.active{
    background:#d9f2d7;
    border-radius:22px;
    margin:9px 8px;
    color:#166534;
}
.nav-item.active .label{
    color:#166534;
}
.nav-item.active .ico{
    transform:translateY(-1px);
}
.empty-space{
    height:8px;
}
</style>
</head>

<body>
<div class="app">
    <div class="header">
        <div class="logo">🎧</div>
        <div class="title"><h1>Hỗ trợ</h1></div>
        <button class="reload" onclick="resetChat()">↻</button>
    </div>

    <div class="chat" id="chat"></div>

    <div class="composer">
        <div class="quick" id="quick"></div>
        <div class="inputrow">
            <input id="q" placeholder="Nhập nội dung..." onkeydown="if(event.key==='Enter') sendQuestion()">
            <button class="send" onclick="sendQuestion()">➤</button>
        </div>
    </div>

    <div class="app-nav">
        <button class="nav-item" onclick="goApp('/')">
            <span class="ico">🏠</span><span class="label">Trang chủ</span>
        </button>
        <button class="nav-item" onclick="goApp('/quan-li')">
            <span class="ico">📁</span><span class="label">Quản lí</span>
        </button>
        <button class="nav-item active" onclick="resetChat()">
            <span class="ico">🎧</span><span class="label">Hỗ trợ</span>
        </button>
        <button class="nav-item" onclick="goApp('/thong-bao')">
            <span class="ico">🔔</span><span class="label">Thông báo</span>
        </button>
        <button class="nav-item" onclick="goApp('/tai-khoan')">
            <span class="ico">👤</span><span class="label">Tài khoản</span>
        </button>
    </div>
</div>

<script>
const API = '/bot-api-app.php';

function escapeHtml(str){
    return String(str).replace(/[&<>"']/g, m => ({
        '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#039;'
    }[m]));
}

function normalizeUrl(url){
    url = String(url || '').trim();
    if(!url) return '';

    if(url.startsWith('http://xaydungvn.com.vn')){
        url = url.replace('http://xaydungvn.com.vn','https://xaydungvn.com.vn');
    }

    if(url.startsWith('/')){
        url = 'https://xaydungvn.com.vn' + url;
    }

    if(url.startsWith('xaydungvn.com.vn')){
        url = 'https://' + url;
    }

    if(url.includes('xaydungvn.com.vn') && !url.includes('app=1')){
        url += (url.includes('?') ? '&' : '?') + 'app=1';
    }

    return url;
}

function stripLinksToButtons(text){
    let safe = escapeHtml(text || '');

    const urls = [];
    safe = safe.replace(/https?:\/\/[^\s<>"']+/g, function(match){
        const clean = match.replace(/&amp;/g,'&');
        urls.push(clean);
        return '';
    });

    safe = safe.replace(/\n{3,}/g, '\n\n').trim();

    let html = safe.replace(/\n/g,'<br>');

    urls.forEach((u, i) => {
        const url = normalizeUrl(u);
        if(url){
            html += `<br><button class="link-btn" onclick="openInApp('${url.replace(/'/g,"\\'")}')">🔗 Mở liên kết</button>`;
        }
    });

    return html || 'Bot chưa có phản hồi.';
}

function addMsg(text, type, suggestions=[]){
    const chat = document.getElementById('chat');
    const div = document.createElement('div');
    div.className = 'msg ' + type;

    if(type === 'bot'){
        div.innerHTML = stripLinksToButtons(text);
    }else{
        div.textContent = text;
    }

    if(suggestions && suggestions.length){
        const sug = document.createElement('div');
        sug.className = 'suggest';
        suggestions.forEach(s => {
            const title = s.title || s.tieu_de || s.text || 'Xem';
            const btn = document.createElement('button');
            btn.textContent = title;
            btn.onclick = () => chooseSuggestion(s);
            sug.appendChild(btn);
        });
        div.appendChild(sug);
    }

    chat.appendChild(div);
    chat.scrollTop = chat.scrollHeight;
}

function setQuick(items){
    const quick = document.getElementById('quick');
    quick.innerHTML = '';
    (items || []).forEach(s => {
        const title = s.title || s.tieu_de || s.text || 'Xem';
        const btn = document.createElement('button');
        btn.textContent = title;
        btn.onclick = () => chooseSuggestion(s);
        quick.appendChild(btn);
    });
}

async function callBot(data){
    const fd = new FormData();
    Object.keys(data).forEach(k => fd.append(k, data[k]));
    const res = await fetch(API, {method:'POST', body:fd, credentials:'include'});
    const raw = await res.text();
    let json;
    try { json = JSON.parse(raw); }
    catch(e){ throw new Error(raw.slice(0,220)); }

    if(!json.ok && !json.success){
        throw new Error(json.message || 'Bot lỗi');
    }

    return json;
}

async function init(){
    try{
        const j = await callBot({action:'init'});
        addMsg(j.message || 'Xin chào!', 'bot', j.suggestions || []);
        setQuick(j.suggestions || []);
    }catch(e){
        addMsg('Không gọi được bot: ' + e.message, 'bot');
    }
}

function resetChat(){
    document.getElementById('chat').innerHTML = '';
    init();
}

async function sendQuestion(){
    const inp = document.getElementById('q');
    const text = inp.value.trim();
    if(!text) return;

    inp.value = '';
    addMsg(text, 'me');

    try{
        const j = await callBot({action:'ask', message:text});
        addMsg(j.message || 'Bot chưa có phản hồi.', 'bot', j.suggestions || []);
        if(j.suggestions) setQuick(j.suggestions);
    }catch(e){
        addMsg('Lỗi: ' + e.message, 'bot');
    }
}

async function chooseSuggestion(s){
    const title = s.title || s.tieu_de || s.text || 'Xem';
    addMsg(title, 'me');

    // Nếu gợi ý có link_url thì mở thẳng, không hiện URL trong chat.
    if(s.link_url){
        openInApp(normalizeUrl(s.link_url));
        return;
    }

    try{
        let data;
        if(s.kich_ban_id || s.id){
            data = {action:'choose', kich_ban_id:(s.kich_ban_id || s.id)};
        }else{
            data = {action:'ask', message:title};
        }

        const j = await callBot(data);
        addMsg(j.message || 'Bot chưa có phản hồi.', 'bot', j.suggestions || []);
        if(j.suggestions) setQuick(j.suggestions);
    }catch(e){
        addMsg('Lỗi: ' + e.message, 'bot');
    }
}

function openInApp(url){
    url = normalizeUrl(url);
    if(!url) return;

    // WebView sẽ mở trong app hiện tại.
    window.location.href = url;
}

function goApp(path){
    // Khi test web thì mở link mẫu. Trong Flutter app, tab dưới là app cứng nên phần này chỉ để test.
    const map = {
        '/':'https://xaydungvn.com.vn/?app=1',
        '/quan-li':'https://xaydungvn.com.vn/xe-cua-toi?tab=quanly&app=1',
        '/thong-bao':'https://xaydungvn.com.vn/thong-bao.php?app=1',
        '/tai-khoan':'https://xaydungvn.com.vn/thong-tin-ca-nhan.php?app=1'
    };
    window.location.href = map[path] || 'https://xaydungvn.com.vn/?app=1';
}

init();
</script>
</body>
</html>
