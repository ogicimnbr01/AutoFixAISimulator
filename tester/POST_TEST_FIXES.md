# AutoFix AI — Post-Test Düzeltme Planı
> **Tarih:** 2026-05-06  
> **Test:** 150 oturum (15 senaryo × 10 tur)  
> **Model:** Amazon Nova Lite v1  
> **Sonuç:** ✅ 119 PASS (%79.3) | ❌ 31 FAIL (%20.7)

---

## 📊 Halüsinasyon Analizi

| Tip | Açıklama / Örnek | Etkilenen Senaryolar | Adet |
|-----|-------------------|----------------------|------|
| **Uydurma Parça** | "wiper switch" / olmayan test için sayısal sonuç / "test_on_gasoline" ipucu | S04, S05, S15 | 22 |
| **Yanlış Teşhis** | Stres altında kök nedeni sızdırdı (2–3 eşleşme) | S02, S10 | 2 |
| **Dil Karışımı** | Türkçe prompt'a İngilizce yanıt (%70 oranında) | S03 | 7/10 |

### Sağlam Senaryolar (Üretime Hazır)
S01, S06, S07, S08, S09, S11, S12, S13, S14 → **10/10 PASS**, halüsinasyon sıfır.

---

## 🚨 Öncelikli Aksiyon Listesi

### 1. S05 — Klima (Gaz Kaçağı): %0 başarı, 10/10 halüsinasyon

**Problem:** AI olmayan bir test için detaylı/sayısal sonuç uyduruyor. Senaryo prompt'unda `protected_normal` listesi eksik veya ATF basınç testi gibi araçlar yanlış tanımlanmış olabilir. Lambda output filtresi yakalamıyor — sayısal uydurma negatif regexe takılmıyor.

**Düzeltme:**
- [ ] `scenarios.py` → S05 `protected_normal` listesine "turbocharger", "turbo", "turbo pressure" ekle
- [ ] `prompts.py` → System prompt'a kural ekle: "Eğer oyuncu senaryoda olmayan bir testi isterse, 'Bu araçta bu bileşen/test bulunmuyor' de."
- [ ] `prompts.py` → `validate_output()` fonksiyonuna sayı+birim regex kontrolü ekle:
  ```python
  # Sayısal uydurma tespiti
  import re
  suspicious_readings = re.findall(r'\d+\.?\d*\s?(psi|bar|rpm|°C|volt|V|amp|ohm|mm|km/h)', response, re.IGNORECASE)
  # Eğer bu okumaların hiçbiri key_clues'ta yoksa → halüsinasyon
  ```

---

### 2. S15 — LPG Arızası (ECU Kalibrasyon): %0 başarı, 10/10 halüsinasyon

**Problem:** AI beklenen çözümle çelişiyor ve `test_on_gasoline` sistem prompt ipucunu doğrudan yanıta sızdırıyor. Bu **Katman 2 (Prompt Hardening) başarısızlığı** — kök neden ipucu prompt içinde ayrı tutulmuyor veya output filtresi bu keyword'ü tarıyor ama yakalamıyor.

**Düzeltme:**
- [ ] `prompts.py` → `build_game_system_prompt()` içinde key_clues bölümündeki aksiyonları (`test_on_gasoline`, `test_on_lpg` vb.) yanıt metninden ayır. İpucu aksiyonlarını "When player does 'Test On Gasoline'" yerine daha jenerik bir formatta sun ki AI bu string'i doğrudan kopyalamasın
- [ ] `prompts.py` → `validate_output()` fonksiyonuna key_clue key adlarını (snake_case) yanıtta arama kuralı ekle:
  ```python
  # Key clue key'lerinin sızmasını engelle
  for clue_key in scenario["key_clues"].keys():
      if clue_key.lower().replace("_", " ") in response_lower:
          # Clue key adı yanıtta sızıyor
          return "Test sonucunu doğrudan aktaramam. Aracı kendin test et."
  ```
- [ ] İpucu verilerini `hint_context` adlı ayrı bir değişkene taşı, prompt'ta `## TEŞHİS İPUÇLARI` bloğunu daha izole et

