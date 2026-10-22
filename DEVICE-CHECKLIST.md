# Mac ve iPhone doğrulama listesi

Aşağıdaki kontroller **henüz yapılmadı**. Windows kontrolleri bunların yerine geçmez.

- [ ] İmzasız simülatör derlemesi başarılı: `bash scripts/build-simulator.sh`.
- [ ] iPhone 13 / iOS 27 üzerinde imzalı Debug derlemesi açılıyor.
- [ ] Ana panel ve liste güvenli alan içinde; notch ve home indicator kontrolleri örtmüyor.
- [ ] DRM içermeyen MP3, M4A ve WAV içe aktarılıp çalıyor.
- [ ] İçe aktarmayı iptal etmek mevcut oynatmayı etkilemiyor.
- [ ] iCloud Drive'dan henüz indirilmemiş dosya seçilebiliyor.
- [ ] Bozuk veya desteklenmeyen dosya kullanıcıya hata gösteriyor; mevcut çalma devam ediyor.
- [ ] Play, Pause, Stop, önceki/sonraki ve zaman çubuğu beklenen konuma gidiyor.
- [ ] Ses ve balans duyulabilir biçimde değişiyor.
- [ ] Karışık çalmada mevcut parça tekrar seçilmiyor; tekrar kapalıyken sıra bittiğinde duruyor.
- [ ] Tekrar açıkken listenin sonundan başına geçiyor.
- [ ] Liste satırına dokunmak parçayı çalıyor; farklı satırları silmek geçerli parçayı bozmuyor.
- [ ] Uygulama yeniden açıldığında içe aktarılmış dosyalar ve liste korunuyor.
- [ ] Ekran kilitliyken ses devam ediyor; kilit ekranında başlık, süre ve kumandalar doğru.
- [ ] Telefon araması / ses kesintisi sonrası yalnız sistem izin verdiğinde devam ediyor.
- [ ] Kulaklık çıkarılınca oynatma duruyor; beklenmedik hoparlör sesi oluşmuyor.
- [ ] Türkçe karakterli dosya adı listede doğru, piksel başlıkta anlaşılır görünüyor.
- [ ] `bash scripts/test-eq.sh` offline ses testleri başarılı.
- [ ] 10 bandın her biri müzik çalarken sesi değiştiriyor; preamp seviyesi doğru.
- [ ] ON kapatılınca tüm EQ ve preamp etkisi kalkıyor; tekrar açılınca değerler korunuyor.
- [ ] EQ panelini gizlemek filtreyi kapatmıyor.
- [ ] Flat/Bass/Vocal/Rock seçimi grafiği, sürgüleri ve sesi birlikte değiştiriyor.
- [ ] AUTO açıkken A/B parçalarında ayrı ayarlar kaydedilip geri yükleniyor; yeniden açılışta korunuyor.
- [ ] Sürgüye çift dokunmak 0 dB yapıyor; VoiceOver ile ±1 dB adımlar çalışıyor.
- [ ] EQ açıkken Pause/Play, arama, Stop, sonraki/önceki sonrası ses ve zaman doğru; eski tamamlanma callback'i parçayı atlamıyor.
- [ ] 22.05/44.1/48 kHz mono/stereo dosyalar arasında geçişte çökme veya yanlış perde yok.
- [ ] VoiceOver ile ana kumandalar ve kaydırıcılar kullanılabiliyor.

Sorun kaydında Xcode sürümü, iOS sürümü, dosya biçimi, hata metni ve tekrar adımlarını yazın. Derleme sorunları için `build/simulator-build.log` dosyasını kullanın.
