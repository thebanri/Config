##  KDE Konfig Kurulum Rehberi

## Otomatik

Bu kodu çalıştırın:

`cd Config && chmod +x install.sh && ./install.sh`

Script eksik bağımlılıkları (Kvantum, Sierra Breeze Enhanced, Panel Colorizer, UFW) tek seferde kurar, NVIDIA saat ayarını systemd servisi olarak yükler, sudo şifresini en başta bir kez sorar ve üzerine yazdığı ayarları `~/.config_backup_<tarih>` klasörüne yedekler.

| Komut | Ne yapar |
|---|---|
| `./install.sh` | Tema + UFW + NVIDIA saat ayarı |
| `./install.sh --apps` | `install_apps.sh`'taki uygulamaları da aynı seferde kurar |
| `./install.sh --only ufw` | Sadece seçilen adımlar (`deps kwin colors kvantum decoration panel ufw nvidia`) |
| `./install.sh --skip panel` | Seçilen adımları atlar |
| `./install.sh --no-restart` | Sonda KWin/Plasma'yı yeniden yüklemez |

### UFW

`UFW/rules.conf` içindeki portlar açılır (KDE Connect `1714-1764`, LocalSend `53317`, TCP+UDP). UFW kapalıysa `deny incoming / allow outgoing` ile etkinleştirilir. Yeni port eklemek için dosyaya satır ekleyip `./install.sh --only ufw` çalıştırın.

### NVIDIA

`NVIDIA/nvidia-clocks.service`, `/etc/systemd/system/` altına kurulur ve `nvidia-persistenced` ile birlikte açılışta otomatik çalışır:

- Persistence mode açık (`nvidia-smi -pm 1`)
- Çekirdek saati 600–2100 MHz (`-lgc 600,2100`)
- Bellek saati en az 810 MHz (`-lmc 810,7501`), böylece kart boşta P5'in altına inmez

Değerler **RTX 3060** içindir; script başka kartta bu adımı atlar. Değerleri değiştirmek için servis dosyasını düzenleyip `./install.sh --only nvidia` çalıştırın. Kaldırmak için: `sudo systemctl disable --now nvidia-clocks`.


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

