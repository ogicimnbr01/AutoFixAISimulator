# Kritik Sorunlar ve Model Notlari

Bu dosya kod degisikligi degildir; bos vakitte ele alinacak takip listesidir.

## Kritik Sorunlar

1. [DUZELTILDI] Frontend ve backend senaryo verileri eslesmiyor.
   - Ornek: App tarafinda 10. vaka "devir artiyor ama arac hizlanmiyor"; backend tarafinda 10. vaka O2 sensoru arizasi.
   - Risk: Oyuncu baska sikayet gorup AI'dan baska ariza davranisi alabilir.
   - Ilgili dosyalar:
     - app/lib/screens/scenario/scenario_select_screen.dart
     - app/lib/l10n/app_tr.arb
     - backend/lambdas/shared/scenarios.py

2. [DUZELTILDI] Pro abonelik backend tarafinda tam uygulanmiyor.
   - Pro vaatleri: sinirsiz enerji, sinirsiz ipucu, reklamsiz deneyim.
   - Mevcut risk: game_handler enerji dusmeye devam edebilir; hint_handler Pro kontrolu yapmadan hint kredisi isteyebilir.
   - Ilgili dosyalar:
     - backend/lambdas/game_handler/handler.py
     - backend/lambdas/hint_handler/handler.py
     - app/lib/providers/providers.dart

3. [DUZELTILDI] Leaderboard skor artisi sorunlu olabilir.
   - add_leaderboard_point fonksiyonu mevcut kullanici skor kaydini dogru bulmak yerine gecici anahtar uzerinden islem yapiyor.
   - Risk: Tamir sayisi artsa bile leaderboard puani 1'de kalabilir veya tekrarli kayit davranisi olusabilir.
   - Ilgili dosya:
     - backend/lambdas/shared/db.py

4. [KISMEN DUZELTILDI] Reklam odulu production guvenligi hazir degil.
   - App test AdMob unit ID kullaniyor.
   - Prod ortamda client-side reward kapatildi.
   - Prod ortamda dogrulanmamis AdMob SSV kapatildi.
   - Kalan is: Gercek AdMob ECDSA imza dogrulamasini eklemek ve gercek ad unit ID'lerini girmek.
   - Ilgili dosyalar:
     - app/lib/core/services/admob_service.dart
     - backend/lambdas/ad_reward_handler/handler.py

5. [KISMEN DUZELTILDI] RevenueCat iOS anahtari placeholder.
   - iOS icin gercek public key girilmeden iOS satin alma akisi production'a hazir degil.
   - RevenueCat webhook icin opsiyonel Bearer secret kontrolu eklendi.
   - Kalan is: iOS public key ve Terraform secret degerini prod ortamda set etmek.
   - Ilgili dosya:
     - app/lib/core/services/revenuecat_service.dart

## Model Notlari

Mevcut kullanim: Amazon Bedrock Nova Lite.

Oyun icin ana problem modelin her zaman "akilli sohbet" yapmasi degil; senaryo kurallarina sadik kalmasi, ariza disina cikmamasi ve cevabi erken sizdirmemesidir. Bu nedenle model yukseltme kadar onemli iki konu var:

1. Daha deterministik cevap almak icin dusuk temperature kullanmak.
2. Model routing yapmak: basit test/normal parca cevaplari ucuz modelde, kritik tamir/teshis karari daha guclu modelde.

Onerilen strateji:
- Varsayilan: Nova Lite.
- Kritik anlar: Nova Pro.
- Sadece test komutu siniflandirma / intent routing: Nova Micro veya kural tabanli parser.
