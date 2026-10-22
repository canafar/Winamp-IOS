# Winamp Classic — iOS başlangıç projesi

**Mac'iniz yoksa:** Windows'tan GitHub Actions ile ilk derleme için [GITHUB-KURULUM.md](GITHUB-KURULUM.md) dosyasını izleyin. Önceki sürüm kullanıcı tarafından derlenip telefonda çalıştırıldı; bu güncellemenin derlemesi bekliyor.

Bu çalışma, Windows Winamp uygulamasının tamamının iOS portu değildir. Orijinal klasik skin görselleriyle hazırlanan, yerel ses dosyalarını çalmak için iOS kodu içeren **0.5.0 geliştirme sürümüdür**. Windows kaynak kodunun derleme hedefini değiştirerek oluşturulmamıştır; Windows pencere ve ses katmanının yerine UIKit ve AVAudioEngine / AVAudioUnitEQ yazılmıştır.

**Durum:** Önceki sürümün iPhone üzerinde çalıştığı kullanıcı tarafından doğrulandı. Bu 0.5.0 güncellemesinde Windows üzerinde sözdizimi, proje ve YAML kontrolleri geçti; yeni kod için Xcode derlemesi, ses testleri ve cihaz kontrolü henüz yapılmadı. [0.5 güncelleme ve kontrol listesi](GUNCELLEME-0.5.md).

- Kullanıcının sağladığı jenerik MP3 ilk açılışta bir kez çalınır ve listede kalır.
- Liste satırlarının sağında parça süresi gösterilir; eski kayıtların süreleri tamamlanır.

- Orijinal Windows şimşekli açık/koyu uygulama simgesi: [simge notları](APP-ICON.md).

## 0.5.0 güncellemesi

Tam genişlikte ve üstten hizalı düzen; ekranın kalanını dolduran playlist; 18 özgün EQ profili; sağ/sol denge yüzdesi ve 49–51 merkez kilidi; kilit ekranında Winamp kapak görseli. [Ayrıntı ve sınırlar](GUNCELLEME-0.5.md).

## Dosyalar

- `WinampClassic.xcodeproj`: doğrudan Xcode ile açılabilen proje; CocoaPods, SPM veya XcodeGen gerektirmez.
- `WinampClassic/`: UIKit arayüzü ve ses oynatma kaynakları.
- `WinampClassic/Resources/`: orijinal BMP görsellerinin kayıpsız PNG dönüşümleri ve bunlardan oluşturulan panel arka planları.
- `skin-preview.png`: uygulamada kullanılan kaynaklarla oluşturulmuş **statik skin önizlemesi**; cihaz veya simülatör ekran görüntüsü değildir.
- `tools/prepare_project.py`: görsel kompozisyonları ve Xcode projesini yeniden üretir. Yalnız yeniden üretim için Python 3 ve Pillow gerekir.
- `scripts/build-simulator.sh`: Mac üzerinde imzasız simülatör derleme kontrolü.
- `DEVICE-CHECKLIST.md`: henüz yapılmamış gerçek cihaz kontrolleri.
- `UPSTREAM.json` ve `UPSTREAM-LICENSE.md`: kaynak revizyonu, özgün dosya hashleri ve lisans.

## Bu sürümde kodlanan özellikler

