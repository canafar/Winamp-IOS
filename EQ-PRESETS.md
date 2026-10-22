# Özgün EQ profilleri

Kaynak: https://github.com/manfromafar/winamp/blob/9c7f91496c56738fd707905f257643b792c05bb9/Src/Winamp/main.cpp (CreateEQPresets).
Dönüşüm: aynı revizyondaki Src/Winamp/In.cpp VALTODB. 31 = 0 dB, 0 = +12 dB, 63 = -12 dB. Özgün preamp 31 = 0 dB. Ses filtresi iOS AVAudioUnitEQ olduğu için Windows ile bit düzeyinde aynı çıktı iddiası yoktur.

18 profil kaynak sırasıyla:

- Classical: 31, 31, 31, 31, 31, 31, 44, 44, 44, 48
- Club: 31, 31, 26, 22, 22, 22, 26, 31, 31, 31
- Dance: 16, 20, 28, 32, 32, 42, 44, 44, 32, 32
- Flat: 31, 31, 31, 31, 31, 31, 31, 31, 31, 31
- Laptop speakers/headphones: 24, 14, 23, 38, 36, 29, 24, 16, 11, 8
- Large hall: 15, 15, 22, 22, 31, 40, 40, 40, 31, 31
- Party: 20, 20, 31, 31, 31, 31, 31, 31, 20, 20
- Pop: 35, 24, 20, 19, 23, 34, 36, 36, 35, 35
- Reggae: 31, 31, 33, 42, 31, 21, 21, 31, 31, 31
- Rock: 19, 24, 41, 45, 38, 25, 17, 14, 14, 14
- Soft: 24, 29, 34, 36, 34, 25, 18, 16, 14, 12
- Ska: 36, 40, 39, 33, 25, 22, 17, 16, 14, 16
- Full Bass: 16, 16, 16, 22, 29, 39, 46, 49, 50, 50
- Soft Rock: 25, 25, 28, 33, 39, 41, 38, 33, 27, 17
- Full Treble: 48, 48, 48, 39, 27, 14, 6, 6, 6, 4
- Full Bass & Treble: 20, 22, 31, 44, 40, 29, 18, 14, 12, 12
- Live: 40, 31, 25, 23, 22, 22, 25, 27, 27, 28
- Techno: 19, 22, 31, 41, 40, 31, 19, 16, 16, 17

Bass ve Vocal önceki iOS özel ayarları olarak ayrıca korunur. Rock artık özgün kaynak değerlerini kullanır. Pozitif kazançlı profillerde yüksek seviyeli kayıtlarda gerekirse preamp azaltılabilir.
