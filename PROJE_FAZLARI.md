# 🔧 AutoFix AI Simulator — Görev Takibi

> **AI:** Amazon Nova Lite (Bedrock, us-east-1) | **Platform:** Flutter (iOS+Android) | **Dil:** İngilizce + Türkçe (sonra)

> **Oyun Ekonomisi:** Balayı: Gün 1-3 = 5 enerji | Gün 4-7 = 4 enerji | Gün 8+ = 3 enerji | Streak 3'te 1 = +1 enerji | 45dk cooldown | 1 reklam = cooldown sıfır | Günlük giriş = +1 enerji + 1 ipucu | İpucu paketleri: 3/29₺, 10/69₺, 25/129₺, 50/199₺ | 🏆 Her tamir = +1 ün puanı

> **Güvenlik:** 3 katmanlı prompt injection koruması | Anti-halüsinasyon (bilinmeyen = normal + Lambda filtre)

---

## Faz 0: AI Prototip & Prompt Mühendisliği ✅
- [x] Python ortamı ve bağımlılıklar kurulumu (Streamlit, boto3)
- [x] Ana oyun sistemi prompt'u yazımı (araç/çevre simülasyonu)
- [x] 15 kök arıza senaryosu tanımlama (scenarios.py)
- [x] Danışman Usta (Hint) prompt'u yazımı
- [x] Streamlit chat arayüzü oluşturma (AWS Bedrock entegrasyonu)
- [x] Model karşılaştırma: Nova Micro ✅ Nova Lite ✅ Haiku 4.5 ✅
- [x] Parça değiştirme akışı ([CASE_SOLVED] tag sistemi)
- [ ] Prompt Caching entegrasyonu ve maliyet ölçümü

## Faz 1: AI Çekirdeği Finalizasyonu ✅
- [x] **Prompt Injection Koruması (3 Katman):**
  - [x] Katman 1: Lambda input regex filtresi (yasaklı kalıplar)
  - [x] Katman 2: System prompt hardening (override-proof kurallar)
  - [x] Katman 3: Lambda output filtresi (kök neden sızıntı kontrolü + negation-aware)
- [x] **Anti-Halüsinasyon Sistemi:**
  - [x] System prompt'a "bilinmeyen = normal" katı kuralı eklenmesi
  - [x] Her senaryoya `protected_normal` parça listesi eklenmesi
  - [x] Lambda'da halüsinasyon override mekanizması
- [x] 51 serbest metin stres testi — **%98 başarı** (50/51 pass)
- [x] Nova Micro Türkçe performans testi — **6/6 başarılı** 🇹🇷
- [x] Edge case handling (şaka, emoji, saçmalık, tehlike — 9/9 pass)
- [x] Prompt iyileştirmeleri (false positive fix, negation-aware filtre)

## Faz 2: AWS Backend + Terraform ✅ (büyük bölümü tamamlandı)
- [x] Terraform proje yapısı (modüller: api_gw, lambda, dynamodb, iam)
- [x] S3 state backend + DynamoDB lock table
- [x] **DynamoDB Tabloları:**
  - [x] `Users`: userId, energy, streak, hints, subscription, totalRepairs, displayName
  - [x] `Sessions`: sessionId, userId, scenarioId, chatHistory, msgCount, status (TTL 24h)
  - [x] `DailyResets`: userId + date, energyUsed, loginBonusClaimed (TTL 48h)
  - [x] `Leaderboard`: period (weekly/monthly/yearly) + score_userId, repPoints
- [x] API Gateway (HTTP API) — 7 endpoint + Lambda Authorizer (300s cache)
- [x] **Lambda Fonksiyonları (Python):**
  - [x] `game_handler`: Oturum başlat, mesaj gönder, [CASE_SOLVED] → +1 ün + streak
  - [x] `hint_handler`: Danışman Usta ipucu (kredi kontrolü)
  - [x] `user_handler`: Profil, enerji kontrolü, daily login bonus (+1 enerji +1 ipucu)
  - [x] `ad_reward_handler`: Reklam izleme → enerji/cooldown sıfırlama
  - [x] `leaderboard_handler`: Haftalık/aylık/yıllık top 100
  - [x] `authorizer`: Firebase JWT doğrulama (MVP seviye)
