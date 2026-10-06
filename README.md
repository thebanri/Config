##  KDE Konfig Kurulum Rehberi

## Otomatik

Bu kodu çalıştırın:

`cd Config && chmod +x install.sh && ./install.sh`

Script eksik bağımlılıkları (Kvantum, Sierra Breeze Enhanced, Panel Colorizer, UFW, xdg-terminal-exec) tek seferde kurar, NVIDIA saat ayarını systemd servisi olarak yükler, sudo şifresini en başta bir kez sorar ve üzerine yazdığı ayarları `~/.config_backup_<tarih>` klasörüne yedekler.

| Komut | Ne yapar |
|---|---|
| `./install.sh` | Tema + dotfile'lar + scripts + UFW + NVIDIA saat ayarı + varsayılan terminal |
| `./install.sh --apps` | `install_apps.sh`'taki uygulamaları da aynı seferde kurar |
| `./install.sh --only ufw` | Sadece seçilen adımlar (`deps kwin colors kvantum decoration panel dotfiles scripts ufw nvidia terminal`) |
| `./install.sh --skip panel` | Seçilen adımları atlar |
| `./install.sh --no-restart` | Sonda KWin/Plasma'yı yeniden yüklemez |

### Dotfile'lar

`Dotfiles/` klasörü `$HOME`'un aynısıdır: `Dotfiles/.config/alacritty/alacritty.toml` → `~/.config/alacritty/alacritty.toml`. Sadece farklı olan dosyalar kopyalanır, eskileri `~/.config_backup_<tarih>/home/` altına aynı yolla yedeklenir.

| Dosya | Ne |
|---|---|
| `alacritty/` | Terminal ayarı + temalar (Tokyo Night Storm) |
| `kitty/kitty.conf` | kitty ayarı |
| `micro/` | Editör ayarı + Catppuccin renk şemaları |
| `fish/` | `config.fish`, Go/zoxide ayarı (`conf.d/dev-tools.fish`), `plasma-reset` fonksiyonu |
| `btop/`, `fastfetch/` | Sistem izleme ve açılış logosu |
| `fontconfig/fonts.conf` | Font yumuşatma / hinting |
| `zed/settings.json` | Zed editör ayarı |
| `git/ignore` | Global gitignore |
| `kwinrulesrc` | Pencere kuralı: BetterNotes görev çubuğunda görünmesin |
| `mimeapps.list` | Varsayılan uygulamalar (tarayıcı: Zen, posta: Thunderbird) |
| `autostart/betternotes.desktop` | BetterNotes açılışta başlasın |
| `systemd/user/` + `.local/bin/clocksource-watch` | Saat kaynağı uyarı servisi, NVIDIA renk canlılığı (nvibrant) |

Sistemdeki değişiklikleri repoya almak için `./sync_dotfiles.sh` çalıştırıp `git diff` ile kontrol edin. Yeni bir dosyayı takibe almak için önce `Dotfiles/` altına aynı yolla kopyalayın.

> Repo herkese açık: `gh/hosts.yml`, `.aws/`, tarayıcı profilleri, `kwalletrc`, `kdeconnect/` gibi token/anahtar içeren dosyaları **eklemeyin**.

### Scripts

[thebanri/scripts](https://github.com/thebanri/scripts) reposu `~/scripts`'e klonlanır (zaten varsa `git pull` yapılır). `config.fish` bu klasörü `fish_function_path`'e eklediği için içindeki `last-pkgs`, `cache`, `open`, `win-next` gibi komutlar doğrudan kullanılabilir. Komutların listesi o reponun README'sinde.

### Görev çubuğu önizlemeleri kaybolursa

Önizlemelerde pencere yerine sadece ikon çıkıyorsa terminalde `plasma-reset` çalıştırın (panel birkaç saniye kaybolup geri gelir, açık pencereler etkilenmez).

Nedeni: kpipewire bir görüntüyü GPU'ya aktaramazsa o formatı oturum boyunca listeden çıkarıyor. KWin sadece BGRA/BGRx sunduğu için ortak format kalmıyor (journal'da `no more input formats`). Ayrıntılı log için `~/.config/QtProject/qtlogging.ini` dosyasına şunu ekleyin:

```ini
[Rules]
kpipewire_logging.debug=true
kpipewire_dmabuf_logging.debug=true
```

