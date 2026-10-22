# 0.4.0 doğrulama — 22 Ekim 2026

Önceki kurulu sürüm kullanıcı tarafından çalışır olarak bildirildi. 0.3 yüklenmedi; bu paket tüm güncellemeleri içerir.

Windows kontrolleri geçti: 11 uygulama ve 2 test Swift dosyasında tree-sitter sözdizimi ayrıştırması; Xcode proje referansları ve derleme aşaması üyelikleri; Info.plist; iki workflow YAML dosyası. Jenerik MP3 kaynakla SHA-256 bazında aynı; mutagen ile süre 5,407 s ve örnekleme hızı 22050 Hz okundu. Bu MP3'te 11025 Hz üstü içerik bulunamayacağından üst frekans çubuklarının sessiz olması normaldir.

Bağımsız NumPy referansı ile 22050, 44100 ve 48000 Hz örnekleme hızlarında desteklenen tüm EQ merkez frekanslarının doğru spektrum bandına düştüğü kontrol edildi. Bu kontrol Swift/Accelerate çalıştırılması değildir.

macOS testleri genişletildi: 10 bant eşlemesi, genlik, ters faz stereo, sessizlik/DC, ring tamponu, tepe beklemesi/yavaş düşüş, zaman biçimi, eski playlist JSON uyumluluğu, süre kalıcılığı ve verilen MP3'ün AVAudioFile ile okunması. Mevcut EQ regresyon testleri korunur. Bunlar GitHub'da çalışacak; burada çalıştırılmadı.

Bekleyen: gerçek Xcode tip denetimi/derleme, macOS test sonuçları, iPhone'da ilk açılış ses davranışı, görsel/dokunma ve liste görünümü. ASAMA-1.md listesini izleyin.

## 0.4.1 simge eklemesi
Açık ve koyu PNG/JSON yapısı, Xcode simge ayarı ve statik önizleme kontrol edildi. Xcode derlemesi ve cihaz kontrolü bekliyor. APP-ICON.md ayrıntıları içerir.

## 0.5.0
13 uygulama Swift dosyası ve 3 test dosyası ayrıştırıldı. Xcode referansları, tüm Swift kaynaklarının build phase üyeliği, plist/YAML ve LF betikleri kontrol edildi. 18 profil kaynağın ham dizileriyle birebir karşılaştırıldı. Bağımsız yerleşim hesapları küçük ekranlar ve iPhone 13 için kontrol edildi. Xcode, UIKit, ses testleri ve yeni kilit ekranı kapağı telefonda henüz çalıştırılmadı. GUNCELLEME-0.5.md son kontrol listesidir.

## 0.6.0
GUNCELLEME-0.6.md güncel doğrulama ve cihaz kontrol listesidir. Yerel sözdizimi ve bağımsız sayısal referans kontrolleri geçti; Xcode testleri henüz çalıştırılmadı.
