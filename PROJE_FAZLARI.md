# Auto Fix AI Simulator - Proje Fazlari ve Lansman Durumu

> Son guncelleme: 13 Mayis 2026
> Platform: Flutter mobil uygulama + AWS Serverless backend
> AI: Amazon Bedrock Nova Lite
> Hedef diller: Turkce, Ingilizce, Rusca, Cince

## Oyun Nedir?

Auto Fix AI Simulator, oyuncuyu bir oto tamir ustasinin yerine koyan chat tabanli ariza teshis oyunudur. Oyuncu, dukkanina gelen arizali araclarin sorununu klasik butonlu testlerle degil, musteri/usta simule eden yapay zeka ile yazarak bulur.

Oyuncu aracin belirtilerini dinler, sorular sorar, testler ister, parcalari kontrol eder ve en sonunda dogru tamir hamlesini yapmaya calisir. Oyun hissi "Arabanin nesi var?" sorusunu bir dedektiflik bulmacasina cevirmek uzerine kurulu.

Ana hedefimiz:

1. AI'in tutarli ve adil kalmasi.
2. Vakalarin eglenceli, kisa ve ogretici olmasi.
3. Oyuncuya "ben gercekten ustalasiyorum" hissi vermesi.

## Oynanis Dongusu

1. Oyuncu garajdan zorluk secip vaka listesine girer.
2. Vaka kartinda arac fotografi, arac bilgisi ve musteri sikayeti gorulur.
3. Oyuncu chat ekraninda test/teshis/tamir komutlari yazar.
4. AI sadece senaryo kapsamindaki parcalari ve belirtileri simule eder.
5. Oyuncu dogru kok arizaya yonelip dogru tamir hamlesini yaparsa vaka cozulur.
6. Cozum sonrasi oyuncu un puani, seri ilerlemesi ve gerekirse bonus enerji kazanir.
7. Cozulen vaka tekrar oynatilmaz; vaka kartinda "Cozuldu" olarak gorunur ve oyuncu eski sohbet arsivini okuyabilir.

## Oyun Ekonomisi

- Yeni oyuncu honeymoon donemi:
  - Gun 1-3: 5 enerji
  - Gun 4-7: 4 enerji
  - Gun 8+: 3 enerji
- Her yeni vaka enerji harcar.
- Her tamir +1 un puani verir.
- 3'lu seri tamamlaninca +1 bonus enerji verilir.
- Gunluk giris: +1 enerji +1 ipucu.
- Ipuclari krediyle kullanilir; Pro kullanicida sinirsizdir.
- Ucretsiz oyuncu enerji veya cooldown icin odullu reklam izleyebilir.
- Pro: sinirsiz enerji, sinirsiz ipucu, reklamsiz deneyim ve arsiv limit avantajlari.
- Ucretsiz oyuncu gunde 2 farkli cozulmus vaka sohbet arsivi acabilir; Pro sinirsiz acar.

## Faz 0 - AI Prototip ve Prompt Muhendisligi

- [x] 15 kok ariza senaryosu olusturuldu.
- [x] Streamlit prototipi ile Bedrock chat akisi dogrulandi.
- [x] Nova Micro, Nova Lite ve alternatif modeller karsilastirildi.
- [x] Ana oyun prompt'u ve Danisman Usta/Hint prompt'u yazildi.
- [x] `[CASE_SOLVED]` temelli cozum isareti sistemi kuruldu.
- [x] Basit, orta ve zor vakalar icin belirtiler ve test yanitlari kurgulandi.
- [ ] Prompt caching ve model maliyet olcumu ayrintili sekilde yapilmadi.

## Faz 1 - AI Cekirdegi ve Adil Teshis

- [x] 3 katmanli prompt injection korumasi eklendi.
- [x] "Bilinmeyen test/parca = normal veya gecersiz" kurali eklendi.
- [x] Protected normal parca listeleri ile saglam parcayi bozuk gosterme halusinasyonu azaltildi.
- [x] Output filtresi kok neden sizintisini ve yanlis cozum isaretlerini yakalayacak sekilde guclendirildi.
- [x] Akku, mars motoru ve sol far sigortasi gibi kritik kolay vakalarda smoke QA scripti yazildi.
- [x] False solved sorunu azaltildi: ornegin akude asit/saf su/harici sarj hamlesi tek basina cozum sayilmiyor.
- [x] Cozum sonrasi dinamik Usta Yorumu eklendi; oyuncunun onceki denemelerini de dikkate aliyor.
- [ ] Tum 15 senaryo icin cok turlu regression testi henuz duzenli CI'a baglanmadi.
- [ ] Kritik karar anlari icin Nova Lite + Nova Pro routing henuz uygulanmadi.

