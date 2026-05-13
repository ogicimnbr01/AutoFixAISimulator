# Pro Early Access Strategy

Auto Fix AI Pro sadece sinirsiz enerji veya ipucu paketi gibi hissettirilmemeli. Pro oyuncu, oyunun gelisimine erken dahil olan "usta ekip" hissini almalı.

## Ana Vaat

Pro oyuncular yeni vaka paketlerine herkesten once erisir.

Kisa urun cumlesi:

> Pro Usta ol, yeni ariza vakalarini erken oyna.

## Neden Gerekli?

Launch doneminde vaka sayisi sinirli: 15 vaka, 5 kolay, 5 orta, 5 zor.

Bu nedenle Pro degeri sadece mevcut icerige baglanirsa oyuncu "bosuna para verdim" hissedebilir. Early access sistemi Pro'yu canli servis avantajina cevirir:

- Pro oyuncu yeni vakalari once dener.
- Ucretsiz oyuncu oyunun duzenli buyudugunu gorur.
- Haftalik update ritmi daha anlamli hale gelir.
- Pro abonelik "devam eden avantaj" gibi hissedilir.

## Icerik Ritmi

Onerilen update ritmi:

- Her hafta 3 yeni vaka.
- 1 kolay, 1 orta, 1 zor.
- Temali paketler halinde yayinlanir.

Ornek temalar:

- Elektrik Paketi
- LPG Paketi
- Sogutma Paketi
- Dizel Paketi
- Fren ve Yurutme Paketi
- Sensor ve OBD Paketi

## Early Access Kurali

Yeni eklenen vakalar once Pro oyunculara acilir.

Onerilen sure:

- Pro early access: 7 gun.
- 7 gun sonra vakalar tum oyunculara acilir.

Alternatif:

- Pro early access: 14 gun.
- Bu daha guclu bir Pro avantaji verir ama ucretsiz oyuncuda bekleme hissini artirir.

Launch icin onerilen secim: 7 gun.

## Oyuncuya Nasil Anlatilmali?

Paywall / Magaza metni:

- Sinirsiz enerji
- Reklamsiz deneyim
- Ekstra ipuclari
- Yeni vakalara erken erisim

Kisa rozet:

> Early Access

Turkce:

> Yeni vakalara erken erisim

Ingilizce:

> Early access to new cases

Rusca:

> Ранний доступ к новым делам

Cince:

> 提前体验新案件

## Vaka Kartinda Gosterim

Early access vaka kartlarinda kucuk bir rozet olabilir:

- Pro Erken Erisim
- 6 gun sonra herkese acilir

Ucretsiz oyuncu tikladiginda:

> Bu vaka su an Pro ustalara erken erisimde. Pro ile hemen oyna veya herkese acilmasini bekle.

Pro oyuncu tikladiginda:

> Early Access vakasi. Geri bildirimin yeni vaka dengesini iyilestirmemize yardimci olur.

## Teknik Uygulama Plani

Her senaryoya yeni alanlar eklenebilir:

```json
{
  "id": 16,
  "difficulty": "Easy",
  "category": "Electrical",
  "release_at": "2026-05-20",
  "early_access_until": "2026-05-27",
  "pro_early_access": true
}
```

Erisim mantigi:

- Pro ise: `release_at` tarihinden itibaren oynar.
- Ucretsiz ise: `early_access_until` gecince oynar.
- Eski vakalarda bu alanlar yoksa herkes oynar.

Backend kontrolu:

- `start_session` icinde senaryo erisimi kontrol edilmeli.
- Ucretsiz oyuncu erken erisim vakasina baslarsa `403 early_access_required` donmeli.

Frontend kontrolu:

- Vaka secme ekraninda kilitli Pro early access karti gosterilmeli.
- Pro olmayan oyuncu karti gorur ama oynayamaz.
- Kart uzerinde kalan gun bilgisi gosterilebilir.

## Dikkat Edilecekler

- Early access, pay-to-win gibi anlatilmamali. Bu oyun rekabetli olsa da ana deger ustalik ve icerik.
- Vaka tamamen Pro'ya ozel kalmamali; belirli sure sonra herkese acilmali.
- Pro oyuncuya "oyunun gelisiminde oncu" hissi verilmeli.
- Yeni vaka QA edilmeden early access'e alinmamali.

## Basari Kriteri

Pro oyuncu sunu hissetmeli:

> Ben sadece enerji satin almiyorum; Auto Fix AI'in yeni vakalarini ilk deneyen usta ekibin icindeyim.