### UFW

`UFW/rules.conf` içindeki portlar açılır (KDE Connect `1714-1764`, LocalSend `53317`, TCP+UDP). UFW kapalıysa `deny incoming / allow outgoing` ile etkinleştirilir. Yeni port eklemek için dosyaya satır ekleyip `./install.sh --only ufw` çalıştırın.

### NVIDIA

`NVIDIA/nvidia-clocks.service`, `/etc/systemd/system/` altına kurulur ve `nvidia-persistenced` ile birlikte açılışta otomatik çalışır:

- Persistence mode açık (`nvidia-smi -pm 1`)
- Çekirdek saati 600–2100 MHz (`-lgc 600,2100`)
- Bellek saati en az 810 MHz (`-lmc 810,7501`), böylece kart boşta P5'in altına inmez

Değerler **RTX 3060** içindir; script başka kartta bu adımı atlar. Değerleri değiştirmek için servis dosyasını düzenleyip `./install.sh --only nvidia` çalıştırın. Kaldırmak için: `sudo systemctl disable --now nvidia-clocks`.

### Terminal

`Terminal/kde-xdg-terminals.list`, `~/.config/` altına kopyalanır ve `xdg-terminal-exec` kurulur. Varsayılan terminal **Alacritty**.

Neden gerekli: `Terminal=true` olan uygulamalar (ör. cachy-update tray ikonu) terminali GLib üzerinden açar. GLib, KDE'deki varsayılan terminal ayarına bakmaz. Önce `xdg-terminal-exec`'i dener, o yoksa sabit bir listeden seçer (gnome-terminal, konsole, xterm...). Alacritty ve kitty bu listede yok, bu yüzden Konsole silinince bu uygulamalar *"Unable to find terminal required for application"* hatasıyla açılmaz.

Terminali değiştirmek için dosyaya başka bir `.desktop` adı yazıp (ör. `kitty.desktop`) `./install.sh --only terminal` çalıştırın.


## Manual

KDE konfigürasyon kurulum rehberine hoş geldiniz. Burdaki dosyalar bana ait olan KDE masaüstü ortamının özelleştirilme dosyalarıdır. 

###  Kurulum: 

####  1. Adım: 

**Dikkat:** Mevcut ayarlarınızı değiştirmeden önce `~/.config/kwinrc` dosyanızın bir yedeğini almanız önerilir.

`kwinrc` dosyasını `.config` içerisine kopyalıyoruz. Kopyaladıktan sonra `systemctl --user restart plasma-plasmashell.service` bu kodu terminalden çalıştırıyoruz.

> Bu dosyanın içerisindeki şeyler özelleştirilebilir fakat en optimize hali bence bu.

####  2. Adım: 

`Colors` klasöründeki dosyayı `System Settings ---> Colors & Themes ---> Colors` kısmından `Install From File` butonuna tıklayarak bu dosyayı seçin ve sonrasında Gelen "Sweet" rengini seçin ardından Apply diyip bu adımı tamamlayın.

####  3. Adım: 

kvantum kurulumu yaptıktan sonra `Application` klasörü içerisindendeki `tar.xz` dosyasını Extract edip kvantum ile kurduktan sonra burdaki kısımdan seçiyoruz.

####  4. Adım: 

`Colors & Themes ---> PLasma Style` kısmı için `Get New` dedikten sonra `Sweet` temasını indirip onu bu kısımdan seçmeniz gerekiyor.


####  5. Adım:

Öncelikle sisteme `sierra breeze enchanted`  indirdikten sonra `~/.config` dosyası içerisine `Window Decoration` klasöründeki dosyayı kopyalamanız gerekiyor sonrasında `Colors & Themes ---> Window Decoration` kısmındaki yerden `Sierra Breeze`'i seçmelisiniz.


####  6. Adım: 

`Colors & Themes ---> İcons` kısmında `Get New` diyerek istediğiniz İcon'u yükleyin ve Apply diyin.


####  7. Adım: 

`panelcolorizer` indirdikten sonra `~/.config/panel-colorizer/presets/` kısmına bu klasörü kopyalıyoruz ardından panel kısmına widget olarak ekleyip configürasyon kısmından en aşşağıdan Panel_Conf ayarını seçiyoruz.


Kurulum Tamamlandı! İyi kullanımlar.