## Faz 2 - AWS Backend ve Veri Katmani

- [x] Terraform modulleri kuruldu: API Gateway, Lambda, DynamoDB, IAM.
- [x] S3 remote state ve DynamoDB lock yapisi hazir.
- [x] Firebase JWT Lambda Authorizer aktif.
- [x] Lambda fonksiyonlari:
  - [x] `game_handler`: oyun baslatma, mesajlasma, cozum, arsiv, cooldown.
  - [x] `hint_handler`: Danisman Usta ipucu.
  - [x] `user_handler`: profil, enerji, gunluk bonus, hesap silme, merge.
  - [x] `ad_reward_handler`: odullu reklam, SSV webhook, test client reward.
  - [x] `leaderboard_handler`: haftalik/aylik/yillik siralama.
  - [x] `revenuecat_webhook`: abonelik ve satin alma webhook'u.
  - [x] `report_handler`: AI cevabi sikayet sistemi.
- [x] DynamoDB tablolari:
  - [x] Users
  - [x] Sessions
  - [x] DailyResets
  - [x] Leaderboard
  - [x] Transactions
  - [x] Reports
  - [x] DeviceStates
- [x] Cozulmus vaka arsivi eklendi:
  - [x] `GET /game/completed`
  - [x] `GET /game/archive/{id}`
  - [x] Cozulmus vaka tekrar baslatilinca 409 `already_solved`
- [x] Device economy korumasi eklendi:
  - [x] Install ID hash ile enerji/limit abuse riski azaltiliyor.
  - [x] Kullanici hesabini silip tekrar acarak ekonomiyi resetleme riski azaltildi.
- [x] Anonim hesap silme backend tarafinda engellendi.
- [x] Prod backend son degisikliklerle deploy edildi.
- [ ] AdMob ECDSA SSV imza dogrulamasi henuz tamamlanmadi.
- [ ] Test donemi icin `ALLOW_CLIENT_AD_REWARD=true`; gercek reklam unitleri ve SSV imza dogrulamasi hazir olunca tekrar kapatilmali.

## Faz 3 - Flutter Mobil Uygulama

- [x] Flutter proje kurulumu tamamlandi.
- [x] Riverpod state management kullaniliyor.
- [x] Firebase Anonymous Auth + Google/Apple hesap baglama akisi var.
- [x] Cihaz dili desteklenen 4 dilden biriyse ilk acilista otomatik seciliyor; desteklenmiyorsa Ingilizce aciliyor.
- [x] Kullanici manuel dil secerse tercih kaydediliyor.
- [x] Ekranlar:
  - [x] Splash
  - [x] Garaj ana ekran
  - [x] Zorluk secimi
  - [x] Vaka secimi
  - [x] Chat/oyun ekrani
  - [x] Hint magazasi
  - [x] Paywall
  - [x] Profil
  - [x] Ayarlar
  - [x] Leaderboard
- [x] Vaka seciminde arac fotograflari eklendi.
- [x] Cozulmus vaka tasarimi eklendi: tik, "Cozuldu", "Sohbeti Gor".
- [x] Read-only arsiv chat goruntuleme eklendi.
- [x] Basari paneli ve hafif konfeti etkisi eklendi.
- [x] Gorsel kimlik pass'i yapildi:
  - [x] Daha mat garaj/servis paleti.
  - [x] Daha az yapay zeka hissi veren kartlar.
  - [x] Daha az glow/gradient.
  - [x] Emoji yerine daha cok ikon kullanimi.
- [x] Anonim kullanicida hesap silme butonu yerine bilgilendirme karti gosteriliyor.
- [x] Profil yuklenmeden vaka baslatma engellendi.
- [x] 4 dilde yeni UI metinleri l10n'ye baglandi.
- [ ] Tum ekranlarda kalan eski emoji/mojibake metinler tamamen temizlenmedi.
- [ ] Paywall ve profil ekranlari son gorsel kimlik pass'ine tam uyarlanmis degil.
- [ ] Tablet/kucuk ekran tasarim kontrolu henuz sistematik yapilmadi.

## Faz 4 - Monetization: RevenueCat, AdMob, Pro

- [x] RevenueCat SDK entegre edildi.
- [x] RevenueCat webhook idempotency eklendi.
- [x] Pro abonelik backend tarafinda enerji/ipucu icin dikkate aliniyor.
- [x] Ipuclari RevenueCat paketlerine baglandi.
- [x] Odullu reklam video akisi calisiyor.
- [x] Test reklam sonrasi client reward Play/internal test icin aktif edildi.
- [x] Cooldown ve enerji odulu endpointleri mevcut.
- [ ] Android gercek AdMob rewarded ad unit ID'leri girilmedi.
- [ ] iOS RevenueCat public key placeholder riski devam ediyor.
- [ ] Apple/Google urun ID'lerinin store tarafinda final kontrolu gerekiyor.
- [ ] Production reklam odulu icin client reward kapatilmali ve SSV imza dogrulamasi tamamlanmali.

