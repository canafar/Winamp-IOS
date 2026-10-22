# Winamp 0.5.0 — Tam ekran, EQ profilleri, denge ve kilit ekranı

## Uygulanan istekler

- Onaylanan ilk taslak temel alındı. Saat/pil alanı korunur, Winamp başlığı güvenli alanın hemen altına gelir. Önceki ortalama ve 10 puan kenar payları kaldırıldı. iPhone 13'te ekran genişliği doldurulur. Çentik çevresi ve alt home-indicator bölgesinde kesintisiz koyu zemin bulunur; hiçbir düğme fiziksel çentiğin altına taşınmaz.
- Ana panel ve EQ oranları korunur; boş alanı playlist kaplar. Liste başlığı ve alt düğmeler esnetilmez, yalnızca orta liste alanı uzar. EQ kapandığında playlist yukarıdan büyür; açıldığında tekrar yerleşir.
- Kaynak main.cpp/CreateEQPresets içindeki 18 profil gerçek değerleriyle eklendi. In.cpp/VALTODB dönüşümü kullanıldı. Bass/Vocal eski iOS özel profilleri olarak ayrıca kalır. Ayrıntılar EQ-PRESETS.md.
- Denge göstergesi şarkı başlığının altında sürekli görünür: BAL L50% R50%. Bunlar denge konumunun yüzdeleridir, ölçülen kanal ses güçleri değildir. 49–51 aralığında merkez 50'ye oturur; aralığın dışına çıkınca serbest kalır. Dengeye çift dokunma merkezi geri getirir.
- Kilit ekranındaki Now Playing kapağına klasik Winamp ana paneli eklendi. Bu statik bir kapak görselidir; üzerindeki Winamp düğmeleri etkileşimli değildir ve animasyonlu spektrum içermez. Gerçek oynat/duraklat, ileri/geri ve süre iOS'un sistem denetimlerindedir. Tam kilit ekranını özel Winamp penceresiyle değiştirme veya Live Activity bu pakette yoktur. Sistemin kapağı ne büyüklükte göstereceğine iOS karar verir.

## Korunanlar

Winamp adı, açık/koyu şimşek simgesi, tek seferlik açılış jeneriği, mevcut playlist ve süreleri, 10 çubuk/çizgi spektrum, düşen tepeler, geçen/kalan süre ve çalışan ses motoru korunur. Uygulamayı silmeyin; aynı Apple hesabı ve uygulama kimliğiyle güncelleyin.

## Yükleme

1. ZIP'i çıkarın. WinampClassicIOS klasörünün içindekileri mevcut özel GitHub deponuzun köküne yükleyin; yeni depo açmayın.
2. .github/workflows içindeki iki workflow'u da güncelleyin. Yeni interface testi eklenmiştir. Testleri ve LF satır sonu düzeltmesini atlamayın.
3. Actions → Build unsigned iPhone IPA → Run workflow ile yeni çalıştırma başlatın. Eski çalıştırmayı tekrar çalıştırmak eski kodu kullanır.
4. Yeşil sonuçta WinampClassic-unsigned-IPA artifact'ını indirip IPA'yı çıkarın. Daha önce çalışan iLoader ile aynı Apple hesabını kullanarak yükleyin.

## Telefon kontrolü

- Yan boşluk yok; Winamp başlığı çentik/saat alanının hemen altında ve okunur.
- Playlist alt düğmeleri home-indicator alanının üstünde ve dokunulabilir.
- EQ/PL aç-kapat, liste kaydırma/silme ve müzik ekleme çalışır.
- PRESETS altında 18 kaynak profil + 2 iOS özel profil görünür; Flat sıfır, Rock yeni kaynak eğrisi verir.
- Dengeyi iki yönden ortaya sürükleyin: 49–51 aralığı 50'de durur, ötesinde çözülür; L/R yüzdeleri yönle uyumludur.
- Telefonu kilitleyin: Winamp kapak görseli ve sistem müzik denetimleri görünür; duraklat, devam, sonraki ve süre çalışır.
- Jenerik ikinci kez otomatik başlamaz, eski şarkılar ve kayıtlı EQ ayarları korunur.

## Doğrulama

Windows üzerinde Swift sözdizimi, Xcode kaynak/varlık referansları, plist, workflow YAML, shell LF satır sonları, kaynak profil karşılaştırması ve bağımsız yerleşim hesapları kontrol edildi. 13 uygulama Swift ve 3 test dosyası ayrıştırıldı. Gerçek Xcode derlemesi ve cihaz testi burada yapılmadı.

GitHub workflow'u mevcut EQ/spektrum testlerine ek olarak InterfaceLogicTests çalıştırır: iPhone 13 ölçüleri, küçük ekranlarda taşma, alt düğme konumları, EQ aç/kapat geometrisi, denge kilidi, 18 profil ve kazanç dönüşümü. Başarılı test sonucu gerçek UIKit görünüm/dokunma testinin yerine geçmez.

Apple Now Playing: https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfocenter
Apple artwork: https://developer.apple.com/documentation/mediaplayer/mpmediaitemartwork
