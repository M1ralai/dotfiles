# Invisible Workspace

**AI when you need it. Nothing when you don't.**

Invisible Workspace, **Neovim + tmux** üzerinde çalışan, kalıcı panel ve dashboard kullanmayan, gerektiğinde **Codex CLI** ile kod hakkında soru sormanı ve değişiklik önerilerini incelemeni sağlayan minimal bir geliştirme ortamıdır. **Ghostty ve macOS wallpaper entegrasyonu isteğe bağlıdır.**

**[Kurulum](#kurulum) · [Günlük kullanım](#günlük-kullanım) · [AI ile çalışma](#ai-ile-çalışma) · [Tam kullanım kitabı — KEYMAPS.md](KEYMAPS.md) · [Ghostty ve wallpaper](ghostty/README.md)**

> Ekran görüntüleri henüz eklenmedi. Bu README, kurulumu ve sistemi kullanmaya başlamayı görseller olmadan anlatır.

## Ne sunuyor?

- **Görünmez arayüz:** Kalıcı statusline, tabline, AI paneli veya dashboard yok. Dosya seçici, terminal penceresi ve diff yalnızca gerektiğinde açılır.
- **Tam teşekküllü editör:** Native Neovim API'leri, `vim.pack`, Tree-sitter, Blink completion, LSP, formatters, mini.nvim ve Gitsigns.
- **Kalıcı terminal agent'ları:** tmux popup'ında Codex'i aç, gizle, kod yazmaya devam et ve aynı çalışan oturuma geri dön.
- **Visual Mode üzerinden AI:** Bir kod bölümünü seç, soru sor veya salt okunur bir değişiklik önerisi iste.
- **Kontrollü düzenleme:** Öneri önce diff olarak gösterilir. **Yalnızca sen `Accept` dediğinde Neovim buffer'ı değişir.** Otomatik kaydetme veya kod çalıştırma yok.

## Gereksinimler

| Bileşen | Gereklilik |
|---|---|
| Neovim | **0.12+** (`vim.pack` ve native API'ler için); geliştirilen yapılandırma 0.12.5 üzerinde doğrulandı |
| tmux | **3.5a** üzerinde doğrulandı; popup destekleyen bir sürüm gerekli |
| Git + internet | İlk açılışta Neovim paketlerini kurmak için |
| `rg` (ripgrep) | Dosya/içerik aramaları için |
| C derleyicisi ve uygun `tree-sitter` CLI | Tree-sitter parser'ları için |
| `codex` CLI | Codex popup, soru-cevap ve edit önerileri için (opsiyonel) |
| `agy` CLI | Antigravity terminal popup'ı için, desteklenen CLI doğrulanabiliyorsa (opsiyonel) |
| Ghostty / macOS | Yalnızca opsiyonel terminal görünümü ve wallpaper eşitleyici için |

Dile göre ayrıca ilgili araçları kurmalısın:

| Dil | Language server | Formatter |
|---|---|---|
| Go | `gopls` | `gofmt` |
| C / C++ | `clangd` | `clang-format` |
| Rust | `rust-analyzer` | `rustfmt` |
| Lua | `lua-language-server` | `stylua` |

Eksik language server'lar kendiliğinden yüklenmez. `lazygit`, `direnv` ve kişisel Zsh temaları gibi araçlar da isteğe bağlıdır.

## Kurulum

### 1. Repoyu klonla

```sh
git clone https://github.com/M1ralai/dotfiles.git
cd dotfiles
```

### 2. Neovim ve tmux'u kur

```sh
chmod +x install.sh
./install.sh
```

Installer şu dosyaları kurar:

```text
repo/nvim/            → ~/.config/nvim-invisible/
repo/tmux/tmux.conf   → ~/.tmux.conf
repo/tmux/agent-popup → ~/.config/tmux/agent-popup
```

- Var olan **`~/.config/nvim` yapılandırmasına dokunmaz**: Invisible Workspace ayrı `nvim-invisible` profili olarak kurulur.
- Hedefte daha önce `nvim-invisible`, `.tmux.conf` veya `agent-popup` varsa önce `~/.local/share/dotfiles-backups/invisible-workspace-.../` altına taşır. **Mevcut tmux ayarlarını değiştirir;** kullanıyorsan bu yedeği koru.
- Terminali, Ghostty ayarlarını, Zsh dosyalarını, AI CLI'larını, sistem bağımlılıklarını veya wallpaper servislerini kurmaz; bunlar ayrı tercihlerdir.
- Repo kaynak dosyalarını değiştirmez; etkin yapılandırmaya kopya alır. Sonraki `git pull` çalışan konfigürasyonunu otomatik güncellemez.

Bir tmux oturumu açıp editörü başlat:

```sh
tmux new -s dev
NVIM_APPNAME=nvim-invisible nvim .
```

Zaten çalışan tmux sunucusuna yeni ayarları yüklemek istersen:

```sh
tmux source-file ~/.tmux.conf
```

**Not:** tmux popup kısayolları yalnızca tmux içinden çalışır; Neovim'i tek başına açmak `Ctrl-Space A` kısayolunu etkinleştirmez.

### 3. Tree-sitter parser'ları

Pluginler `vim.pack` ile Neovim'in ilk açılışında kurulur. Dil parser'ları otomatik indirilmez. Neovim içerisinde:

```vim
:TSInstall bash c cpp go json lua markdown markdown_inline rust toml yaml
```

Güncelleme isteğe bağlı ve açıkça başlatılır:

```vim
:lua vim.pack.update()
:TSUpdate
```

## Günlük kullanım

| Kısayol | Ne yapar? |
|---|---|
| `Space Space` veya `Space ff` | Dosya bul |
| `Space /` veya `Space sg` | Projede metin ara |
| `Space e` | Geçici dosya gezginini aç/kapat |
| `Space fb` | Açık buffer'ları gör |
| `gd` / `gr` | Tanıma git / referansları bul |
| `K` | LSP hover bilgisi |
| `Space ca` / `Space cr` | Code action / rename |
| `Space cf` | Elle formatla |
| `Space gg` | Lazygit aç (kuruluysa) |

**Vim'i bilmiyor musun?** Modlar, hareketler, text object'ler, `mini.surround`, register'lar, makrolar, completion, Git ve tüm özel kısayollar örnekleriyle **[KEYMAPS.md](KEYMAPS.md)** içinde anlatılıyor.

## AI ile çalışma

AI sisteminin iki ayrı kullanım biçimi vardır; aynı konuşma oturumunu paylaşmaları beklenmez.

### 1. Kalıcı Codex popup'ı (tmux)

| Kısayol | İşlem |
|---|---|
| `Ctrl-Space`, sonra `A` | Codex popup'ını göster; aynı oturum açıksa yeniden bağlan |
| `Ctrl-Space`, sonra `H` | Popup'ı **gizle**; agent çalışmaya devam eder |
| `Ctrl-Space`, sonra `X`, sonra `y` | Agent oturumunu **tamamen kapat** |
| `Ctrl-Space`, sonra `G` | Uygun Antigravity CLI varsa popup aç |

`Ctrl-Space`, tmux prefix'idir; kombinasyonlarda tuşları **sırayla** basarsın. Agent oturumları açıldıkları tmux oturumuna ve proje dizinine göre ayrılır. Hide konuşmayı korur, Close süreci bitirir. Yeniden başlatılan tmux sunucusunda aynı çalışan süreç korunmaz.

**Antigravity notu:** `agy` kurulmuş olsa bile launcher ilgili terminal yeteneklerini doğrular. Visual Mode üzerinden Antigravity Q&A, güvenilir read-only yürütme doğrulanana kadar kapalıdır.

### 2. Seçili kod üzerinden soru sor

1. Neovim'de `v` veya `V` ile kodu seç.
2. **`Space a c`** ile Codex'e soru gönder.
3. Açılan küçük pencerede sorununu yaz ve `Enter` ile gönder (`Esc` iptal eder).
4. Yanıtı oku; `q` ile gizle, **`:AIShow`** ile geri aç, `Q` ile sil.

Bu işlem kaynak buffer'ı değiştirmez. Codex salt okunur, ayrı ve geçici bir CLI çalışması kullanır; tmux'taki interaktif konuşmayı devam ettirmez.

### 3. AI'dan değişiklik önerisi al ve incele

1. `v` / `V` ile değiştirmek istediğin kodu seç.
2. **`Space a e`** ile Codex'ten bir değişiklik iste.
3. Codex yalnızca önerilen metni üretir. Neovim, orijinal kodla arasında diff gösterir.
4. Diff içinde **`a` = Accept**, **`r` = Reject**, **`q` = Hide**.
5. Gizlediğin öneriyi **`:AIProposalShow`** ile yeniden açabilir veya **`:AIProposalDiscard`** ile silebilirsin.

Accept, yalnızca seçili aralığı kaynak buffer'da değiştirir; **dosyayı diske kaydetmez**. Kaydetmek istersen ayrıca `:w` kullan. `u` ile geri alabilirsin. Kaynak buffer sen beklerken değişirse, silinirse veya unload edilirse eski öneri otomatik uygulanmaz. Blockwise seçimle düzenleme desteklenmez.

> **AI edits nothing without my approval.** İnteraktif tmux agent'ları ve Visual Mode read-only edit önerileri ayrı işlemlerdir; Neovim'in Accept/Reject güvencesi tmux içindeki serbest sohbetin bütün eylemlerini yönetmez.

Tüm komutlar, viewer yaşam döngüleri, kısıtlamalar ve örnekler: **[KEYMAPS.md — AI-powered development](KEYMAPS.md#11-ai-powered-development-questions-changes-and-code-review)**.

## Ghostty ve macOS wallpaper (opsiyonel)

Neovim ve tmux, Ghostty olmadan da kullanılabilir. macOS'ta Ghostty için Rose Pine temaları, terminal içi arka plan görseli, wallpaper eşitleyici ve deneysel cursor shader kodu `ghostty/` altında bulunur.

**[Ghostty kurulumu ve wallpaper rehberi](ghostty/README.md)** üzerinden ilerle. Bu bölüm macOS AppKit, Swift ve `launchd` gerektirir.

**Önemli:** `ghostty/config` örneğinde `/Users/REPLACE_ME/...` yer tutucuları vardır. Dosyayı aktif Ghostty yapılandırmasına kopyalamadan önce gerçek kullanıcı dizinine uygun hâle getir; aksi hâlde görsel/include yolları çalışmayabilir. Repo özel wallpaper resmini içermez. Wallpaper helper'ı istersen sistem duvar kâğıdını takip edebilir; terminal penceresi gerçekte yarı saydam olmaz.

## Depo düzeni

```text
.
├── README.md                     # Tanıtım ve kurulum
├── KEYMAPS.md                   # Tam Neovim, tmux ve AI kullanım kitabı
├── install.sh                   # Neovim profili + tmux kurucusu
├── nvim/                        # Lua ayarları, AI modülü, plugin lockfile
├── tmux/                        # tmux.conf + agent-popup
├── ghostty/                     # İsteğe bağlı Ghostty ve wallpaper kaynakları
└── zsh/                         # Kişisel Zsh örnekleri (installer dokunmaz)
```

## Sorun giderme

- **`Ctrl-Space A` çalışmıyor:** tmux içinde misin? `~/.config/tmux/agent-popup` var mı? `command -v codex` çalışıyor mu? Terminal/OS kısayolu engelliyor olabilir.
- **`Space a g` hata veriyor:** Antigravity Visual Q&A henüz etkin değil; Codex için `Space a c` kullan.
- **Completion/LSP yok:** İlgili language server'ın PATH'te olduğundan emin ol. `:checkhealth` ile Neovim durumunu incele.
- **AI önerisi stale:** Kaynak kod veya buffer yaşam döngüsü değişmiştir. Güncel kodu seçip yeni öneri iste.
- **Wallpaper görünmüyor:** Önce [Ghostty rehberini](ghostty/README.md), yol yer tutucularını ve `sync-wallpaper status` çıktısını kontrol et.

## Geri alma

Installer, değiştirilen her hedefin eski hâlini kurulum sonunda yazdığı yedek dizine taşır. Geri almak için Neovim ve tmux istemcilerini kapatmadan önce yedek yolunu not et, ilgili aktif dosyaları başka bir yere taşı ve yedekteki dosyaları özgün konumlarına geri koy. **`~/.config/nvim` hiç değiştirilmez.** tmux sunucusu zaten çalışıyorsa `tmux source-file ~/.tmux.conf` ile geri yüklediğin ayarları yeniden uygula.

## Yaklaşım

Minimalizm, yetenekten vazgeçmek değil; arayüzü yalnızca gerektiğinde göstermek.

**AI edits nothing without my approval.**
