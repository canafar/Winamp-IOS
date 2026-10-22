# Windows'tan GitHub ile ilk derleme

Bu paket derleme otomasyonunu içerir. Henüz GitHub'a yüklenmedi veya GitHub üzerinde çalıştırılmadı.

1. GitHub'da **New repository** açın. Örneğin `winamp-ios-private` adını verin, görünürlüğü **Private** seçin ve **Add a README file** seçeneğini işaretleyin. Depoyu oluşturun.
2. Paket ZIP'ini Windows'ta çıkarın. İçindeki `WinampClassicIOS` klasörünü açın.
3. Depoda **Add file → Upload files** seçin. Klasörün **içeriğini** yükleyin; dıştaki `WinampClassicIOS` klasörünü yüklemeyin. ZIP dosyasını tek başına yüklemek yeterli değildir.
4. Depo kökünde `WinampClassic.xcodeproj`, `WinampClassic`, `scripts`, `tests` ve `.github` klasörlerinin bulunduğunu kontrol edin. `.github/workflows/ios-check.yml` dosyası görünmelidir. Noktayla başlayan klasör yüklenmediyse GitHub'da **Add file → Create new file** ile bu tam dosya adını yazın ve paketteki YAML içeriğini yapıştırın.
5. Dosyaları **Commit changes** ile kaydedin.
6. **Actions → iOS build and EQ tests → Run workflow → Run workflow** yolunu izleyin. İş akışı varsayılan dalda bulunmalıdır; Actions kapalıysa depo ayarlarından etkinleştirin.
7. Çalışma bittiğinde yeşil/kırmızı durumuna bakın. Kırmızıysa ilgili adımı açın; hata metnini veya **Artifacts → ios-build-logs** çıktısını paylaşın.

İlk aşamada Apple hesabı, sertifika, şifre veya token eklemeniz gerekmiyor. İş akışı yalnız elle başlatılır; her dosya yüklemesinde otomatik çalışmaz. GitHub hesabınızdaki Actions kotasını kullanır; kota/bütçe ayarları çalışmayı sınırlandırabilir.

## Bu iş akışı ne yapar?

- GitHub'ın macOS 15 makinesinde Xcode 16.4 kullanır. iOS 16 minimum hedefini derlemek için sabit bir başlangıç ortamıdır; iOS 27 cihaz doğrulaması değildir.
- Gerçek Apple offline ses motorunda EQ kazanç/bypass/preamp testlerini çalıştırır.
- iPhone simülatörü için uygulamayı derler; simülatörü açıp UI testi yapmaz.
- Hata olsa da logları 7 gün saklar. Tüm kontroller başarılıysa simülatör uygulamasını ZIP olarak kaydeder.

**SIMULATOR-ONLY çıktısı iPhone'a kurulamaz ve IPA değildir.** Gerçek iPhone kurulumu için daha sonra cihaz derlemesi ve Apple imzalama işlemleri kurulmalıdır. Bu aşama yalnız projenin derlenebilirliğini ve EQ ses işlemesini doğrulamak içindir.

Depoyu Private tutun; bu çalışma kişisel kullanım içindir ve upstream lisansı dağıtımı kısıtlar. Bu kurulum App Store veya TestFlight yayını yapmaz.

Kaynaklar:

- https://docs.github.com/en/actions/concepts/runners/github-hosted-runners
- https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md
- https://docs.github.com/en/actions/how-tos/managing-workflow-runs-and-deployments/managing-workflow-runs/manually-running-a-workflow
