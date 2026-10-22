# 0.4.0 — Aşama 1: klasik spektrum

Bu aşamada iki yatay kanal göstergesi yerine gerçek ses frekanslarından hesaplanan 10 dikey çubuk eklendi. Solda düşük, sağda yüksek frekanslar; klasik renk paleti ve düşen tepe işaretleri kullanılır. Tek dokunuş çizgi spektruma, tekrar dokunuş çubuklara döner. Görünüm seçimi saklanır. FFT, EQ çıkışından alınan örneklere uygulanır; çizgi modu kullanıcının isteğiyle aynı 10 frekans bölgesini birleştirir. Bu, zaman dalgası osiloskopundan farklıdır.

## GitHub'a yükleme

1. ZIP'i aç. WinampClassicIOS klasörünün İÇİNDEKİ dosya ve klasörleri mevcut özel deponun köküne yükle. Üst klasörü yükleme. Mevcut dosyaları güncelle.
2. `.github/workflows/unsigned-ipa.yml` ve `ios-check.yml` dosyalarını da güncelle. Tarayıcı gizli klasörü yüklemiyorsa GitHub'da mevcut dosyayı aç, kalemle düzenle, paketteki aynı dosyanın tamamını yapıştır ve kaydet.
3. Actions → Build unsigned iPhone IPA → Run workflow. Yeni workflow önce EQ ve spektrum testlerini çalıştırır; başarılıysa IPA üretir.
4. Yeşil sonuçtan IPA artifact'ını indir, ZIP'ten IPA'yı çıkar ve aynı Apple hesabıyla Sideloadly üzerinden yükle. Uygulamayı önceden silme; aynı uygulama kimliğiyle güncelleme yap.

## İlk açılış ve liste

Verilen DJ Mike Llama – Llama Whippin.mp3, intro.mp3 adıyla uygulamaya aynen eklendi (yaklaşık 5,4 saniye). Bu sürümün ilk açılışında otomatik çalar, listede kalır ve tekrar açılışlarda otomatik çalmaz. Var olan liste silinmez; jenerik ilk satıra eklenir. Kullanıcı listeden silerse sonraki açılışta geri eklenmez. Başarısız oynatma sonraki uygulama açılışında yeniden denenir.

Playlist dosyasındaki duration alanı isteğe bağlıdır; eski listeler okunmaya devam eder. Süresi olmayan parçalar dosyalarından okunur. Bilinmeyen süre --:--, bilinen süre dakika:saniye biçiminde sağda gösterilir. Uzun başlıklar süre sütununu kapatmaz.

## Telefonda kontrol

- İlk açılışta jenerik bir kez çalıyor, listede görünüyor ve ses sorunsuz mu?
- Uygulamayı kapatıp açınca jenerik yeniden otomatik başlamıyor ve kopyalanmıyor mu?
- Eski parçalar korunuyor ve süreleri sağda görünüyor mu? Uzun başlıkla da kontrol et.
- Zaman göstergesine dokununca eksi kalan süreye, tekrar dokununca geçen süreye geçiyor mu?
- Bir bas vuruşundan sonra gri tepe işareti çubuktan ayrılıp yavaşça düşüyor mu?
- Bilinen bir müzikte düşük ve yüksek frekans çubukları farklı hareket ediyor mu?
- Spektruma bir dokunuş çizgiye, ikinci dokunuş çubuklara geçiriyor mu?
- Duraklatmada çubuklar sönüyor ve çizgi yatay hale geliyor mu?
- EQ değişikliği hem duyuluyor hem frekans göstergesine yansıyor mu?
- Şarkı değiştirirken, ileri sararken ve arka plana geçerken ses sorunsuz sürüyor mu?

## Sonraki aşamalar — henüz uygulanmadı

2. Sol/sağ denge yüzdesini görünür yapma; 49–51 aralığında 50 merkezine tutunma, aralıktan çıkınca serbest bırakma.
3. Klasik Windows EQ hazır ayarlarının tam listesini ve değerlerini ekleme.
4. iPhone 13 için tam ekran düzenini adım adım geliştirme.

Bu güncelleme Windows'ta tip denetiminden veya iOS derlemesinden geçirilmedi. Eklenen otomatik testler GitHub'ın macOS ortamında çalışacak.