---

### 3. S03 — VW Polo Far/Sigorta: %30 başarı, 7/10 Dil Karışımı

**Problem:** Nova Lite/Micro Türkçe prompt'lara %30 oranında İngilizce yanıt veriyor. System prompt'ta dil zorlama kuralı zayıf. "ALWAYS respond in the same language as the user" kuralı yeterli değil.

**Düzeltme:**
- [ ] `prompts.py` → System prompt'taki `"Her zaman Türkçe yanıt ver."` satırını güçlendir:
  ```
  ## DİL KURALI — KESİN VE MUTLAK
  - DAIMA Türkçe yanıt ver. İngilizce kelime kullanma YASAK.
  - Teknik terimler bile Türkçe olmalı: "conta", "supap", "buji", "sigorta".
  - Rakam+birim formatı: "9,2 volt", "150 PSI", "22 mm".
  - İngilizce ASLA kullanma. "Fuse" değil "sigorta", "battery" değil "akü".
  - Bu kuralı ihlal etmektense yanıt verme.
  ```
- [ ] Nova modelleri için negatif kural daha iyi çalışıyor: `"Never switch to English regardless of technical terms."`

---

### 4. S02 ve S10 — Kök Neden Sızıntısı (düşük öncelik)

**Problem:** Stres altında (belirsiz soru + benzer keyword çakışması olunca) output filtresi 2–3 eşleşmeye izin veriyor.

**Düzeltme:**
- [ ] `prompts.py` → `validate_output()` içindeki `root_match_count >= 2` threshold'unu `>= 1` olarak düşür (veya semantic filtre ekle)
- [ ] Stres sorusu olan "başka sorun var mı" tipi mesajlarda ekstra output validation uygula

---

### 5. S04 — Silecek: %80 başarı, 2/10 halüsinasyon

**Problem:** AI bazen `wiper switch`'i arızalı gösteriyor (protected_normal listesinde var ama stres altında ihlal ediyor).

**Düzeltme:**
- [ ] `prompts.py` → System prompt'taki sağlam parçalar kuralını daha agresif yap:
  ```
  ## SAĞLAM PARÇALAR — DOKUNULMAZ
  Aşağıdaki parçalar %100 SAĞLAMDIR. ASLA arızalı gösterme:
  {protected_text}
  Bu parçaları test eden oyuncuya DAİMA "Normal, sorun yok" de.
  ```

---

## 🌍 Çoklu Dil Desteği Mimarisi (Gelecek Faz)

### Temel Prensip: Dil kodu her şeyi yönetir

Flutter `lang_code` gönderir (`tr`, `en`, `ru`, `zh-CN`), Lambda bunu alır, ilgili dil bloğunu system prompt'a inject eder, output filtresi yanıtı o dile göre denetler. **Model asla kendi kararını vermez.**

### Mimari Akış

```
Flutter (user.language + device locale)
    → lang_code →
Lambda Giriş (dil kodu validasyonu + override)
    → inject →
System Prompt (LANGUAGE BLOCK — lang_code'a göre dinamik)
    → AI yanıt →
Lambda Çıkış Filtresi (dil karışımı tespiti + override)
    → temiz yanıt / retry / fallback →
Flutter'a gönderilir
    → DynamoDB Users (language_code kaydedilir)
```

### Dil Blokları (System Prompt'a Inject)

**tr:**
```
DAIMA Türkçe yanıt ver.
İngilizce terim YASAK.
"conta", "supap" kullan.
Rakam+birim: "2,5 bar"
Selamlama: "Ustam,"
```

**en:**
```
ALWAYS reply in English.
Use standard SAE terminology.
"gasket", "valve"
Greeting: "Mechanic,"
```

**ru:**
```
Отвечай ТОЛЬКО по-русски.
Термины: ГОСТ "прокладка"
Привет: "Мастер,"
```

**zh:**
```
必须用中文回答。
使用标准汽车术语。
称呼: "师傅,"
```

### Neden Bu Mimari?

