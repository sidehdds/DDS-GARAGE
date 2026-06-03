const SB_URL  = 'https://oakhuffubspawhqtbigv.supabase.co';
const SB_ANON = 'sb_publishable_CVs7EnDiKwVB87nrB-QFNw_sVb2bDzy';

let _sb = null;
function sb() {
  if (!_sb && window.supabase) _sb = window.supabase.createClient(SB_URL, SB_ANON);
  return _sb;
}

async function authInit() {
  if (!sb()) return;
  const { data: { session } } = await sb().auth.getSession();
  const user = session?.user;
  updateNavAuth(user);
}

function updateNavAuth(user) {
  const loginBtn  = document.getElementById('nav-login-btn');
  const garageBtn = document.getElementById('nav-garage-btn');
  const avatar    = document.getElementById('nav-avatar');
  if (user) {
    if (loginBtn)  loginBtn.style.display  = 'none';
    if (garageBtn) garageBtn.style.display = '';
    if (avatar) {
      const name = user.user_metadata?.full_name || user.email || '';
      avatar.textContent = name.charAt(0).toUpperCase() || '?';
      avatar.title = user.email;
      avatar.style.display = '';
    }
  } else {
    if (loginBtn)  loginBtn.style.display  = '';
    if (garageBtn) garageBtn.style.display = 'none';
    if (avatar)    avatar.style.display    = 'none';
  }
}

async function authSignOut() {
  await sb().auth.signOut();
  window.location.href = '/';
}

document.addEventListener('DOMContentLoaded', authInit);