- 275 × 116 özgün ana panel, 275 × 116 özgün ekolayzır paneli ve 275 × 232 klasik liste çerçevesi. iPhone ekranının güvenli alanına tam genişlikte ölçeklenir, playlist orta alanı kalan yüksekliğe uyarlanır; özgün skin pikselleri en yakın komşu örneklemesiyle çizilir.
- Eject / ADD üzerinden Dosyalar uygulamasından birden çok ses dosyası seçme.
- Dosyaları uygulamanın Documents/Music dizinine kopyalama ve listeyi JSON olarak saklama.
- Oynat, duraklat/devam, durdur, önceki/sonraki, zaman çubuğundan arama.
- Ses, sol/sağ denge, listeyi karıştırma, listeyi tekrarlama.
- Gerçek ses zincirinde 10 bant parametrik EQ: 70, 180, 320, 600 Hz; 1, 3, 6, 12, 14, 16 kHz. Her bant ±12 dB; bant genişliği 1 oktav.
- ±12 dB preamp; ON kapalıyken hem bantlar hem preamp bypass edilir. Paneli kapatmak EQ'yu kapatmaz.
- AUTO açıkken parçaya özel EQ ayarı saklanır ve parça yeniden seçildiğinde yüklenir. Henüz ayar kaydedilmemiş parça Flat ile açılır.
- Flat, Bass, Vocal ve Rock hazır ayarları; bir sürgüye çift dokunarak 0 dB'ye döndürme. Bunlar bu uygulama için tanımlanan ayarlardır, özgün Winamp preset dosyaları değildir.
- EQ ayarlarını uygulama yeniden açıldığında koruma.
- Parçayı listeden seçme, sola kaydırarak silme; REM geçerli parçayı siler.
- Geçen/kalan süre geçişi, uzun başlıkları kaydırma, EQ frekanslarıyla eşleşen 10 çubuklu spektrum, düşen tepe işaretleri ve dokunarak 10 noktalı çizgi spektruma geçiş.
- Arka planda ses, kilit ekranı kumandaları, ses kesintisi ve kulaklık çıkarılması için işleyiciler.
- Temel VoiceOver etiketleri ve kaydırıcı erişilebilirlik eylemleri.

Bu maddeler kaynak kodun kapsamını anlatır; cihazda testten geçmiş özellik listesi değildir. Dosya biçimi desteğini AVAudioFile belirler; bu sürüm mono/stereo dosyalar içindir; ilk denemeler için DRM içermeyen MP3, AAC/M4A ve WAV kullanın. Apple Music abonelik kataloğuna erişim eklenmedi.

## Windows 11'de yapılabilecekler

Kaynak dosyaları düzenleyebilir ve `skin-preview.png` görselini açabilirsiniz. Bu klasörde Windows'ta çalışan bir EXE veya iPhone'a doğrudan kurulabilen IPA yoktur. Xcode ve Apple iOS SDK'sı Windows üzerinde çalışmaz; sonraki derleme aşaması bir Mac gerektirir.

## Mac'te ilk derleme ve iPhone'a kurulum

1. Bu klasörün tamamını size ait veya erişebildiğiniz bir Mac'e aktarın.
2. Hedef iOS sürümünü destekleyen Xcode'u açın; gereken iOS platform desteğini yükleyin.
3. `WinampClassic.xcodeproj` dosyasını açın. Şema: **WinampClassic**.
4. Önce bir iPhone simülatörü seçip **Product → Build** çalıştırın. Terminal alternatifi:

   ```sh
   bash scripts/build-simulator.sh
   ```

5. Gerçek cihaz için **Target → Signing & Capabilities → Team** alanında kendi Apple hesabınızın takımını seçin. **Bundle Identifier** değerini size özgü bir değerle değiştirin; örneğin `com.adiniz.winampclassic`.
6. iPhone'u Mac'e bağlayın, güven ilişkisini kurun, cihaz isterse Geliştirici Modu'nu etkinleştirin. Xcode'da cihazı seçip Run çalıştırın. İmzalama/provisioning işlemlerini Xcode yönetsin.
7. Uygulamada Eject'e basıp Dosyalar'dan bir müzik dosyası ekleyin; ardından Play'e basın.

Minimum deployment target iOS 16.0'dır; bu, kullanılan API tabanıdır. iOS 27 üzerinde çalıştığı iddiası değildir. iOS 27 desteği, uygun SDK ile derleme ve hedef cihaz testi tamamlandıktan sonra doğrulanabilir.

## Henüz tamamlanmayanlar ve görsel sınırlar