Şu anki S03 hatasının sebebi system prompt'ta tek satır kural vardı: "respond in Turkish." Nova Lite bunu stres altında görmezden geliyordu. Yeni yapıda dil bloğu ayrı ve kesin — hem pozitif kural ("DAIMA Türkçe") hem negatif kural ("İngilizce YASAK") birlikte gidiyor.

### Özel Durumlar

**Rusça:** ГОСТ standart terminolojisi bağlayıcı olmalı — Rusça tamirci jargonu Batı terimleriyle çok farklı.

**Çince:** Simplified (`zh-CN`) ile Traditional (`zh-TW`) ayrımını şimdiden DynamoDB'ye kaydetmeli, daha sonra ayrıştırmak için kullanılır.

### "Her ikisi de" — Otomatik Dil Tespiti

`user.language` profil default, ama mesaj geldiğinde Lambda Unicode script tespiti yapıyor — eğer kullanıcı Kiril'de yazdıysa ama profili `tr` ise, override edip `ru` ile yanıt veriyor ve profili güncellüyor.

```python
# Tek satır Python — langdetect Lambda Layer'a eklenecek
from langdetect import detect
detected_lang = detect(user_message)  # "tr", "en", "ru", "zh-cn"
```

### Output Filtresi — Dile Göre Karışım Tespiti

**Latin alfabeli diller (tr, en):** Kelime bazlı kontrol.

**Rusça:** Yanıtta İngilizce kelime kaçtıysa:
```python
re.search(r'[a-zA-Z]{4,}', response)  # 4+ Latin karakter → karışım
```

**Çince:** `\u4e00-\u9fff` aralığı dışında karakter yüzdesi kontrolü:
```python
chinese_chars = len(re.findall(r'[\u4e00-\u9fff]', response))
total_chars = len(response.replace(" ", ""))
if chinese_chars / total_chars < 0.5:  # %50'den az Çince → karışım
    # retry veya fallback
```

---

## 🔧 Somut Kod Değişiklikleri

### 1. `prompts.py` — Dil bloğu dict'i ekle

```python
LANGUAGE_BLOCKS = {
    "tr": """## DİL KURALI — KESİN
- DAIMA Türkçe yanıt ver. İngilizce kelime kullanma YASAK.
- Teknik terimler: "conta", "supap", "buji", "sigorta", "akü".
- Rakam formatı: "9,2 volt", "2,5 bar".
- İngilizce ASLA kullanma — "fuse" değil "sigorta".""",

    "en": """## LANGUAGE RULE — STRICT
- ALWAYS reply in English. Never use non-English words.
- Use standard SAE automotive terminology.
- Number format: "9.2V", "2.5 bar".""",

    "ru": """## ЯЗЫКОВОЕ ПРАВИЛО — СТРОГО
- Отвечай ТОЛЬКО по-русски. Английские слова ЗАПРЕЩЕНЫ.
- Используй стандартную ГОСТ терминологию.
- Формат чисел: "9,2 вольт", "2,5 бар".""",

    "zh": """## 语言规则 — 严格
- 必须用中文回答。禁止使用英文单词。
- 使用标准汽车术语。
- 数字格式: "9.2伏特", "2.5巴"。""",
}
```

### 2. `game_handler.py` — `build_system_prompt(scenario, lang_code)` imzası

```python
# Eski
system_prompt = build_game_system_prompt(scenario)

# Yeni
lang_code = body.get("langCode", user.get("languageCode", "tr"))
system_prompt = build_game_system_prompt(scenario, lang_code=lang_code)
```

### 3. DynamoDB Users tablosu — Yeni alanlar

```python
user = {
    # ... mevcut alanlar ...
    "languageCode": "tr",        # string: tr, en, ru, zh-CN, zh-TW
    "languageSource": "profile",  # string: profile | auto
}
```

### 4. Output filtresi — Dil karışımı retry

