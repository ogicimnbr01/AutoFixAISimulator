import json

translations = {
    "tr": {
        "editProfile": "Profili Düzenle",
        "enterNewName": "Yeni ismini gir",
        "saveSuccess": "Başarıyla güncellendi!",
        "save": "Kaydet"
    },
    "en": {
        "editProfile": "Edit Profile",
        "enterNewName": "Enter new name",
        "saveSuccess": "Successfully updated!",
        "save": "Save"
    },
    "ru": {
        "editProfile": "Редактировать профиль",
        "enterNewName": "Введите новое имя",
        "saveSuccess": "Успешно обновлено!",
        "save": "Сохранить"
    },
    "zh": {
        "editProfile": "编辑个人资料",
        "enterNewName": "输入新名称",
        "saveSuccess": "更新成功！",
        "save": "保存"
    }
}

for lang in translations:
    filepath = f"c:/Proje/Sanayi Ustasu/app/lib/l10n/app_{lang}.arb"
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    for k, v in translations[lang].items():
        data[k] = v
        
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

print("Done!")
