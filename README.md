##  KDE Konfig Kurulum Rehberi

## Otomatik

Bu kodu çalıştırın:

`cd Config`
`chmod +x install.sh`
`./install.sh`


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

