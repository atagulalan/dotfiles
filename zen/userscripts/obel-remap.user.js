// ==UserScript==
// @name         Obel palette remap
// @namespace    obel
// @version      1.1
// @description  Google / WhatsApp Web / ChatGPT renklerini değerine göre Obel paletine çevirir (sınıf adı gerektirmez).
// @match        https://www.google.com/*
// @match        https://www.google.com.tr/*
// @exclude      https://www.google.com/maps*
// @exclude      https://www.google.com.tr/maps*
// @match        https://web.whatsapp.com/*
// @match        https://chatgpt.com/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

/* CSS (userContent.css) değişkenleri ve bilinen seçicileri hallediyor; bu script
   sınıf adı obfuscate edilmiş ya da değişkeni bilinmeyen kalıntıları yakalar:
   her öğenin hesaplanmış rengine bakar, paletteki karşılığını inline !important yazar. */
(() => {
  'use strict';

  const H = location.hostname;
  const SITE = H.includes('whatsapp') ? 'wa' : H.includes('chatgpt') ? 'gpt' : 'g';

  const C = {
    bg: '#000000', s1: '#0a0a0a', s2: '#161616', edge: '#333333',
    acc: '#ff3c05', accDim: '#a8300a', onAcc: '#000000',
  };
  // Zaten bizim paletteki renkler — dokunma (yoksa kendi çıktımızı tekrar işleriz)
  const TOKENS = new Set([
    '0,0,0', '10,10,10', '17,17,17', '22,22,22', '26,26,26', '38,38,38',
    '51,51,51', '255,60,5', '168,48,10', '230,54,0', '255,106,61',
    '241,241,239', '189,189,187', '106,106,104',
  ]);

  const parse = (s) => {
    const m = s && s.match(/rgba?\(([^)]+)\)/);
    if (!m) return null;
    const p = m[1].split(/[\s,/]+/).filter(Boolean).map(Number);
    return { r: p[0], g: p[1], b: p[2], a: p.length > 3 ? p[3] : 1 };
  };
  const hsl = ({ r, g, b }) => {
    r /= 255; g /= 255; b /= 255;
    const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2;
    if (mx === mn) return { h: 0, s: 0, l };
    const d = mx - mn, s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
    let h = mx === r ? (g - b) / d + (g < b ? 6 : 0) : mx === g ? (b - r) / d + 2 : (r - g) / d + 4;
    return { h: h * 60, s, l };
  };
  const key = (c) => `${c.r},${c.g},${c.b}`;
  const neutral = (c, x) => Math.max(c.r, c.g, c.b) - Math.min(c.r, c.g, c.b) <= 24 && x.s < 0.3;
  const blue = (x) => x.h >= 190 && x.h <= 245 && x.s > 0.3;
  const green = (x) => x.h >= 110 && x.h <= 180 && x.s > 0.25;
  const purple = (x) => x.h > 250 && x.h <= 300 && x.s > 0.3;

  // Zemin rengi → {bg, border?, acc?}
  function mapBg(c, el) {
    if (!c || c.a < 0.9 || TOKENS.has(key(c))) return null;
    const x = hsl(c);
    const r = el.getBoundingClientRect();
    const thin = r.height > 0 && r.height <= 4 && r.width > 8;

    if (SITE === 'g') {
      if (neutral(c, x)) {
        if (thin) return { bg: x.l > 0.75 ? C.acc : C.edge };          // sekme alt çizgisi / ayraç
        if (x.l < 0.15) return { bg: C.bg };                            // #202124 sayfa zemini
        if (x.l < 0.4) return { bg: C.s1, border: C.edge };             // #303134 kartlar
        return null;
      }
      if (blue(x)) return { bg: C.acc, acc: true };                     // mavi butonlar
      return null;
    }
    if (SITE === 'wa') {
      if (green(x)) return { bg: C.acc, acc: true };                    // giden balon, yeşil butonlar
      if (neutral(c, x) || (x.h >= 190 && x.h <= 215 && x.l < 0.25)) {  // #111b21 / #202c33 tonları
        if (x.l < 0.16) return { bg: C.bg };
        if (x.l < 0.3) return { bg: C.s2 };
      }
      return null;
    }
    // gpt
    if (blue(x)) return { bg: C.acc, acc: true };                       // kullanıcı balonu, durdur butonu
    if (neutral(c, x) && x.l > 0.06 && x.l < 0.3) return { bg: C.s1 };  // #1e1e1e / #303030 yüzeyler
    return null;
  }

  // Yazı rengi
  function mapText(c, el) {
    if (!c || TOKENS.has(key(c))) return null;
    const x = hsl(c);
    if (x.l < 0.35) {
      // Google: zeminler şeffaf → koyu yazı siyah üstünde kalır; doğrudan metni olan öğeyi aç
      if (SITE === 'g' && c.a > 0.5 && el && [...el.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim())
          && !el.closest('[data-obel-acc], #searchform, form[role="search"]')) return '#f1f1ef';
      return null;
    }
    if (blue(x)) return C.acc;
    if (purple(x)) return C.accDim;
    if (SITE === 'wa' && green(x)) return C.acc;
    return null;
  }

  // Kenarlık rengi (Google ayraçları)
  function mapBorder(cs) {
    if (SITE !== 'g') return null;
    for (const side of ['Top', 'Right', 'Bottom', 'Left']) {
      if (parseFloat(cs[`border${side}Width`]) > 0) {
        const c = parse(cs[`border${side}Color`]);
        if (c && c.a > 0.5 && !TOKENS.has(key(c))) {
          const x = hsl(c);
          if (neutral(c, x) && x.l > 0.15 && x.l < 0.5) return C.edge;
          if (blue(x)) return C.acc;
        }
      }
    }
    return null;
  }

  const SKIP = new Set(['IMG', 'VIDEO', 'CANVAS', 'PICTURE', 'SOURCE', 'SCRIPT', 'STYLE', 'LINK', 'META', 'HTML', 'HEAD', 'IFRAME', 'PATH']);
  const set = (el, prop, val, tag) => {
    el.style.setProperty(prop, val, 'important');
    el.dataset.obel = ((el.dataset.obel || '') + ' ' + tag).trim();
  };

  function restore(el) {
    const t = el.dataset.obel;
    if (!t) return;
    if (t.includes('bg')) el.style.removeProperty('background-color');
    if (t.includes('bd')) { el.style.removeProperty('border'); el.style.removeProperty('border-color'); }
    if (t.includes('tx')) el.style.removeProperty('color');
    if (t.includes('acc')) {
      for (const v of ACC_VARS) el.style.removeProperty(v);
      el.removeAttribute('data-obel-acc');
    }
    delete el.dataset.obel;
  }

  // Turuncu zeminli öğe altında yazı siyah olsun (değişkenler miras kalır)
  const ACC_VARS = [
    '--message-primary', '--WDS-content-default', '--WDS-content-deemphasized',
    '--bubble-meta', '--bubble-meta-icon', '--text-primary', '--text-secondary',
    '--icon-ack',
  ];

  function processEl(el) {
    if (el.nodeType !== 1 || SKIP.has(el.tagName.toUpperCase()) || (el.dataset && el.dataset.obel)) return;
    if (el.closest('svg') && el.tagName.toLowerCase() !== 'svg') return;
    const cs = getComputedStyle(el);
    if (el.tagName.toLowerCase() === 'svg') {
      for (const prop of ['color', 'fill']) {
        const c = parse(cs[prop]);
        if (c && !TOKENS.has(key(c)) && blue(hsl(c))) {
          el.style.setProperty(prop, C.acc, 'important');
          el.setAttribute('data-obel', 'tx');
        }
      }
      // svg içindeki path'ler fill'i kendisi taşıyorsa
      el.querySelectorAll('[fill]').forEach((n) => {
        const c = parse(getComputedStyle(n).fill);
        if (c && blue(hsl(c))) n.style.setProperty('fill', C.acc, 'important');
      });
      return;
    }

    const b = mapBg(parse(cs.backgroundColor), el);
    if (b) {
      set(el, 'background-color', b.bg, 'bg');
      if (b.border) set(el, 'border', `1px solid ${b.border}`, 'bd');
      if (b.acc) {
        el.setAttribute('data-obel-acc', '');
        for (const v of ACC_VARS) el.style.setProperty(v, C.onAcc, 'important');
        set(el, 'color', C.onAcc, 'tx acc');
      }
    }

    if (!el.dataset.obel || !el.dataset.obel.includes('tx')) {
      if (el.closest('[data-obel-acc]') && el.childNodes.length) {
        const c = parse(cs.color);
        if (c && hsl(c).l > 0.5) set(el, 'color', C.onAcc, 'tx');
      } else {
        const t = mapText(parse(cs.color), el);
        if (t) set(el, 'color', t, 'tx');
      }
    }

    if (!b || !b.border) {
      const bd = mapBorder(cs);
      if (bd) set(el, 'border-color', bd, 'bd');
    }
  }

  // ChatGPT: yazı kutusunun zeminli ilk atasına turuncu çerçeve
  function gptComposer() {
    const ta = document.querySelector('#prompt-textarea');
    if (!ta) return;
    for (let e = ta.parentElement; e && e !== document.body; e = e.parentElement) {
      if (e.tagName === 'FORM') break;
      const c = parse(getComputedStyle(e).backgroundColor);
      if (c && c.a > 0.5) {
        if (!e.hasAttribute('data-obel-composer')) {
          document.querySelectorAll('[data-obel-composer]').forEach((o) => {
            o.removeAttribute('data-obel-composer');
            o.style.removeProperty('outline');
          });
          e.setAttribute('data-obel-composer', '');
          e.style.setProperty('outline', `1px solid ${C.acc}`, 'important');
          e.style.setProperty('outline-offset', '-1px', 'important');
        }
        return;
      }
    }
  }

  function scan(root) {
    if (root.nodeType !== 1) return;
    processEl(root);
    root.querySelectorAll('*').forEach(processEl);
  }

  // Değişiklikleri kare başına bir kez işle
  const pending = new Set();
  let scheduled = false;
  function queue(n) {
    pending.add(n);
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(() => {
      scheduled = false;
      const items = [...pending];
      pending.clear();
      for (const n of items) if (n.isConnected) scan(n);
      if (SITE === 'gpt') gptComposer();
    });
  }

  function start() {
    scan(document.body);
    if (SITE === 'gpt') gptComposer();
    new MutationObserver((muts) => {
      for (const m of muts) {
        if (m.type === 'childList') m.addedNodes.forEach((n) => n.nodeType === 1 && queue(n));
        else if (m.type === 'attributes' && m.target.nodeType === 1) {
          restore(m.target);
          queue(m.target);
        }
      }
    }).observe(document.documentElement, {
      childList: true, subtree: true, attributes: true, attributeFilter: ['class'],
    });
  }

  if (document.body) start();
  else document.addEventListener('DOMContentLoaded', start, { once: true });
})();
