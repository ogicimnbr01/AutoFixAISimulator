# 🐞 Hata Takip ve Düzeltme Listesi (Bug Tracker)

Bu dosya cihaz üzerinde yapılan testlerde tespit edilen hataları (bug), eksikleri ve iyileştirmeleri takip etmek için oluşturulmuştur.

## 🔴 Açık Hatalar ve Eksikler (Open Issues)
*Tüm hatalar çözüldü.*

## 🟡 Devam Edenler (In Progress)
*Henüz üzerinde çalışılan bir konu yok.*

## 🟢 Çözülenler (Resolved)
### 1. Fonksiyonel Hatalar (Bugs)
- **Şikayet Butonu:** API rotası eksikliği giderildi, artık şikayetler çalışıyor.
- **Google ile Giriş (Sign-In):** SHA-1/SHA-256 eklendi, artık çalışıyor.
- **Çoklu Dil (L10n):** UI metinlerinin bir kısmı L10n altyapısına bağlandı.
- **Reklam İzleme (Profil):** "Video İzle" butonu AdMob servisine bağlandı, video bitince ödül veriliyor.
- **İpucu (Hint) Halüsinasyonu:** Çift tıklama engeli (`_isLoading` durumu) eklendi.
- **Vaka Detayları Uyuşmazlığı:** Backend'deki araç isimleri Türkçe yapıldı ve L10n hatası çözüldü.

### 2. İyileştirmeler (Improvements)
- **Chatbot Tasarımı:** Daha sade ve yumuşak oval kenarlara geçirildi.
- **Profil Premium Butonu:** "Pro'ya Geç" olarak değiştirildi ve Paywall ekranına yönlendirildi.
- **Dinamik Garaj İpuçları:** Garaj ekranında her açılışta rastgele değişen ipuçları eklendi.
- **Vaka Görselleri:** Vaka seçim ekranına görseller (`assets/images/cars/scenario_X.jpg`) eklendi.
- **Çözülen Vakalar:** İlerleyen süreçte değerlendirilecek, şimdilik atlandı.

### 3. Yasal / Telif (Copyright)
- **Araç İsimlendirmeleri:** Gerçek marka/model isimleri jenerik ve telifsiz isimlerle değiştirildi (örn: 2002 Japon Sedan).