- [x] Shared Lambda Layer (prompts, scenarios, security, db, response)
- [x] Firebase Auth kurulumu (Firebase Console — manuel adım)
- [x] Cooldown sistemi (25 mesaj → 45dk bekleme)
- [x] Enerji sistemi (3/gün + streak 3'te 1 bonus + login bonus)
- [x] Hafıza budaması (ilk durum + son 5 mesaj)
- [x] 3 katmanlı güvenlik (input regex → prompt hardening → output validation)
- [x] Hata yönetimi (Bedrock error → fallback mesaj)
- [x] **E2E Test Geçti:** Profil → Login Bonus → Game Start → AI Message → Prompt Injection → Repair → Leaderboard

## Faz 3: Flutter Mobil Uygulama ✅
- [x] Flutter proje kurulumu (v3.41.9 + Dart 3.11.5)
- [x] State Management: Riverpod (providers.dart)
- [x] Tema ve tasarım sistemi (koyu garaj teması — orange/cyan palette)
- [x] API Client (tüm 7 endpoint bağlı)
- [x] Firebase Auth (Anonymous + Google/Apple Sign-In)
- [x] **Ekranlar:**
  - [x] Splash Screen (animated fade+scale, logo glow, 2.5s)
  - [x] Ana Menü (Garaj) — Enerji kartı, zorluk seçici, streak barı, günlük bonus, reklam butonu
  - [x] Senaryo Seçim — 15 vaka, araç bilgisi + müşteri şikayeti
  - [x] Chat / Oyun ekranı (baloncuklar, typing indicator, çözüm banner, bonus enerji)
  - [x] Cooldown ekranı (2 saat geri sayım + "Reklam İzle" butonu)
  - [x] Enerji çubuğu (ana menüde gradient kartı + reklam butonu)
  - [x] Streak Bar (3'te 1 ilerleme barı)
  - [x] Profil / İstatistikler ekranı (2x2 stat grid, menü listesi)
  - [x] 🏆 Leaderboard ekranı (Haftalık/Aylık/Yıllık tab'lar, podyum top 3)
  - [x] Paywall / Mağaza ekranı (Abonelikler ve ürünler listesi)
- [x] Daily Login Bonus popup (bottom sheet, +1 enerji +1 ipucu gösterimi)
- [x] "Give Up" butonu (teslim ol dialog, streak korunur)
- [x] Otomatik ipucu (15 mesaj popup → ücretsiz hint)
- [x] API entegrasyonu (api_client.dart tüm endpoint'ler)
- [x] Riverpod Providers (UserProfile, GameSession, Leaderboard)
- [x] Flutter Web test başarılı (Chrome localhost:8080)
- [x] **Kademeli Balayı Ekonomisi:**
  - [x] Backend: `calculate_max_energy()` — Gün 1-3=5, Gün 4-7=4, Gün 8+=3
  - [x] Backend: Yeni kullanıcı 5 enerji ile başlar
  - [x] Backend: Profile API → `maxEnergy`, `daysSinceInstall`, `installDate`
  - [x] Flutter: `isHoneymoon` / `isTransition` getter'ları
  - [x] Flutter: FOMO popup ilk 3 gün gösterilmez
  - [x] Flutter: Gün 4-7 geçiş uyarı banner'ı ("Pro'ya geç, sınırsız kalsın")

## Faz 4: IAP, Reklamlar & RevenueCat ✅
- [x] RevenueCat kurulumu
- [x] **Abonelikler:**
  - [x] Pro Weekly ($2.99): Sınırsız enerji + reklam yok + sınırsız ipucu
  - [x] Pro Monthly ($6.99): Aynı + özel senaryolar + detaylı arıza açıklaması
- [x] **Consumable İpucu Paketleri (hint_store_sheet.dart):**
  - [x] 🧰 Küçük Tamir Çantası: 3 ipucu — 29.99 ₺
  - [x] 🔧 Usta Çantası: 10 ipucu — 69.99 ₺
  - [x] ⭐ Patron Çantası: 25 ipucu — 129.99 ₺ (EN ÇOK SATAN)
  - [x] 🔥 Sınırsız Usta: 50 ipucu — 199.99 ₺
- [x] **İpucu Sistemi (game_screen.dart):**
  - [x] Animasyonlu "Yardım" butonu (input bar solunda, pulse glow, badge)
  - [x] Kredi kontrolü (Pro = sınırsız, yoksa kredi düş)
  - [x] FOMO popup (kredi bitince → mağazaya yönlendir)
- [x] **Rewarded Ads:**
  - [x] Google AdMob entegrasyonu (admob_service.dart — rewarded ad servisi)
  - [x] "Reklam İzle → Hemen Devam Et" butonu (cooldown ekranında)
  - [x] AdMob Server-Side Verification (SSV) — `GET /webhook/admob-ssv`
- [x] Paywall ekranı tasarımı (premium hissiyat, decoy pricing)
- [x] FOMO Popup (Gizli Teklif — 1 hafta sınırsız enerji + 5 ipucu hediye, %80 indirim, fake sayaç)
- [x] Sunucu tarafı doğrulama (Lambda webhook — RevenueCat + AdMob SSV)
- [x] **Güvenlik Sıkılaştırmaları:**
  - [x] RevenueCat Webhook Idempotency (Transactions tablosu + TTL 7 gün)
  - [x] Şikayet (Report) sistemi — DynamoDB Reports tablosu + Flutter UI + Lambda
  - [x] Geçersiz userId / custom_data edge case handling (sessiz 200 dönüş)

## Faz 5: Lansman (3-5 gün)
- [x] ASO (İngilizce açıklamalar, anahtar kelimeler)
- [x] Firebase Analytics entegrasyonu
- [ ] Beta testi (TestFlight + Play Console Internal)
- [ ] Mağaza görselleri ve ekran görüntüleri
- [x] Gizlilik Politikası + Kullanım Şartları sayfası (AWS Bedrock / Nova Lite açıkça belirtildi)
- [x] Apple AI guideline uyum kontrolü (Report butonu + 3 katmanlı filtre)
- [ ] Review'a gönderim

## Lansman Sonrası
- [ ] A/B test: 3 vs 4 günlük enerji
- [ ] Haftalık 3-5 yeni senaryo ekleme
- [ ] Türkçe dil desteği
- [ ] "Random Case" Pro modu (AI tamamen özgün arıza oluşturur)
- [ ] Zorluk yıldızları (minimum mesajda çöz challenge)
- [ ] Yıllık abonelik seçeneği ($39.99)

## Faz 6: Başarımlar (Achievements) & Sosyal
- [ ] Google Play Games Services entegrasyonu (Flutter `games_services` paketi)
- [ ] Apple Game Center entegrasyonu
- [ ] Başarım kurguları:
  - [ ] "Çırak": 5 Vaka Çöz
  - [ ] "Usta": 50 Vaka Çöz
  - [ ] "Şahin Gözlü": İpucu kullanmadan 3 vaka çöz
  - [ ] "Sabırlı Usta": 18 mesaja ulaşmadan tek tahminde sorunu bul
- [ ] Liderlik tablosunun (Leaderboard) Play Games / Game Center'a senkronize edilmesi
