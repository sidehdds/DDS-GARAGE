// Paywall partagé — s'injecte automatiquement dans toutes les pages

function paywallInit() {
  if (document.getElementById('paywall-overlay')) return;
  const div = document.createElement('div');
  div.id = 'paywall-overlay';
  div.className = 'paywall-overlay';
  div.style.display = 'none';
  div.innerHTML = `
    <div class="paywall-box">
      <div class="paywall-icon">🔒</div>
      <div class="paywall-title">Limite atteinte</div>
      <p class="paywall-sub">Tu as utilisé tes 3 recherches gratuites.<br/>Passe à Premium pour un accès illimité.</p>
      <div class="paywall-features">
        <div class="paywall-feature"><span class="paywall-feature-icon">⚡</span>Recherches de plaques illimitées</div>
        <div class="paywall-feature"><span class="paywall-feature-icon">🔍</span>Diagnostics IA illimités</div>
        <div class="paywall-feature"><span class="paywall-feature-icon">⚙️</span>Tuning & Reprogrammation</div>
        <div class="paywall-feature"><span class="paywall-feature-icon">🛡️</span>Historique véhicule</div>
      </div>
      <div class="paywall-price">4.99€</div>
      <div class="paywall-price-sub">par mois — résiliable à tout moment</div>
      <button class="paywall-btn" onclick="paywallCheckout()">S'abonner maintenant →</button>
      <div class="paywall-promo-row">
        <input type="text" id="paywall-promo-input" class="paywall-promo-input" placeholder="Code promo…" autocomplete="off"/>
        <button class="paywall-promo-btn" onclick="paywallPromo()">Appliquer</button>
      </div>
      <div id="paywall-promo-msg" class="paywall-promo-error" style="display:none"></div>
    </div>
  `;
  document.body.appendChild(div);
}

function showPaywall() {
  paywallInit();
  document.getElementById('paywall-overlay').style.display = 'flex';
}

async function paywallCheckout() {
  let user_id = '', email = '';
  try {
    const sbClient = window.supabase?.createClient(
      'https://oakhuffubspawhqtbigv.supabase.co',
      'sb_publishable_CVs7EnDiKwVB87nrB-QFNw_sVb2bDzy'
    );
    if (sbClient) {
      const { data: { session } } = await sbClient.auth.getSession();
      if (session?.user) { user_id = session.user.id; email = session.user.email; }
    }
  } catch {}
  const res = await fetch('/api/create-checkout', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({user_id, email})
  });
  const data = await res.json();
  if (data.url) window.location.href = data.url;
}

async function paywallPromo() {
  const code = document.getElementById('paywall-promo-input').value.trim();
  if (!code) return;
  const res = await fetch('/api/redeem-promo', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({code})
  });
  const data = await res.json();
  const msg = document.getElementById('paywall-promo-msg');
  msg.style.display = 'block';
  if (data.success) {
    localStorage.setItem('premium_token', data.token);
    msg.style.color = '#4ade80';
    msg.textContent = '✅ Code activé ! Rechargement…';
    setTimeout(() => window.location.reload(), 1200);
  } else {
    msg.style.color = '#f87171';
    msg.textContent = '❌ Code invalide';
  }
}

function getPremiumHeaders() {
  const token = localStorage.getItem('premium_token') || '';
  const headers = {'Content-Type': 'application/json'};
  if (token) headers['X-Premium-Token'] = token;
  try {
    const sbClient = window._sbClient;
    if (sbClient) {
      sbClient.auth.getSession().then(({ data: { session } }) => {
        if (session?.user) window._currentUserId = session.user.id;
      });
    }
    if (window._currentUserId) headers['X-User-Id'] = window._currentUserId;
  } catch {}
  return headers;
}

// Init user ID from Supabase session
document.addEventListener('DOMContentLoaded', async () => {
  paywallInit();
  try {
    const sbClient = window.supabase?.createClient(
      'https://oakhuffubspawhqtbigv.supabase.co',
      'sb_publishable_CVs7EnDiKwVB87nrB-QFNw_sVb2bDzy'
    );
    if (sbClient) {
      window._sbClient = sbClient;
      const { data: { session } } = await sbClient.auth.getSession();
      if (session?.user) window._currentUserId = session.user.id;
    }
  } catch {}
});