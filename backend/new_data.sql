INSERT INTO questions (emojis, correct_answer, category, hint, options) VALUES
-- Eş Anlamlı (Synonym)
('⬛ = ?', 'Kara', 'eş_anlamlı', 'Siyahın eş anlamlısı', '["Kara", "Ak", "Karanlık", "Koyu"]'),
('⬜ = ?', 'Ak', 'eş_anlamlı', 'Beyazın eş anlamlısı', '["Berrak", "Aydınlık", "Ak", "Temiz"]'),
('❤️ = ?', 'Yürek', 'eş_anlamlı', 'Kalbin eş anlamlısı', '["Sevgi", "Yürek", "Damar", "Kan"]'),
('🟥 = ?', 'Al', 'eş_anlamlı', 'Kırmızının eş anlamlısı', '["Kızıl", "Kan", "Bordo", "Al"]'),
('💸+😢 = ?', 'Yoksul', 'eş_anlamlı', 'Fakirin eş anlamlısı', '["Borçlu", "Dertli", "Yoksul", "Üzgün"]'),
('👦+🎒 = ?', 'Talebe', 'eş_anlamlı', 'Öğrencinin eş anlamlısı', '["Talebe", "Genç", "Çocuk", "Kursiyer"]'),
('🏫 = ?', 'Mektep', 'eş_anlamlı', 'Okulun eş anlamlısı', '["Kolej", "Bina", "Sınıf", "Mektep"]'),
('👨‍⚕️ = ?', 'Hekim', 'eş_anlamlı', 'Doktorun eş anlamlısı', '["Cerrah", "Hekim", "Sağlıkçı", "Uzman"]'),
('👴 = ?', 'Yaşlı', 'eş_anlamlı', 'İhtiyarın eş anlamlısı', '["Büyük", "Yaşlı", "Olgun", "Dede"]'),
('🧳+🚶‍♂️ = ?', 'Misafir', 'eş_anlamlı', 'Konuğun eş anlamlısı', '["Misafir", "Yolcu", "Turist", "Ziyaretçi"]'),

-- Zıt Anlamlı (Antonym)
('🔥 ↔️ ?', 'Soğuk', 'zıt_anlamlı', 'Sıcağın zıt anlamlısı', '["Buz", "Serin", "Soğuk", "Ilık"]'),
('☀️ ↔️ ?', 'Gece', 'zıt_anlamlı', 'Gündüzün zıt anlamlısı', '["Akşam", "Gece", "Ay", "Karanlık"]'),
('💰+💎 ↔️ ?', 'Ucuz', 'zıt_anlamlı', 'Pahalının zıt anlamlısı', '["Kalitesiz", "Basit", "Bedava", "Ucuz"]'),
('🏎️ ↔️ ?', 'Yavaş', 'zıt_anlamlı', 'Hızlının zıt anlamlısı', '["Ağır", "Durgun", "Sakin", "Yavaş"]'),
('🍔+🧍‍♂️ ↔️ ?', 'Zayıf', 'zıt_anlamlı', 'Şişmanın zıt anlamlısı', '["Zayıf", "İnce", "Cılız", "Kısa"]'),
('👶 ↔️ ?', 'İhtiyar', 'zıt_anlamlı', 'Gencin zıt anlamlısı', '["Büyük", "İhtiyar", "Dede", "Olgun"]'),
('⬆️ ↔️ ?', 'Aşağı', 'zıt_anlamlı', 'Yukarının zıt anlamlısı', '["Alt", "Aşağı", "Zemin", "Dip"]'),
('🧗‍♂️ ↔️ ?', 'Kolay', 'zıt_anlamlı', 'Zorun zıt anlamlısı', '["Basit", "Rahat", "Hafif", "Kolay"]'),
('📦+✨ ↔️ ?', 'Eski', 'zıt_anlamlı', 'Yeninin zıt anlamlısı', '["Tarihi", "Kullanılmış", "Eski", "Antika"]'),
('😢 ↔️ ?', 'Gülmek', 'zıt_anlamlı', 'Ağlamanın zıt anlamlısı', '["Sevinmek", "Gülmek", "Kahkaha", "Oynamak"]'),

-- Sesteş (Homonym)
('🏊‍♂️ + 💯 + 👤 = ?', 'Yüz', 'sesteş', 'Hem sayı, hem çehre, hem de suda yapılan yüzme eylemi.', '["Bin", "Kafa", "Yüz", "Su"]'),
('✍️ + ☀️ = ?', 'Yaz', 'sesteş', 'Hem mevsim, hem de kelimeleri kağıda geçirme eylemi.', '["Oku", "Bahar", "Sıcak", "Yaz"]'),
('🌹 + 😂 = ?', 'Gül', 'sesteş', 'Hem dikenli bir çiçek, hem de sevinç belirtisi gülümseme eylemi.', '["Çiçek", "Gül", "Mutlu", "Lale"]'),
('☕ + 🏞️ = ?', 'Çay', 'sesteş', 'Hem demlenip içilen içecek, hem de dereden büyük akarsu.', '["Nehir", "Kahve", "Çay", "Su"]'),
('🐎 + 🗑️ = ?', 'At', 'sesteş', 'Hem binek hayvanı, hem de bir şeyi fırlatıp yere fırlatma eylemi.', '["Koş", "Fırlat", "Eşek", "At"]'),
('🔨 + 🏞️ = ?', 'Kır', 'sesteş', 'Hem parçalama eylemi, hem de şehir dışı yeşillik alan.', '["Dağ", "Parçala", "Vazo", "Kır"]'),
('🦵 + 📚 = ?', 'Diz', 'sesteş', 'Hem bacak büküm yeri, hem de nesneleri sıraya koyma eylemi.', '["Bacak", "Sırala", "Diz", "Ayak"]'),
('🙋‍♂️ + 🟤 = ?', 'Ben', 'sesteş', 'Hem kendimiz, hem de vücuttaki ufak leke.', '["Sen", "Leke", "İz", "Ben"]'),
('👧 + 😠 = ?', 'Kız', 'sesteş', 'Hem dişi çocuk, hem de öfkelenmek eylemi.', '["Erkek", "Öfke", "Çocuk", "Kız"]'),
('🍳 + ❄️ = ?', 'Ocak', 'sesteş', 'Hem yemek pişirilen yer, hem de yılın ilk ayı.', '["Ateş", "Şubat", "Soba", "Ocak"]');
