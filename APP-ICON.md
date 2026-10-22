# 0.4.1 — Açık/koyu uygulama simgesi

Orijinal Windows şimşek logosu kaynak depodaki WinampIcon.ico dosyasından alındı. Çizim yeniden üretilmedi; ICO'nun 256 piksel sürümü, oranı korunarak 1024 piksel iOS varlıklarına dönüştürüldü. Kaynak çözünürlüğü nedeniyle bu bir vektör çizim değildir.

Açık simge opak açık zeminlidir. Koyu simge şeffaf zeminlidir; iOS kendi koyu zeminini sağlar. Kullanıcının ana ekran simge görünümü seçimi hangi sürümün gösterileceğini belirler. Otomatik görünüm seçildiğinde sistemin açık/koyu geçişi kullanılır. Eski iOS sürümleri varsayılan açık simgeyi kullanır. Uygulama içindeki klasik skin aynı kalır.

Kaynak: https://github.com/manfromafar/winamp/blob/9c7f91496c56738fd707905f257643b792c05bb9/Src/Winamp/resource/WinampIcon.ico
SHA-256: e00ec8cf7808faf7743dc2e01d7fd4b83b7f32fc6fe7c8a71433470686e0888c
Lisans: UPSTREAM-LICENSE.md
Apple: https://developer.apple.com/documentation/xcode/configuring-your-app-icon

Yeniden üretim: tools/prepare_app_icon.py, ardından tools/prepare_project.py. Üretilmiş dosyalar pakete dahildir; GitHub derlemesi için Python/Pillow çalıştırmak gerekmez.

Kontrol: İki PNG boyutu/renk modu, JSON ve proje simge ayarı kontrol edildi; açık/koyu statik önizleme incelendi. Shell betikleri LF ve workflow normalleştirme adımı korunuyor. Xcode asset compiler ve iPhone simge seçimi henüz test edilmedi. GitHub derlemesinden sonra açık, koyu ve otomatik ana ekran simge görünümlerinde kontrol edin. Önizlemede sistemin uyguladığı köşe maskesi gösterilmez.
