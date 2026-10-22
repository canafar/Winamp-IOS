# Winamp 0.6.0 — kaynak davranışına göre güncelleme

- EQ 10 banttır. Spektrum kaynak kodundaki gibi 19 çubuktur: 75 giriş sütunu, dörderli ortalama, 3 piksel çubuk + 1 piksel boşluk. Son grubun eksik sütunu kaynak gibi sıfırdır.
- classic_vis.cpp/SABuffer.cpp: 512 örnek Hann FFT, stereo kanalların toplamı, kaynak frekans eğrisi ve Hermite entegrasyonu kullanılır. Önceki EQ frekanslarına bağlı 10 bölgeli dB görselleştirmesi kaldırıldı. Ters fazdaki stereo sinyal kaynakta olduğu gibi görselde birbirini söndürebilir; ses çıkışı değişmez.
- draw_sa.cpp/config.h: varsayılan çubuk düşüşü her 16 ms adımda 12/16 piksel, tepe başlangıç hızı 3/256 piksel ve adım başına 1.1 çarpanıdır. Önceki sabit 250 ms bekleme ve doğrusal tepe düşüşü kaldırıldı.
- SA.cpp dinamiği 16 ms adımlıdır; kaynak varsayılanı iki adımda bir çizer. İstenen akıcılık için iOS çizimi CADisplayLink ile 60 FPS hedefler; hareket hızı ekran FPS'inden bağımsızdır. Gerçek FPS cihaz güç/ısınma durumuna bağlıdır.
- Dokununca kaynak çizgi osiloskobuna geçer: 75 ses örneği, kaynak gri/beyaz tonları. Bu görünüm frekans çubuklarını birleştiren eğri değildir.
- Uzun başlık kutu içinde piksel adımlarıyla kayar. Ses sürgüsüne dokunma ve yan ses tuşları VOLUME= 67% biçiminde bilgi gösterir. Denge sürgüsü BALANCE= CENTRE / BALANCE= 67% LEFT / BALANCE= 43% RIGHT gösterir. Yüzdeler merkezden uzaklıktır. Sürgü tutulurken bilgi kalır; bırakılınca iki saniye sonra başlık geri gelir. Metin aynı kutuya kırpılır.
- kbps sıkıştırılmış dosyanın AudioFile bitrate özelliğinden, kHz dosyanın örnekleme hızından okunur. Klasik kutu tam sayı kHz gösterir: 44100 Hz → 44. VBR dosyalarında dosyanın ortalama bitrate değeri gösterilir; anlık MP3 çerçeve bitrate'i değildir. Okunamayan bitrate uydurulmaz, --- gösterilir.
- İşaretlenen playlist alt alanı kaynak draw_pe.cpp konumlarına göre doldurulur: seçili parça süresi / toplam süre, saatlik toplamlar ve bilinmeyen süre için +/? işaretleri. Bu iOS sürümünde tek parça seçimi vardır. Alt zaman göstergesine dokunarak geçen/kalan süre değişir. Mevcut küçük oynatma düğmeleri kullanılabilir. SEL/MISC/LIST OPTS kapsamlı Windows menüleri bu değişikliğin parçası değildir.
- Winamp dışındaki siyah zemin, tam genişlik yerleşimi ve sistem ses sürgüsü korunur.

## Kaynak izleri

SOURCE-REFERENCE-0.6.json indirilen kaynak dosyalarının SHA-256 ve adreslerini içerir.
FFT ölçeklemesi ayrıca Src/nsutil/main.cpp içindeki IPP_FFT_NODIV_BY_ANY ile kontrol edildi.
Hann tanımı: https://www.intel.com/content/www/us/en/docs/ipp/developer-guide-reference/2022-0/winhann.html (N−1 paydası).
Apple bitrate: https://developer.apple.com/documentation/audiotoolbox/kaudiofilepropertybitrate

## Doğrulama ve sınırlar

Windows'ta 15 uygulama Swift dosyası ve 3 test dosyasının sözdizimi; Xcode kaynak üyeliği; plist/YAML; shell LF; 18 EQ profilinin kaynak değerleri kontrol edildi. Bağımsız NumPy FFT referansında 22050/44100/48000 Hz örnekleme hızlarında 12 ton senaryosu incelendi. Kaynak düşüş denklemleri 60/120 Hz güncellemelerde aynı süre sonunda aynı sonucu verdi. Bu kontroller gerçek Swift/Xcode testi değildir.
GitHub testlerine 19 bant/10 EQ ayrımı, kaynak FFT referans vektörü, tepe hızının FPS bağımsızlığı, MP3 metadata, denge merkez/yön yüzdeleri ve playlist toplamları eklendi. Henüz Xcode üzerinde çalıştırılmadı; gerçek UIKit/telefon testi de yapılmadı.

## Yükleme

ZIP'i çıkarın. WinampClassicIOS klasörünün içindekileri mevcut GitHub deponuzun köküne yükleyin. WinampClassic.xcodeproj, WinampClassic, tests, scripts ve .github klasörlerini birlikte güncelleyin. Yeni repo açmayın. Actions → Build unsigned iPhone IPA → Run workflow ile yeni çalışma başlatın; eski çalışmayı yeniden çalıştırmayın. Başarılı IPA'yı iLoader ile aynı hesap ve uygulama kimliğine güncelleyin.

## Telefon kontrolü

1. Bas/tiz içeren parçada 19 çubuk ve ayrılan, hızlanarak düşen tepeler; dokununca ortada hareket eden çizgi.
2. Ses sürgüsünü hareket ettirmeden tutun: mevcut VOLUME değeri görünmeli, tutuldukça kalmalı. Yan tuşlar da aynı bilgiyi güncellemeli.
3. Denge ortada CENTRE; solda/sağda merkezden uzaklık yüzdesi; bırakınca başlık geri gelmeli.
4. Uzun başlık kaymalı; hiçbir yazı kutudan taşmamalı.
5. Jenerik için 64 kbps / 22 kHz; 44.1 kHz MP3 için 44 kHz gösterilmeli.
6. Playlist seçili/toplam süre ve alt saat; ileri/geri, duraklat/devam ve süre görünümüne dokunma.
7. Uygulamadan çıkıp dönüş, kulaklık değişimi ve kilit ekranından oynatma.
