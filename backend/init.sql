CREATE TABLE IF NOT EXISTS questions (
    id SERIAL PRIMARY KEY,
    emojis VARCHAR(255) NOT NULL,
    correct_answer VARCHAR(255) NOT NULL,
    category VARCHAR(50) DEFAULT 'atasözü',
    hint TEXT,
    options JSONB NOT NULL
);

INSERT INTO questions (emojis, correct_answer, category, hint, options) VALUES
('🧠 + 🧠 + ⬆️', 'Akıl akıldan üstündür', 'atasözü', 'Birinin çözemediği sorunu başkası kolayca çözebilir.', '["Akıl yaşta değil baştadır", "Akıl akıldan üstündür", "Aklın yolu birdir", "Delilikle dahilik arasında ince bir çizgi vardır"]'),
('💧 + 💧 + 🏞️', 'Damlaya damlaya göl olur', 'atasözü', 'Küçük birikimler zamanla büyük kazançlara dönüşür.', '["Taşıma suyla değirmen dönmez", "Su uyur düşman uyumaz", "Damlaya damlaya göl olur", "Su verenlerin çok olsun"]'),
('🌹 + ❤️ + 🌵', 'Gülü seven dikenine katlanır', 'atasözü', 'Güzel bir şeyi elde etmek isteyen, onun zorluklarına da katlanmalıdır.', '["Gülme komşuna gelir başına", "Gülü seven dikenine katlanır", "Dikensiz gül olmaz", "Sevenin halinden seven anlar"]'),
('🌾 + 📦 + ⏳', 'Sakla samanı gelir zamanı', 'atasözü', 'Değersiz görünen şeyler gün gelir işe yarar.', '["Zaman sana uymazsa sen zamana uy", "Sakla samanı gelir zamanı", "Vakit nakittir", "Bugünün işini yarına bırakma"]'),
('👁️ + 👁️ + 🦷 + 🦷', 'Göze göz dişe diş', 'deyim', 'Yapılan bir kötülüğe aynı şekilde karşılık vermek.', '["Gözden ırak olan gönülden de ırak olur", "Göz var nizam var", "Göze göz dişe diş", "Göz görmeyince gönül katlanır"]'),
('🍎 + 🌳 + 🍂', 'Meyve veren ağaç taşlanır', 'atasözü', 'Başarılı ve işe yarayan kişiler sürekli eleştirilir.', '["Ağaç yaşken eğilir", "Meyve veren ağaç taşlanır", "Her ağacın meyvesi yenmez", "Diktiğin ağacın meyvesini yersin"]'),
('🐢 + 🐇 + 🏁', 'Yavaş giden yolu kaybetmez', 'deyim', 'Adımlarını sağlam ve yavaş atan kişi hata yapmaz.', '["Acele işe şeytan karışır", "Yavaş giden yolu kaybetmez", "Sabır acıdır meyvesi tatlıdır", "Bekle beni gülüm bekle"]'),
('🐺 + 🗡️ + 🐺', 'Kurt kurdu yemez', 'atasözü', 'İnsanlar kendi türünden veya meslektaşlarına zarar vermezler.', '["İt iti ısırmaz", "Kurt kurdu yemez", "El eli yıkar", "Dost başa düşman ayağa bakar"]'),
('🏠 + 🔥 + 😤', 'Komşu komşunun külüne muhtaçtır', 'atasözü', 'İnsanlar ne kadar varlıklı olurlarsa olsunlar yakınlarına ihtiyaç duyarlar.', '["Ev alma komşu al", "Komşu komşunun külüne muhtaçtır", "Yakın komşu uzak akrabadan iyidir", "Komşusu yanmayan evsiz kalır"]'),
('💰 + 💰 + 💰 + 🤔', 'Para parayı çeker', 'atasözü', 'Ancak sermayesi olan büyük paralar kazanabilir.', '["Fakirin düğünü ya çok yağmur ya çok çamur", "Para parayı çeker", "Parayı veren düdüğü çalar", "Var güldürür yok ağlatır"]'),
('🌱 + ⏰ + 🌳', 'Ağaç yaşken eğilir', 'atasözü', 'İnsanlar ancak küçük yaşta kolay eğitilir.', '["Küçük büyüklere saygı gösterir", "Ağaç yaşken eğilir", "Her yaş kendine yazar", "Eğri büyümüş ağaç doğrulmaz"]'),
('🔑 + 🚪 + 💡', 'Her kapının bir anahtarı vardır', 'özlü_söz', 'Önümüze çıkan her zorluk için bir çözüm yolu mümkündür.', '["Arayan bulur", "Her kapının bir anahtarı vardır", "Çıkmazı olmayan yol yoktur", "Sabreden derviş muradına ermiş"]'),
('🌊 + 🪨 + ⏳', 'Damlayan su taşı deler', 'atasözü', 'Sürekli ve azimli çalışmak en aşılamaz engelleri bile aşar.', '["Yavaş yavaş ileri git", "Damlayan su taşı deler", "Israr eden elde eder", "Çalışmak ibadettir"]'),
('👂 + 🗣️ + 🔇', 'Az söyle çok dinle', 'özlü_söz', 'Sürekli konuşmaktan ziyade dinlemeyi ve öğrenmeyi tercih et.', '["İki kulak bir ağız", "Az söyle çok dinle", "Susan altın konuşan gümüştür", "Sözün güzeli kısası"]'),
('🤝 + 💪 + 🏆', 'El ele vermek dağ taşır', 'deyim', 'Birlikte çalışan ve dayanışan insanlar büyük zorlukları aşabilir.', '["Birlikten kuvvet doğar", "El ele vermek dağ taşır", "Tek elin sesi çıkmaz", "Güç birliği yapan galip gelir"]'),
('🐜 + 🌧️ + 🏠', 'İleriyi gören karıncadan öğren', 'atasözü', 'Geleceği düşünerek şimdiden hazırlanmak gerekir.', '["Akıllı dağı dolaşır", "İleriyi gören karıncadan öğren", "Yarını düşünen bugün hazırlanır", "Çalışkan hiç yorulmaz"]'),
('🎯 + 🏹 + 🎯', 'Bir taşla iki kuş vurmak', 'deyim', 'Tek bir davranış ile iki farklı hedefe aynı anda ulaşmak.', '["İki tavşana koşan birini de yakalayamaz", "Bir taşla iki kuş vurmak", "Çok iş güç durum", "Vurduğunu düşürmek"]'),
('🌙 + ⭐ + 🌙', 'Gece gündüze uymaz', 'özlü_söz', 'Zıtlıklar her zaman olacak, herkes her zaman aynı durumda kalamaz.', '["Her şeyin bir vakti var", "Gece gündüze uymaz", "Zıtlar birbirini tamamlar", "Karanlık olmadan ışık anlaşılmaz"]'),
('👀 + 🍲 + 🏃', 'Gözüm ısırıyor', 'deyim', 'Başkasıyla ilgisi yok; birisini bir yerden tanıdığını hissetmekte kullanılır.', '["Gözü gönlü tok", "Gözden ırak olan", "Göz kulak olmak", "Gözüm ısırıyor"]'),
('🗣️ + 🧵 + ✂️', 'İpe sapa gelmez', 'deyim', 'Söylenilen şeylerin hiçbir anlamı ve değeri olmadığını belirtir.', '["Laf ebesi", "Çene çalmak", "İpe sapa gelmez", "Laf yetiştirmek"]');

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    device_id VARCHAR(255),
    score INT DEFAULT 0,
    level INT DEFAULT 1,
    coins INT DEFAULT 500,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (username, score, level, coins) VALUES
('BilgeAdam', 1500, 15, 2000),
('Ustaaa', 1200, 12, 1400),
('CozucuX', 900, 9, 800),
('BilmeceKralı', 850, 8, 700),
('Gizemli42', 700, 7, 500);