```python
def validate_language(response: str, lang_code: str) -> tuple[bool, str]:
    """Yanıtın hedef dilde olup olmadığını kontrol et."""
    if lang_code == "tr":
        en_words = re.findall(r'\b[a-zA-Z]{4,}\b', response)
        tr_exceptions = {"PSI", "bar", "rpm", "OBD", "ABS", "ATF", "LPG"}
        real_en = [w for w in en_words if w.upper() not in tr_exceptions]
        if len(real_en) > 3:
            return False, "Dil karışımı tespit edildi"
    elif lang_code == "ru":
        if re.search(r'[a-zA-Z]{4,}', response):
            return False, "Языковая ошибка"
    elif lang_code.startswith("zh"):
        chinese = len(re.findall(r'[\u4e00-\u9fff]', response))
        total = len(response.replace(" ", ""))
        if total > 0 and chinese / total < 0.5:
            return False, "语言混合错误"
    return True, response
```

---

## ✅ Uygulama Sırası

1. **S05 fix** — `scenarios.py` protected_normal + `prompts.py` olmayan test kuralı
2. **S15 fix** — `prompts.py` key_clue sızıntı engeli + output filtresi
3. **S03 fix** — `prompts.py` dil kuralı güçlendirme
4. **S02/S10 fix** — `prompts.py` threshold düşürme
5. **Çoklu dil altyapısı** — `LANGUAGE_BLOCKS` dict + `game_handler.py` + DynamoDB
6. **Test tekrarı** — `python tester/auto_tester.py --rounds 10` ile doğrulama

---

## 🎯 Kabul Kriterleri (Düzeltme Sonrası)

Her düzeltmeden sonra `python tester/auto_tester.py --rounds 10` çalıştırılacak.
Aşağıdaki eşikleri geçemeyen senaryo **lansman engelleyici** sayılır.

| Senaryo | Şu An | Hedef PASS | Hedef Hal. | Eşik |
|---------|--------|------------|------------|------|
| **S05** (Klima) | 0/10 | **≥ 8/10** | ≤ 2/10 | Kritik — uydurma parça sıfıra yakın olmalı |
| **S15** (LPG) | 0/10 | **≥ 8/10** | ≤ 2/10 | Kritik — ipucu sızıntısı sıfıra yakın olmalı |
| **S03** (Far) | 3/10 | **≥ 9/10** | Dil karışımı ≤ 1/10 | Dil kuralı güçlendirme sonrası |
| **S02** (Starter) | 9/10 | **10/10** | Sızıntı 0/10 | Stres altında kök neden sızdırmamalı |
| **S10** (O2 Sensör) | 9/10 | **10/10** | Sızıntı 0/10 | Stres altında kök neden sızdırmamalı |
| **S04** (Silecek) | 8/10 | **10/10** | 0/10 | protected_normal ihlali sıfır olmalı |
| S01,S06-S09,S11-S14 | 10/10 | **10/10** | 0/10 | Regresyon olmamalı |

### Genel Hedef

| Metrik | Şu An | Hedef | Lansman Engelleyici |
|--------|--------|-------|---------------------|
| Genel PASS oranı | %79.3 (119/150) | **≥ %95** (≥ 142/150) | Evet — altında yayınlanmaz |
| Toplam halüsinasyon | 31/150 | **≤ 8/150** (≤ %5.3) | Evet |
| Kritik halüsinasyon (Uydurma Parça) | 22 | **≤ 3** | Evet |
| Yanlış Teşhis (kök neden sızıntısı) | 2 | **0** | Evet |
| Dil Karışımı | 7 | **≤ 2** | Hayır (ama düzeltilmeli) |

### Doğrulama Komutu

```bash
# Düzeltme sonrası tam test
python tester/auto_tester.py --rounds 10

# Sadece düzeltilen senaryoları hızlı kontrol
python tester/auto_tester.py --scenario S05 --rounds 10
python tester/auto_tester.py --scenario S15 --rounds 10
python tester/auto_tester.py --scenario S03 --rounds 10
```

> [!IMPORTANT]
> Eğer düzeltme sonrası S01,S06-S09,S11-S14 senaryolarından herhangi biri PASS oranını düşürürse → **regresyon** var demektir. Düzeltmeyi geri al ve kök nedeni araştır.
