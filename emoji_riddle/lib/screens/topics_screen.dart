import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  final List<Map<String, dynamic>> topics = const [
    {'id': 'tümü',     'title': 'Tümü',         'icon': Icons.all_inclusive,     'color': Color(0xFF5543CF)},
    {'id': 'atasözü',  'title': 'Atasözleri',    'icon': Icons.menu_book,         'color': Color(0xFF006764)},
    {'id': 'deyim',    'title': 'Deyimler',      'icon': Icons.record_voice_over, 'color': Color(0xFFD97706)},
    {'id': 'özlü_söz', 'title': 'Özlü Sözler',  'icon': Icons.format_quote,      'color': Color(0xFFBE185D)},
    {'id': 'eş_anlamlı', 'title': 'Eş Anlamlı', 'icon': Icons.swap_horiz, 'color': Color(0xFF1E3A8A)},
    {'id': 'zıt_anlamlı', 'title': 'Zıt Anlamlı', 'icon': Icons.compare_arrows, 'color': Color(0xFFB91C1C)},
    {'id': 'sesteş', 'title': 'Sesteş', 'icon': Icons.hearing, 'color': Color(0xFF047857)},
  ];

  @override
  Widget build(BuildContext context) {
    final gameData = context.read<GameProvider>();
    final currentId = gameData.selectedCategory;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Konu Seç',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bir Kategori Seç',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('İstediğin konuda bilmeceleri çözmeye başla.',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final t = topics[index];
                    final isSelected = currentId == t['id'] ||
                        (currentId == null && t['id'] == 'tümü');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        onTap: () {
                          // Kategoriyi kaydet, oyunu başlatma — ana ekrana dön
                          context.read<GameProvider>().setSelectedCategory(
                              t['id'] as String,
                              t['title'] as String);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (t['color'] as Color).withOpacity(0.12)
                                : Theme.of(context).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? (t['color'] as Color)
                                  : (t['color'] as Color).withOpacity(0.25),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (t['color'] as Color).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(t['icon'] as IconData,
                                    color: t['color'] as Color),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  t['title'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle,
                                    color: t['color'] as Color, size: 22)
                              else
                                Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