## Faz 5 - QA, Test Hesabi ve Release Hazirligi

- [x] Kalici anonim QA test hesabi olusturuldu.
- [x] `tester/firebase_test_token.py` ile test token yenileme ve smoke calistirma akisi var.
- [x] `tester/prod_smoke_qa.py` ile S01/S02/S03 smoke testleri calistirilabiliyor.
- [x] Far sigortasi halusinasyonunu yakalayan regression eklendi.
- [x] Backend deploy sonrasi canli API testleri yapildi.
- [x] Release APK build alip telefona kurma akisi dogrulandi.
- [x] Release AAB build alindi.
- [ ] Play Console Internal Testing'e AAB yuklenmedi.
- [ ] Internal test build telefondan yuklenip smoke QA tekrarlanmadi.
- [ ] Magaza ekran goruntuleri final build uzerinden alinmadi.
- [ ] 4 dilde manuel UI smoke test tamamlanmadi.
- [ ] Tum 15 vaka icin "cozuldu/arsiv/tekrar oynanamaz" manuel kontrolu tamamlanmadi.

## Faz 6 - Legal, Privacy ve Store Uyumu

- [x] Vercel `index.html` gizlilik politikasi mevcut.
- [x] Hesap silme sayfasi mevcut.
- [x] Bedrock/Nova Lite kullanimi politikada belirtiliyor.
- [x] Cozulmus vaka chat arsivi ve anti-abuse device economy kayitlari politikaya eklendi.
- [x] Anonim hesaplar icin app icinden silme kapatildi; manuel talep yolu politikada aciklandi.
- [x] AI cevabi sikayet/report butonu var.
- [ ] Privacy metni ile app icindeki tum akislari son kez hukuk/store checklist olarak okumak gerekiyor.
- [ ] Play Console Data Safety formu son veri akislariyla doldurulmadi.
- [ ] App Store tarafina girilecek privacy nutrition bilgileri son haliyle hazirlanmadi.

## Faz 7 - Lansman Sonrasi Gelistirme

- [ ] Haftalik yeni vaka paketi.
- [ ] Random Case / Pro ozel vaka modu.
- [ ] Model routing: ucuz model + guclu model kritik karar ayrimi.
- [ ] Oyuncu performansina gore zorluk yildizi.
- [ ] Basarim sistemi:
  - [ ] Cirak: 5 vaka coz.
  - [ ] Usta: 50 vaka coz.
  - [ ] Sahin Gozlu: ipucu kullanmadan 3 vaka coz.
  - [ ] Sabirli Usta: mesaj limitine takilmadan coz.
- [ ] Google Play Games / Game Center entegrasyonu.
- [ ] Leaderboard'u Play Games / Game Center ile senkronize etme.
- [ ] A/B test: enerji ekonomisi, honeymoon suresi, paywall zamanlamasi.

## Kritik Eksikler - Bugun Gormemiz Gerekenler

1. Play Console Internal Testing'e AAB yukle.
2. Internal test build ile telefonda su akislari dene:
   - Ilk acilista cihaz dili secimi.
   - Enerji karti ve profil yukleme.
   - S01/S02/S03 smoke.
   - Cozulmus vakanin tekrar oynanamamasi.
   - Cozulmus vaka sohbet arsivi.
   - Odullu reklam izleyince enerji gelmesi.
   - Anonim hesapta silme butonunun gorunmemesi.
3. Magaza ekran goruntulerini final internal build uzerinden al.
4. Play Console Data Safety formunu privacy metnine gore doldur.
5. AdMob icin karar ver:
   - Internal testte client reward acik kalabilir.
   - Production review'a cikarken gercek SSV dogrulamasi yoksa risk notu var.
6. iOS release dusunuluyorsa RevenueCat iOS public key ve Apple urunleri tamamlanmali.
7. Tum 4 dilde en az garaj, vaka secimi, chat, profil, ayarlar, paywall hizli kontrol edilmeli.

## Son Bilinen Build/Deploy Durumu

- Backend prod deploy: yapildi.
- `ALLOW_CLIENT_AD_REWARD`: test donemi icin `true`.
- `ALLOW_UNVERIFIED_ADMOB_SSV`: prod icin kapali.
- Son APK build: telefona kurulup test edilebilir durumda.
- Son AAB build: alinmis durumda, fakat son locale/reward degisikliklerinden sonra tekrar AAB alinmasi gerekir.
- Git durumu: son degisikliklerin commitlenmesi gerekiyor.