- EQ ses işleme kodu eklendi; Apple ses motoru ile gerçek render testi ve iPhone'da dinleme testi henüz yapılmadı. Özgün Winamp DSP'siyle bit düzeyinde aynı filtre davranışı iddia edilmez.
- Dosyanın Nyquist sınırının üzerindeki bantlar bypass edilir. Pozitif EQ ve preamp kazançları birlikte taşmaya yol açabilir; hazır ayarlarda bunun için negatif preamp kullanılır.
- EQ grafiği sürgü kazançlarını gösterir; ölçülmüş frekans cevabı değildir. Hazır ayar seçicisi iOS menüsüdür.
- Ses çıkışının yeniden yapılandırılmasında oynatma güvenli biçimde duraklar; Play ile devam edilir.
- Windows DLL eklentileri, DSP zinciri, internet radyosu, video ve modern skin motoru taşınmadı.
- SEL, MISC ve LIST OPTS menüleri henüz uygulanmadı; bilgi mesajı gösterirler.
- Masaüstü pencere küçültme, windowshade ve uygulamayı kapatma düğmeleri bu sürümde görseldir.
- Liste satırları Unicode dosya adlarını korumak için iOS metin çizimini kullanır; masaüstü fontuyla birebir piksel eşleşmesi beklenmemelidir. Dosya seçimi, silme hareketi ve uyarılar iOS bileşenleridir.
- Görseldeki sayaç alanı 99:59'a kadar özgün dört basamak düzenini korur; daha uzun kayıtlarda dakika göstergesi 99 ile sınırlıdır.
- Özgün düğme yerleşimi küçük dokunma hedefleri içerir. iPhone'da dokunma rahatlığı cihaz testiyle değerlendirilmeli.
- Dosya içe aktarma bu ilk sürümde ana iş parçacığında çalışır; çok büyük veya buluttan indirilen dosyalarda arayüz geçici olarak bekleyebilir.

## Kaynak ve kullanım kapsamı

Kaynak: https://github.com/manfromafar/winamp

Sabit revizyon: `9c7f91496c56738fd707905f257643b792c05bb9`.

Özgün skin dosyaları ve arayüz koordinatları depodaki `Src/Winamp/resource`, `draw_main.cpp` ve `draw_pe.cpp` dosyalarına dayanır. Winamp ve orijinal görsellerin hakları ilgili hak sahiplerindedir. Bu proje resmi bir Winamp iOS sürümü değildir.

Depodaki lisans kişisel kullanım için değişikliği mümkün kılar; değiştirilmiş sürümlerin dağıtımını kısıtlar. Bu çalışma kişisel yerel geliştirme içindir. App Store/TestFlight yayını, herkese açık depo veya üçüncü kişilere dağıtım hazırlanmadı. Özgün lisans `UPSTREAM-LICENSE.md` dosyasında aynen korunmuştur.

Apple başvuru kaynakları:

- https://developer.apple.com/documentation/avfaudio/avaudiouniteq
- https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller/init(foropeningcontenttypes:ascopy:)
- https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/playback
- https://help.apple.com/xcode/mac/current/en.lproj/dev5a825a1ca.html

## EQ ses testi (Mac)

```sh
bash scripts/test-eq.sh
```

Bu test, uygulamanın kullandığı `EqualizerDSP.configure` fonksiyonunu Apple'ın offline ses motorunda çalıştırır. 70 Hz, 1 kHz ve 16 kHz tonlarında +6 dB bant kazancını; ON kapalıyken bypass'ı; −6 dB preamp'ı ve düşük örnekleme hızlarında bant bypass'ını sınar. Hoparlörden ses vermez. Aynı komut `EnginePlayer.swift` dosyasını da Mac SDK'sıyla derler. Test kaynakları eklendi ancak Windows ortamında **çalıştırılmadı**; iOS derleme ve cihaz testinin yerini almaz.
