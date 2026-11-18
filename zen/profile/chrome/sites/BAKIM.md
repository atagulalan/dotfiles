# Obel site temaları — bakım notları

Zen `chrome/userContent.css` → `sites/*.css` dosyalarını `@import` eder.
Değişiklikler **Zen tamamen kapatılıp açılınca** uygulanır (canlı yenileme yok).
Dotfiles kopyası: `~/dotfiles/zen/profile/chrome/` (zen/backup.sh ile de alınır).

| Dosya | Kapsam |
|---|---|
| `youtube.css` | youtube.com |
| `whatsapp.css` | web.whatsapp.com |
| `chatgpt.css` | chatgpt.com |
| `google.css` | google.com(.tr) ana sayfa + /search (Maps/Gmail hariç), ayrıca Görseller bloğu |
| `common.css` | ortak hover/seçili/odak çerçevesi kuralı (4 site) |
| `font.css` | Space Grotesk (4 site) |

Palet: bg `#000` · yüzey `#0a0a0a` / `#161616` · kenarlık `#333` (silik `#202020`, `#1a1a1a`)
· yazı `#f1f1ef` / `#bdbdbb` / soluk `#6a6a68` · vurgu `#ff3c05` (koyu `#a8300a`) · köşe 0.

## Yorum etiketleri (her bloğun üstünde)

- **ETKİ** — sayfada neyi değiştiriyor.
- **KANCA** — seçici neye tutunuyor ve ne kadar kalıcı:
  - `KALICI` → id, `aria-*`, `role`, `data-testid` / `data-*`, URL parametresi, özel element adı
    (`ytd-*`, `yt-*`, `g-*`). Yıllarca değişmez.
  - `ORTA` → okunabilir sınıf adı (`yt-spec-…`, `ytp-…`, `ytSpecButton…`, `sidebar-item`,
    `aim-lhs-panel-container`, `app-shell-left-panel`). Büyük tasarım değişikliğinde kırılır.
  - `KIRILGAN` → anlamsız kısa sınıf (`.RNNXgb`, `.b3puKe`, `.KFFQ0c`, `x1n2onr6`…). Her deploy'da değişebilir.
  - `GENEL` → sınıfa bağlı değil (`body *`, `:empty`, değişken ezme). Kırılmaz ama fazla şeye dokunabilir.
- **KIRILIRSA** — bozulunca ne aranacak.

## Bir şey bozulduğunda genel yöntem

1. Sorunlu öğeye sağ tık → **İncele**. Panelde yukarı çıkıp sayfada **görünen kutuyu tam
   kaplayan** satırı bul (mavi vurgu kutunun kenarına oturmalı).
2. O satırda kalıcı bir kanca ara, sırayla: `id` → `data-testid` / `data-*` → `aria-label` /
   `role` → özel element adı → okunabilir sınıf → (son çare) kısa sınıf.
3. **Rengi/gri zemini veren katmanı bul**: Styles panelinde `background` nereden geliyor?
   - Öğenin kendisi mi, bir üst katman mı, yoksa `::before` / `::after` mı? (Google çoğu gri
     kutuyu pseudo-element'le çiziyor; `body *` şeffaflaştırması pseudo'ya ulaşmaz.)
   - Çerçeve `border` mı, `box-shadow: inset` mi, `outline` mı?
4. Kenarlık/zemin **padding'i olan katmana** verilmeli; aksi hâlde yazıya yapışık çerçeve çıkar.
5. Bizim kuralımız ezilmiyorsa özgüllük ekle: `html body …:not(#_)` deseni bunun için.
6. Sınıf adına bakmadan renge göre düzeltmek için Tampermonkey scripti var:
   `~/dotfiles/zen/userscripts/obel-remap.user.js` (Google griler, WhatsApp yeşili, ChatGPT mavisi).

## Bilinen kırılgan noktalar (ilk bakılacak yerler)

- Google: `.RNNXgb` (arama kutusu), `.b3puKe` (Hakkında satırı), `.KFFQ0c/.akqY6`, `.Fgyi2e/.ym1pid`
  (ayraçlar), `.PpHF4/.LGKDTe` (AI menü popup/tooltip), `#hdtb-sc` içi, `.w8qArf`.
- WhatsApp: tamamen `x…` sınıflı; tüm kurallar `data-testid` / `aria-label` / `data-icon`'a dayanıyor.
  "You:" / "Siz:" etiketi dil değişirse giden balon kuralı kırılır.
- ChatGPT: CSS-module sınıfları (`LeftPanel-e8ghK3` gibi son eki değişir) → `[class*="LeftPanel"]` ile tutuldu.
- YouTube: eski `yt-spec-button-shape-next--tonal` ↔ yeni `ytSpecButtonShapeNextTonal` ikisi de yazıldı.
