// ── Cookie consent + AdSense loader ───────────────────────────────────────

const ADSENSE_ID = "ca-pub-XXXXXXXXXXXXXXXX"; // ← Remplace avec ton ID AdSense

function cookieInit() {
  const consent = localStorage.getItem('cookie_consent');
  if (consent === null) {
    document.getElementById('cookie-banner').style.display = 'flex';
  } else if (consent === 'accepted') {
    loadAds();
  }
}

function cookieAccept() {
  localStorage.setItem('cookie_consent', 'accepted');
  hideBanner();
  loadAds();
}

function cookieRefuse() {
  localStorage.setItem('cookie_consent', 'refused');
  hideBanner();
}

function hideBanner() {
  const b = document.getElementById('cookie-banner');
  if (b) { b.style.animation = 'slideDown .25s ease forwards'; setTimeout(() => b.remove(), 250); }
}

function loadAds() {
  if (ADSENSE_ID.includes('XXXX')) return; // ID pas encore configuré
  if (document.getElementById('adsense-script')) return;
  const s = document.createElement('script');
  s.id = 'adsense-script';
  s.async = true;
  s.src = `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${ADSENSE_ID}`;
  s.crossOrigin = 'anonymous';
  document.head.appendChild(s);
  s.onload = () => {
    document.querySelectorAll('.adsbygoogle').forEach(() => {
      try { (adsbygoogle = window.adsbygoogle || []).push({}); } catch {}
    });
  };
}

document.addEventListener('DOMContentLoaded', cookieInit);