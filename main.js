/* =============================================
   CUSTOM CURSOR
   ============================================= */
const cursor     = document.createElement('div'); cursor.className = 'cursor';
const cursorRing = document.createElement('div'); cursorRing.className = 'cursor-ring';
document.body.prepend(cursor, cursorRing);

let mx = 0, my = 0, rx = 0, ry = 0;
document.addEventListener('mousemove', e => { mx = e.clientX; my = e.clientY; });
(function animCursor() {
  rx += (mx - rx) * 0.14;
  ry += (my - ry) * 0.14;
  cursor.style.left     = mx + 'px';
  cursor.style.top      = my + 'px';
  cursorRing.style.left = rx + 'px';
  cursorRing.style.top  = ry + 'px';
  requestAnimationFrame(animCursor);
})();

document.querySelectorAll('a, button, .svc, .bcard:not(.bcard--soon)').forEach(el => {
  el.addEventListener('mouseenter', () => { cursor.classList.add('hover'); cursorRing.classList.add('hover'); });
  el.addEventListener('mouseleave', () => { cursor.classList.remove('hover'); cursorRing.classList.remove('hover'); });
});

/* =============================================
   NAVBAR SCROLL
   ============================================= */
const nav = document.getElementById('nav');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 40);
}, { passive: true });

/* =============================================
   MOBILE NAV
   ============================================= */
function toggleNav() {
  document.getElementById('drawer').classList.toggle('open');
}

/* =============================================
   MARQUEE — duplicate content for seamless loop
   ============================================= */
const mi = document.getElementById('marqueeInner');
if (mi) {
  const clone = mi.cloneNode(true);
  mi.parentElement.appendChild(clone);
}

/* =============================================
   SCROLL REVEAL
   ============================================= */
const revealObs = new IntersectionObserver((entries) => {
  entries.forEach((e, i) => {
    if (e.isIntersecting) {
      const delay = parseFloat(e.target.dataset.delay || 0);
      setTimeout(() => e.target.classList.add('in'), delay * 1000);
      revealObs.unobserve(e.target);
    }
  });
}, { threshold: 0.12 });

document.querySelectorAll('.reveal').forEach((el, i) => {
  const parent = el.parentElement;
  const siblings = [...parent.querySelectorAll('.reveal')];
  el.dataset.delay = siblings.indexOf(el) * 0.1;
  revealObs.observe(el);
});

/* =============================================
   COUNTER ANIMATION
   ============================================= */
function animateCounter(el) {
  const target = parseInt(el.dataset.target, 10);
  const duration = 1400;
  const start = performance.now();
  function update(now) {
    const p = Math.min((now - start) / duration, 1);
    const ease = 1 - Math.pow(1 - p, 3);
    el.textContent = Math.floor(ease * target);
    if (p < 1) requestAnimationFrame(update);
    else el.textContent = target;
  }
  requestAnimationFrame(update);
}

const counterObs = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      animateCounter(e.target);
      counterObs.unobserve(e.target);
    }
  });
}, { threshold: 0.5 });

document.querySelectorAll('[data-target]').forEach(el => counterObs.observe(el));

/* =============================================
   BENTO CARD MOUSE GLOW
   ============================================= */
document.querySelectorAll('.bcard').forEach(card => {
  card.addEventListener('mousemove', e => {
    const r = card.getBoundingClientRect();
    const x = ((e.clientX - r.left) / r.width) * 100;
    const y = ((e.clientY - r.top) / r.height) * 100;
    const glow = card.querySelector('.bcard-glow');
    if (glow) glow.style.background = `radial-gradient(circle at ${x}% ${y}%, rgba(124,58,237,0.18), transparent 60%)`;
  });
});

/* =============================================
   SERVICE ROW HOVER ACCENT
   ============================================= */
document.querySelectorAll('.svc').forEach(svc => {
  const num = svc.getAttribute('data-n');
});

/* =============================================
   CONTACT FORM — Formspree
   ============================================= */
document.getElementById('contactForm').addEventListener('submit', async function (e) {
  e.preventDefault();
  const btn  = document.getElementById('cfSubmit');
  const msg  = document.getElementById('cfMsg');
  const text = document.getElementById('cfText');

  text.textContent = 'Invio in corso...';
  btn.disabled = true;
  msg.className = 'cf-msg';
  msg.textContent = '';

  const payload = {
    name:    this.name.value,
    email:   this.email.value,
    service: this.service.value,
    message: this.message.value,
  };

  try {
    const res = await fetch('https://formspree.io/f/FORM_ID', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify(payload),
    });
    if (res.ok) {
      msg.className = 'cf-msg ok';
      msg.textContent = '✓ Messaggio inviato! Ti rispondo entro 24 ore.';
      this.reset();
    } else { throw new Error(); }
  } catch {
    msg.className = 'cf-msg err';
    msg.textContent = '✕ Errore nell\'invio. Riprova tra qualche minuto.';
  } finally {
    text.textContent = 'Invia messaggio';
    btn.disabled = false;
  }
});

/* =============================================
   SMOOTH ACTIVE NAV ON SCROLL
   ============================================= */
const sections = document.querySelectorAll('section[id]');
const navLinks = document.querySelectorAll('.nav-menu a');
const scrollSpy = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      navLinks.forEach(a => a.classList.remove('active'));
      const active = document.querySelector(`.nav-menu a[href="#${e.target.id}"]`);
      if (active) active.classList.add('active');
    }
  });
}, { threshold: 0.4 });
sections.forEach(s => scrollSpy.observe(s));
