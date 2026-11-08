# Opsiyonel Ghostty + macOS wallpaper eşitlemesi

**Bu wallpaper entegrasyonu macOS'a özeldir.** AppKit, Core Image, Apple Events ve launchd kullanır; Linux/Windows üzerinde çalışmaz. Kaynak Swift kodu dahildir; program yerel makinede derlenir. Ghostty'nin `/Applications/Ghostty.app` konumunda kurulu olması gerekir. Neovim/tmux bu bileşen olmadan da çalışır.

## Wallpaper seçici nasıl çalışıyor?

Ayrı bir görsel seçici/popup yoktur. İki kullanım şekli vardır:

1. `source = ""` (varsayılan): macOS Sistem Ayarları → Duvar Kâğıdı üzerinden seçtiğin görseli takip eder. Görünür Ghostty penceresinin en çok bulunduğu ekranı seçer; pencere bilgisi bulunamazsa ana ekranı kullanır. macOS'un `NSWorkspace.desktopImageURL` API'si ile o ekranın wallpaper dosyasını okur.
2. `source = "/tam/yol/resim.jpg"`: Ghostty için sabit bir görsel kullanır; macOS masaüstü duvar kâğıdını değiştirmez.

Görsel ekran oranına göre cover olarak kırpılır, blur/dimming/saturation uygulanır ve `~/Library/Caches/invisible-workspace/processed/` altında PNG olarak saklanır. Ghostty bu resmi **opak terminal penceresinin içinde** çizer (`background-opacity = 1`). Bu, arkadaki masaüstünü gösteren gerçek pencere şeffaflığı değildir.

LaunchAgent etkinleştirilirse girişte ve her **60 saniyede** kontrol eder. Görsel/dosya zamanı/işleme ayarları değişmediyse cache kullanılır; sürekli render yapan bir watcher yoktur. Kaynak görsel değiştirilmez. İşlem kilidi, atomik yazma, Ghostty config doğrulaması ve son çalışan çıktıyı koruma mekanizmaları mevcut Swift kodunda korunmuştur.

## Kurulum

Repo kökünden, macOS üzerinde çalıştır. Swift derlemek için Xcode Command Line Tools gerekir (`xcode-select -p` ile kontrol edebilirsin; eksikse `xcode-select --install`). Aşağıdaki işlemler mevcut ayarları yedekler. Bu komutları tekrar çalıştırmak wallpaper ayarlarını repo varsayılanlarına döndürür.

```sh
backup="$HOME/.local/share/dotfiles-backups/ghostty-$(date +%Y%m%d-%H%M%S)"
root="$HOME/.config/invisible-workspace"
plist="$HOME/Library/LaunchAgents/com.invisible-workspace.wallpaper.plist"
mkdir -p "$backup" "$HOME/.config" "$HOME/Library/LaunchAgents"
# Önceden kurulu kendi eşitleyicimizi durdur; Ghostty/tmux oturumları açık kalır.
launchctl bootout "gui/$(id -u)/com.invisible-workspace.wallpaper" 2>/dev/null || true
for name in ghostty invisible-workspace; do
  if [ -e "$HOME/.config/$name" ] || [ -L "$HOME/.config/$name" ]; then
    mv "$HOME/.config/$name" "$backup/$name"
  fi
done
if [ -f "$plist" ]; then mv "$plist" "$backup/wallpaper.plist"; fi
mkdir -p "$HOME/.config/ghostty"
cp ghostty/config "$HOME/.config/ghostty/config"
cp -R ghostty/invisible-workspace "$root"
mkdir -p "$root/scripts" "$HOME/Library/Caches/invisible-workspace"
xcrun swiftc -O "$root/src/Wallpaper.swift" -o "$root/scripts/sync-wallpaper"
"$root/scripts/sync-wallpaper" refresh
printf 'Yedek: %s\n' "$backup"
```

`refresh` başarılıysa wallpaper overlay üretilir. Ghostty config'in sonundaki opsiyonel include onu yükler; çıktı henüz yoksa Ghostty düz arka planla açılabilir. Hata olursa aşağıdaki otomatik çalışma adımından önce hata mesajını çöz.

Otomatik 60 saniyelik kontrol istersen, aynı shell'de:

```sh
plutil -create xml1 "$plist"
plutil -insert Label -string com.invisible-workspace.wallpaper "$plist"
plutil -insert ProgramArguments -json "[]" "$plist"
plutil -insert ProgramArguments.0 -string "$root/scripts/sync-wallpaper" "$plist"
plutil -insert ProgramArguments.1 -string refresh "$plist"
plutil -insert RunAtLoad -bool YES "$plist"
plutil -insert StartInterval -integer 60 "$plist"
plutil -insert LimitLoadToSessionType -string Aqua "$plist"
plutil -insert ProcessType -string Background "$plist"
plutil -insert LowPriorityIO -bool YES "$plist"
plutil -insert Nice -integer 10 "$plist"
plutil -insert StandardErrorPath -string "$HOME/Library/Caches/invisible-workspace/sync-error.log" "$plist"
launchctl bootstrap "gui/$(id -u)" "$plist"
```

## Kullanım

```sh
sync="$HOME/.config/invisible-workspace/scripts/sync-wallpaper"
"$sync" inspect                       # Ekran, seçilen ekran ve wallpaper yolu
"$sync" status                        # Son başarılı işlemin bilgileri
"$sync" refresh                       # Hemen kontrol et/üret
"$sync" set source "/tam/yol/resim.jpg" # Ghostty için sabit görsel
"$sync" set source ""                 # macOS wallpaper'ını tekrar takip et
"$sync" set blur 6
"$sync" set dimming 0.70
"$sync" set saturation 0.85
"$sync" set opacity 0.80
"$sync" reload                        # Mümkünse Ghostty config'i yeniden yükle
```

Diğer ayarlar: `brightness` (-0.5…0.5), `max_dimension` (640…4096). `config.toml` düz scalar ayar dosyasıdır; genel amaçlı TOML parser değildir. `set` komutu geçerli çıktıyı üretip doğruladıktan sonra ayarları kaydeder.

Ghostty'ye Automation izni **zaten verilmişse** otomatik `reload_config` denenir. İzin yoksa yeni izin istemez; Ghostty'de **Cmd + Shift + virgül** ile manuel yenile. Cache değişmediğinde `refresh` tekrar reload denemez; bu durumda manuel kısayolu veya `reload` komutunu kullan.

Opsiyonel shader: `"$sync" set cursor on`; kapatmak için `"$sync" set cursor off`. Varsayılan **off**; Ghostty shader animasyonu odaklı pencerede sürekli render çalıştırabilir. Neovim'in kendi mini.animate cursor/scroll animasyonu bundan bağımsız olarak açıktır.

## Sınırlar

- JPG/PNG/HEIC/HEIF/TIFF/BMP desteklenir. Video/Aerial wallpaper desteklenmez; dinamik/çok kareli resimde statik çözülen kare kullanılır, günün saatine göre görünüm garanti edilmez.
- Tüm Ghostty pencereleri tek üretilen config'i kullanır; farklı monitörlere eşzamanlı ayrı wallpaper atanmaz. Ekran/Space değişikliklerinin tespiti macOS'un public API'sinin döndürdüğü bilgiyle sınırlıdır.
- Eşitleme gecikmesi 60 saniyeye kadar olabilir; `refresh` hemen çalıştırır. Başarısız kaynak okumasında mevcut çıktı korunur.
- tmux/Neovim arka plan renkleri default/NONE olarak ayarlıdır. Uygulama açık hücre arka planı boyarsa wallpaper o alanda örtülebilir; her uygulama/popup için bağımsız per-pixel şeffaflık garantisi yoktur.
- Repo aktarımı, baştan sona yeni bir ekran görüntüsü/piksel doğrulaması değildir; farklı Ghostty sürümlerindeki görünüm ayrıca kontrol edilmelidir.

## Geri alma

Kurulumun yazdırdığı yedek yolunu kullan:

```sh
backup="/kurulumda/yazdirilan/ghostty-yedek/yolu"
plist="$HOME/Library/LaunchAgents/com.invisible-workspace.wallpaper.plist"
launchctl bootout "gui/$(id -u)/com.invisible-workspace.wallpaper" 2>/dev/null || true
[ ! -f "$plist" ] || mv "$plist" "$backup/wallpaper-export.plist"
for name in ghostty invisible-workspace; do
  mv "$HOME/.config/$name" "$backup/$name-export"
  if [ -e "$backup/$name" ] || [ -L "$backup/$name" ]; then
    mv "$backup/$name" "$HOME/.config/$name"
  fi
done
if [ -f "$backup/wallpaper.plist" ]; then
  mv "$backup/wallpaper.plist" "$plist"
  launchctl bootstrap "gui/$(id -u)" "$plist"
fi
```

Ghostty'yi Cmd + Shift + virgül ile yenile; gerekirse yeni bir Ghostty penceresi aç. Masaüstünün wallpaper'ı hiçbir aşamada değiştirilmez. Cache silinmesi zorunlu değildir.
