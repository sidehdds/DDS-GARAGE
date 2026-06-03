const LC_SID = (() => {
  let id = localStorage.getItem('lc_sid');
  if (!id) { id = 'v_' + Math.random().toString(36).slice(2, 11); localStorage.setItem('lc_sid', id); }
  return id;
})();

let lcName = localStorage.getItem('lc_name') || '';
let lcOpen = false, lcSock = null, lcConn = false, lcUnread = 0, lcPendingFile = null;

function lcToggle() {
  lcOpen = !lcOpen;
  document.getElementById('lc-panel').classList.toggle('lc-hidden', !lcOpen);
  if (lcOpen) { lcUnread = 0; lcUpdateBadge(); if (!lcSock) lcConnect(); if (lcName) lcShowChat(); }
}

function lcConnect() {
  lcSock = io();
  lcSock.on('connect', () => {
    lcConn = true;
    document.getElementById('lc-dot').classList.add('lc-online');
    document.getElementById('lc-sub').textContent = 'Mécanicien disponible';
    if (lcName) lcSock.emit('visitor_connect', { session_id: LC_SID, name: lcName });
  });
  lcSock.on('disconnect', () => {
    lcConn = false;
    document.getElementById('lc-dot').classList.remove('lc-online');
    document.getElementById('lc-sub').textContent = 'Reconnexion…';
  });
  lcSock.on('admin_reply', (msg) => {
    lcRenderMsg(msg);
    if (!lcOpen) { lcUnread++; lcUpdateBadge(); }
  });
  lcSock.on('admin_typing', (d) => {
    document.getElementById('lc-typing').classList.toggle('lc-hidden', !d.typing);
    const m = document.getElementById('lc-messages'); m.scrollTop = m.scrollHeight;
  });
}

function lcSetName() {
  const v = document.getElementById('lc-name-input').value.trim();
  if (!v) return;
  lcName = v; localStorage.setItem('lc_name', v);
  if (lcSock && lcConn) lcSock.emit('visitor_connect', { session_id: LC_SID, name: lcName });
  lcShowChat();
}

function lcShowChat() {
  document.getElementById('lc-name-screen').classList.add('lc-hidden');
  document.getElementById('lc-chat-screen').classList.remove('lc-hidden');
}

function lcFileSelected(e) {
  const file = e.target.files[0];
  if (!file) return;
  if (file.size > 10 * 1024 * 1024) { alert('Fichier trop lourd (max 10 Mo)'); e.target.value = ''; return; }
  const reader = new FileReader();
  reader.onload = (ev) => {
    lcPendingFile = { data: ev.target.result, name: file.name, mime: file.type };
    const thumb = document.getElementById('lc-attach-thumb');
    if (file.type.startsWith('image/')) {
      thumb.src = ev.target.result; thumb.style.display = 'block';
    } else {
      thumb.style.display = 'none';
    }
    document.getElementById('lc-attach-name').textContent = file.name;
    document.getElementById('lc-attach-preview').classList.remove('lc-hidden');
  };
  reader.readAsDataURL(file);
}

function lcCancelAttach() {
  lcPendingFile = null;
  document.getElementById('lc-attach-preview').classList.add('lc-hidden');
  document.getElementById('lc-file-input').value = '';
}

function lcSend() {
  if (!lcConn) return;
  const inp = document.getElementById('lc-input');
  const txt = inp.value.trim();
  const now = new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });

  if (lcPendingFile) {
    const isImage = lcPendingFile.mime.startsWith('image/');
    const type = isImage ? 'image' : 'file';
    lcSock.emit('visitor_message', {
      session_id: LC_SID, name: lcName, type,
      data: lcPendingFile.data, fileName: lcPendingFile.name, message: txt
    });
    lcRenderMsg({ role: 'visitor', type, data: lcPendingFile.data, fileName: lcPendingFile.name, text: txt, time: now });
    lcCancelAttach(); inp.value = '';
    return;
  }

  if (!txt) return;
  inp.value = '';
  lcSock.emit('visitor_message', { session_id: LC_SID, name: lcName, type: 'text', message: txt });
  lcRenderMsg({ role: 'visitor', type: 'text', text: txt, time: now });
}

function lcRenderMsg(msg) {
  const box = document.getElementById('lc-messages');
  const d = document.createElement('div');
  d.className = 'lc-msg lc-msg-' + (msg.role || 'visitor');

  let inner = '';
  if (msg.type === 'image') {
    inner = `<img src="${msg.data}" class="lc-msg-img" onclick="window.open(this.src)" alt="Photo"/>`;
    if (msg.text) inner += `<span class="lc-msg-caption">${lcEsc(msg.text)}</span>`;
  } else if (msg.type === 'file') {
    inner = `<a href="${msg.data}" download="${lcEsc(msg.fileName||'fichier')}" class="lc-msg-file">
      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
      ${lcEsc(msg.fileName || 'Fichier')}
    </a>`;
    if (msg.text) inner += `<span class="lc-msg-caption">${lcEsc(msg.text)}</span>`;
  } else {
    inner = `<span class="lc-msg-text">${lcEsc(msg.text || '')}</span>`;
  }
  inner += `<span class="lc-msg-time">${msg.time || ''}</span>`;
  d.innerHTML = inner;
  box.appendChild(d);
  box.scrollTop = box.scrollHeight;
}

function lcUpdateBadge() {
  const b = document.getElementById('lc-badge');
  b.textContent = lcUnread; b.classList.toggle('lc-hidden', lcUnread === 0);
}

function lcEsc(s) { return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
