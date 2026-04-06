import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  // ── Hint: İpucu (💡) ──────────────────────────────────────────────────────
  void _handleHintText(BuildContext context) {
    if (!context.read<GameProvider>().useHintText()) {
      _showAdOrCostDialog(context, jokerType: 1, coinCost: 50, adCount: 1,
          jokerName: 'İpucu', jokerEmoji: '💡');
    }
  }

  // ── Hint: Yarıya İndir (½) ────────────────────────────────────────────────
  void _handleEliminate(BuildContext context) {
    final g = context.read<GameProvider>();
    if (g.eliminatedOptions.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu joker bu soru için zaten kullanıldı!')));
      return;
    }
    if (!g.useHintEliminate()) {
      _showAdOrCostDialog(context, jokerType: 2, coinCost: 120, adCount: 2,
          jokerName: 'Yarıya İndir', jokerEmoji: '½');
    }
  }

  // ── Hint: Cevabı Göster (👁) ──────────────────────────────────────────────
  void _handleReveal(BuildContext context) {
    final g = context.read<GameProvider>();
    if (g.isAnswerRevealed) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cevap zaten gösteriliyor!')));
      return;
    }
    if (!g.useHintReveal()) {
      _showAdOrCostDialog(context, jokerType: 3, coinCost: 500, adCount: 3,
          jokerName: 'Cevabı Göster', jokerEmoji: '👁');
    }
  }

  /// Yetersiz altın → reklam veya altınla satın al seçimi
  void _showAdOrCostDialog(BuildContext context,
      {required int jokerType, required int coinCost, required int adCount,
       required String jokerName, required String jokerEmoji}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$jokerEmoji $jokerName'),
        content: Text(
            'Yeterli altın yok! ($coinCost altın gerekli)\n\n'
            'Reklam izleyerek bu jokeri ücretsiz kullanabilirsin ($adCount reklam).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _watchAdsForJoker(context, jokerType: jokerType, adCount: adCount,
                  jokerName: jokerName);
            },
            icon: const Icon(Icons.play_circle, size: 18),
            label: Text('$adCount Reklam İzle'),
          ),
        ],
      ),
    );
  }

  /// adCount kadar sıralı reklam göster, sonra jokeri uygula  
  void _watchAdsForJoker(BuildContext context,
      {required int jokerType, required int adCount, required String jokerName}) {
    _showSequentialAds(context, remaining: adCount, total: adCount, jokerType: jokerType, jokerName: jokerName);
  }

  void _showSequentialAds(BuildContext context,
      {required int remaining, required int total, required int jokerType, required String jokerName}) {
    if (remaining <= 0) {
      // Tüm reklamlar izlendi → jokeri ver
      context.read<GameProvider>().addJokerStock(jokerType);
      // Hemen uygula
      switch (jokerType) {
        case 1: context.read<GameProvider>().useHintText(); break;
        case 2: context.read<GameProvider>().useHintEliminate(); break;
        case 3: context.read<GameProvider>().useHintReveal(); break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$jokerName jokeri kazanıldı! ✅')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_fill, size: 64, color: Color(0xFF5543CF)),
            const SizedBox(height: 16),
            Text('Reklam ${total - remaining + 1}/$total',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Reklam simüle ediliyor...', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('(Gerçek uygulamada AdMob reklamı oynar)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSequentialAds(context,
                  remaining: remaining - 1, total: total, jokerType: jokerType, jokerName: jokerName);
            },
            child: const Text('Reklamı Geç →'),
          ),
        ],
      ),
    );
  }

  void _showRewardedAdForCoins(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.play_circle_fill, size: 64, color: Color(0xFF5543CF)),
            SizedBox(height: 16),
            Text('Reklam simüle ediliyor...', textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text('(Gerçek uygulamada AdMob reklamı oynar)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.read<GameProvider>().rewardCoinsFromAd(50);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('+50 altın kazandın!')));
            },
            child: const Text('Ödül Al (+50 Altın)'),
          ),
        ],
      ),
    );
  }

  /// Yanlış cevap → "Cevabı Gör" — önce reklam, sonra cevabı göster
  void _handleShowAnswerAfterAd(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.play_circle_fill, size: 64, color: Color(0xFF5543CF)),
            SizedBox(height: 16),
            Text('Doğru cevabı görmek için reklam izlemen gerekiyor.',
              textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text('(Gerçek uygulamada AdMob reklamı oynar)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GameProvider>().revealAnswerFree();
            },
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('Cevabı Gör'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: Consumer<GameProvider>(
        builder: (context, gameData, child) {
          if (gameData.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Level Complete Summary ─────────────────────────────────────────
          if (gameData.isLevelComplete) {
            return _buildLevelComplete(context, gameData);
          }

          if (gameData.questions.isEmpty || gameData.currentQuestion == null) {
            return const Center(child: Text('Soru bulunamadı.'));
          }

          final question = gameData.currentQuestion!;

          return SafeArea(
            child: Column(
              children: [
                // ── Emoji Card ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        blurRadius: 20, offset: const Offset(0, 8),
                      )],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Konu: ${question.category}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold, fontSize: 13,
                              color: Theme.of(context).colorScheme.primary)),
                        ),
                        const SizedBox(height: 12),
                        Text(question.emojis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 48, letterSpacing: 6)),
                        if (gameData.hintText.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5543CF).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF5543CF).withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb, color: Color(0xFF5543CF), size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(gameData.hintText,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12, color: const Color(0xFF5543CF),
                                    fontWeight: FontWeight.w500))),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Progress + Score ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Soru ${gameData.currentIndex + 1} / ${gameData.questions.length}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text('${gameData.score}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Options ───────────────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: question.options.length,
                    itemBuilder: (context, index) {
                      final option = question.options[index];
                      final isEliminated = gameData.eliminatedOptions.contains(option);
                      final isCorrect = option == question.correctAnswer;
                      final isRevealed = gameData.isAnswerRevealed && isCorrect;
                      final isWrong = gameData.lastWrongAnswer == option;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildOptionButton(context, option, ['A', 'B', 'C', 'D'][index],
                          isEliminated, isRevealed, isWrong),
                      );
                    },
                  ),
                ),

                // ── Joker Bottom Bar ──────────────────────────────────────────
                _buildJokerBar(context, gameData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelComplete(BuildContext context, GameProvider gameData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, val, child) => Opacity(opacity: val, child: child),
              child: const Text('🏆', style: TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 24),
            Text(gameData.isDailyTask ? 'Günlük Görev Tamamlandı!' : 'Seviye Tamamlandı!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _scoreLine(context, 'Toplam Puan', '${gameData.score}', Icons.star_rounded),
                  const SizedBox(height: 12),
                  _scoreLine(context, 'Kazanılan Altın', '+${gameData.questions.length * 5}',
                      Icons.monetization_on),
                  if (!gameData.isDailyTask) ...[
                    const SizedBox(height: 12),
                    _scoreLine(context, 'Yeni Seviye', '${gameData.level}', Icons.trending_up),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (gameData.isDailyTask) {
                    Navigator.pop(context);
                  } else {
                    context.read<GameProvider>().nextQuestion();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: Icon(gameData.isDailyTask ? Icons.home : Icons.play_arrow),
                label: Text(gameData.isDailyTask ? 'Ana Ekrana Dön' : 'Sonraki Bölüm',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreLine(BuildContext context, String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ]),
        Text(value,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
      ],
    );
  }

  Widget _buildJokerBar(BuildContext context, GameProvider gameData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildJokerButton(context: context, label: '💡', cost: '50',
            tooltip: 'İpucu Göster', isUsed: gameData.hintText.isNotEmpty,
            stock: gameData.hintStocks,
            onTap: () => _handleHintText(context)),
          _buildJokerButton(context: context, label: '½', labelIsText: true, cost: '120',
            tooltip: 'Yarıya İndir', isUsed: gameData.eliminatedOptions.isNotEmpty,
            stock: gameData.eliminateStocks,
            onTap: () => _handleEliminate(context)),
          _buildJokerButton(context: context, label: '👁', cost: '500',
            tooltip: 'Cevabı Göster', isUsed: gameData.isAnswerRevealed,
            stock: gameData.revealStocks,
            onTap: () => _handleReveal(context)),
          // Altın butonu
          _buildCoinButton(context, gameData),
        ],
      ),
    );
  }

  Widget _buildCoinButton(BuildContext context, GameProvider gameData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _showRewardedAdForCoins(context),
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1.5),
            ),
            child: const Center(child: Icon(Icons.monetization_on, color: Colors.amber, size: 24)),
          ),
        ),
        const SizedBox(height: 4),
        Text('${gameData.coins}',
          style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildJokerButton({
    required BuildContext context,
    required String label,
    bool labelIsText = false,
    required String cost,
    required String tooltip,
    required bool isUsed,
    required VoidCallback onTap,
    int stock = 0,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: isUsed ? null : onTap,
        child: Opacity(
          opacity: isUsed ? 0.4 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: isUsed
                          ? Colors.grey.withOpacity(0.15)
                          : primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUsed
                            ? Colors.grey.withOpacity(0.3)
                            : primary.withOpacity(0.3),
                        width: 1.5),
                    ),
                    child: Center(
                      child: labelIsText
                          ? Text(label, style: GoogleFonts.plusJakartaSans(
                              fontSize: 22, fontWeight: FontWeight.w900,
                              color: isUsed ? Colors.grey : primary))
                          : Text(label, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  // Stok rozeti
                  if (stock > 0)
                    Positioned(
                      top: -4, right: -4,
                      child: Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text('$stock',
                            style: const TextStyle(fontSize: 9, color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.monetization_on, size: 10, color: Colors.grey[500]),
                const SizedBox(width: 2),
                Text(cost,
                  style: TextStyle(
                    fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new,
            color: Theme.of(context).colorScheme.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Consumer<GameProvider>(
        builder: (context, gameData, child) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seviye ${gameData.level}',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18,
                    color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            // Puan göster
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${gameData.score}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, String text, String label,
      bool isEliminated, bool isRevealed, bool isWrong) {
    if (isEliminated) {
      return Opacity(opacity: 0.25,
          child: _buildOptionContainer(context, text, label, false, false));
    }
    return InkWell(
      onTap: () {
        final isCorrect = context.read<GameProvider>().checkAnswer(text);
        _showResultDialog(context, isCorrect);
      },
      borderRadius: BorderRadius.circular(14),
      child: _buildOptionContainer(context, text, label, isRevealed, isWrong),
    );
  }

  void _showResultDialog(BuildContext context, bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isCorrect ? Icons.check_circle : Icons.cancel, 
              size: 64, color: isCorrect ? Colors.green : Colors.red),
            const SizedBox(height: 16),
            Text(isCorrect ? 'Doğru Bildin! 🎉' : 'Yanlış Cevap 😔',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Text(isCorrect ? '+10 Puan kazanıldı' : '-5 Puan silindi',
              style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          if (!isCorrect)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _handleShowAnswerAfterAd(context);
              },
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Cevabı Gör (Reklamlı)'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GameProvider>().skipToNextQuestion();
            },
            child: const Text('Sonraki Soru'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionContainer(BuildContext context, String text, String label,
      bool isRevealed, bool isWrong) {
    Color bgColor = Theme.of(context).colorScheme.surfaceContainerLow;
    Color borderColor = Theme.of(context).colorScheme.primary.withOpacity(0.08);
    Color labelBg = Theme.of(context).colorScheme.surfaceContainerHighest;
    Color labelColor = Theme.of(context).colorScheme.primary;

    if (isRevealed) {
      bgColor = Colors.green.withOpacity(0.12);
      borderColor = Colors.green;
      labelBg = Colors.green.withOpacity(0.25);
      labelColor = Colors.green.shade800;
    } else if (isWrong) {
      bgColor = Colors.red.withOpacity(0.08);
      borderColor = Colors.red.withOpacity(0.5);
      labelBg = Colors.red.withOpacity(0.15);
      labelColor = Colors.red.shade700;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: labelBg, shape: BoxShape.circle),
            child: Center(child: Text(label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold, fontSize: 13, color: labelColor))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface))),
          if (isRevealed) const Icon(Icons.check_circle, color: Colors.green, size: 18),
          if (isWrong) const Icon(Icons.cancel, color: Colors.red, size: 18),
        ],
      ),
    );
  }
}
