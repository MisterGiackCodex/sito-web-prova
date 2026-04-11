/* =============================================
   NAVBAR — scrolled state
   ============================================= */
const nav = document.getElementById('nav');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 40);
}, { passive: true });

/* =============================================
   MOBILE NAV — hamburger drawer
   ============================================= */
const hamburgerBtn = document.getElementById('hamburgerBtn');
const drawer = document.getElementById('drawer');

function openNav() {
  drawer.classList.add('open');
  drawer.setAttribute('aria-hidden', 'false');
  hamburgerBtn.setAttribute('aria-expanded', 'true');
  hamburgerBtn.setAttribute('aria-label', 'Chiudi menu');
}

function closeNav() {
  drawer.classList.remove('open');
  drawer.setAttribute('aria-hidden', 'true');
  hamburgerBtn.setAttribute('aria-expanded', 'false');
  hamburgerBtn.setAttribute('aria-label', 'Apri menu');
}

function toggleNav() {
  drawer.classList.contains('open') ? closeNav() : openNav();
}

hamburgerBtn.addEventListener('click', toggleNav);

// Close drawer when a link is clicked
drawer.querySelectorAll('a').forEach(link => {
  link.addEventListener('click', closeNav);
});

// Close drawer on Escape
document.addEventListener('keydown', e => {
  if (e.key === 'Escape' && drawer.classList.contains('open')) {
    closeNav();
    hamburgerBtn.focus();
  }
});

/* =============================================
   MARQUEE — duplicate for seamless loop
   ============================================= */
const marqueeInner = document.getElementById('marqueeInner');
if (marqueeInner) {
  const clone = marqueeInner.cloneNode(true);
  clone.setAttribute('aria-hidden', 'true');
  marqueeInner.parentElement.appendChild(clone);
}

/* =============================================
   SCROLL REVEAL — IntersectionObserver
   ============================================= */
const revealObs = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (!entry.isIntersecting) return;
    const idx = parseFloat(entry.target.dataset.revealIdx || 0);
    const delay = idx * 60; // 60ms stagger
    setTimeout(() => entry.target.classList.add('in'), delay);
    revealObs.unobserve(entry.target);
  });
}, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

document.querySelectorAll('.reveal').forEach((el, globalIdx) => {
  // Stagger siblings within same parent container
  const parent = el.parentElement;
  const siblings = [...parent.querySelectorAll(':scope > .reveal')];
  const sibIdx = siblings.indexOf(el);
  el.dataset.revealIdx = sibIdx >= 0 ? sibIdx : 0;
  revealObs.observe(el);
});

/* =============================================
   SCROLL SPY — active nav link
   ============================================= */
const sections = document.querySelectorAll('main section[id]');
const navLinks = document.querySelectorAll('.nav-menu a[href^="#"]');

const spyObs = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (!entry.isIntersecting) return;
    navLinks.forEach(a => {
      a.classList.remove('active');
      a.removeAttribute('aria-current');
    });
    const active = document.querySelector(`.nav-menu a[href="#${entry.target.id}"]`);
    if (active) {
      active.classList.add('active');
      active.setAttribute('aria-current', 'true');
    }
  });
}, { threshold: 0.4 });

sections.forEach(s => spyObs.observe(s));
