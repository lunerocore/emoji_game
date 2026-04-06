import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'game_screen.dart';
import 'duel_screen.dart';
import 'topics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _dailyProverb;

  @override
  void initState() {
    super.initState();
    _loadDailyProverb();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<GameProvider>().loadUserData(auth.user!);
      }
    });
  }

  Future<void> _loadDailyProverb() async {
    final data = await _apiService.fetchDailyProverb();
    if (mounted) {
      setState(() {
        _dailyProverb = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Background Decorators
          Positioned(
            top: 100, left: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHeroProverb(context),
                        const SizedBox(height: 40),
                        _buildPlaySection(context),
                        const SizedBox(height: 40),
                        _buildQuickAccessGrid(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Consumer<GameProvider>(
        builder: (context, gameData, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar & Titles
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            width: 2),
                      ),
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bilmece',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold, fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Usta Çözücü',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('SEVİYE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8, fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                        letterSpacing: 2,
                      )),
                    const SizedBox(width: 6),
                    Text('${gameData.level}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Score (puan — mevcut puan)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('${gameData.score}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900, color: Colors.amber[800],
                      )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroProverb(BuildContext context) {
    if (_dailyProverb == null) {
      return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
    }

    String categoryText = 'GÜNÜN ${_dailyProverb!['category']}'.toUpperCase();
    categoryText = categoryText.replaceAll('ÖZLÜ_SÖZ', 'ÖZLÜ SÖZÜ');
    categoryText = categoryText.replaceAll('ATASÖZÜ', 'ATASÖZÜ');
    categoryText = categoryText.replaceAll('DEYİM', 'DEYİMİ');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceContainerLow,
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 4, height: 16, decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    )),
                    const SizedBox(width: 8),
                    Text(categoryText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2,
                        color: Theme.of(context).colorScheme.primary,
                      )),
                  ],
                ),
                const SizedBox(height: 14),
                Text(_dailyProverb!['text'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.3,
                  )),
                if (_dailyProverb!['hint'] != null && _dailyProverb!['hint'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_dailyProverb!['hint'],
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    )),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6),
              )],
            ),
            child: Center(
              child: Text(
                _dailyProverb!['emojis'].split('+')[0].trim(),
                style: const TextStyle(fontSize: 32))
            ),
          ),
        ],
      ),
    );
  }

  /// Oyna butonu + altında konular chip'i
  Widget _buildPlaySection(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameData, child) {
        final topicTitle = gameData.selectedCategoryTitle ?? 'Tümü';
        final topicId = gameData.selectedCategory ?? 'tümü';

        // Map renkler
        const topicColors = {
          'tümü': Color(0xFF5543CF),
          'atasözü': Color(0xFF006764),
          'deyim': Color(0xFFD97706),
          'özlü_söz': Color(0xFFBE185D),
        };
        final chipColor = topicColors[topicId] ?? const Color(0xFF5543CF);

        return Column(
          children: [
            // ── Büyük Oyna Butonu ──
            GestureDetector(
              onTap: () {
                context.read<GameProvider>().fetchQuestions();
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const GameScreen()));
              },
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5543CF), Color(0xFF9E93FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF5543CF).withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 56),
                    Text('OYNA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 4,
                      )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Konular Chip ── (Oyna'nın altında)
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const TopicsScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: chipColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: chipColor.withOpacity(0.35), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category_rounded, color: chipColor, size: 16),
                    const SizedBox(width: 6),
                    Text(topicTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: chipColor,
                      )),
                    const SizedBox(width: 6),
                    Icon(Icons.keyboard_arrow_down_rounded, color: chipColor, size: 16),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameData, child) {
        final dailyDone = gameData.dailyTaskCompleted;
        
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: dailyDone ? null : () {
                  gameData.fetchDailyQuestions();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
                },
                child: Opacity(
                  opacity: dailyDone ? 0.5 : 1.0,
                  child: _buildBentoCard(
                    context,
                    title: dailyDone ? 'Yapıldı' : 'Görev',
                    subtitle: 'GÜNLÜK',
                    icon: dailyDone ? Icons.check_circle : Icons.event_available,
                    iconColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showDialog(context: context, builder: (_) => const DuelEntryDialog());
                },
                child: _buildBentoCard(
                  context,
                  title: 'Düello',
                  subtitle: 'YARIŞMA',
                  icon: Icons.sports_martial_arts,
                  iconColor: const Color(0xFF006764),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBentoCard(BuildContext context,
      {required String title, required String subtitle, required IconData icon, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                )),
              const SizedBox(height: 2),
              Text(title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                )),
            ],
          ),
          Icon(icon, color: iconColor, size: 28),
        ],
      ),
    );
  }
}
