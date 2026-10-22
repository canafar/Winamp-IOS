# Winamp 0.5.1

- Winamp panelleri dışındaki üst/alt alanlar saf siyah.
- Ana panelde taşan BAL sağ/sol yüzde yazısı tamamen kaldırıldı. Şarkı metni kendi kutusuna kırpılır.
- Klasik ses sürgüsü gerçek MPVolumeView sistem kontrolüne bağlandı. Telefon ses tuşları ve sürgü aynı medya sesini kontrol eder. Ayrı yazılımsal ses azaltma kaldırıldı; mevcut sistem ses düzeyi kullanılır.
- Ses değişiminde başlık kutusunda kısa süre VOLUME yüzdesi görünür, iki saniye sonra şarkı adı geri gelir.

## Güncelleme
ZIP içindeki WinampClassicIOS klasörünün içeriğini mevcut deponun köküne yükleyin. Xcode proje dosyasını ve yeni SystemVolumeView.swift dosyasını birlikte yükleyin. Actions üzerinden yeni Run workflow başlatın. Başarılı çalıştırmanın IPA dosyasını iLoader ile aynı hesap/uygulama kimliğiyle güncelleyin.

## Kontrol durumu
Windows üzerinde Swift sözdizimi, Xcode kaynak üyeliği, plist, YAML ve shell LF kontrolleri geçti. Gerçek Xcode derlemesi ve cihaz testi yapılmadı. GitHub Actions derlemesi gereklidir.
Telefonda müzik çalarken yan ses tuşlarını ve sürgüyü iki yönde deneyin; Denetim Merkezi ses düzeyiyle eşleşmesini kontrol edin. Arka plandan dönüş ve kulaklık bağlantısında da kontrol edin. Denge sürgüsünde artık görünür yüzde yazısı yoktur.
