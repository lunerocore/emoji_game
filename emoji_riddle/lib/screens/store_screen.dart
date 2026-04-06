import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mağaza',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28, fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text('Atasözlerini çözmek için ihtiyacın her şey burada.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13)),
                    const SizedBox(height: 28),
                    _sectionLabel(context, 'ÖNE ÇIKANLAR'),
                    const SizedBox(height: 12),
                    _buildHeroCard(context),
                    const SizedBox(height: 28),
                    _sectionLabel(context, 'ALTIN PAKETLERİ'),
                    const SizedBox(height: 12),
                    _buildGoldPackages(context),
                    const SizedBox(height: 28),
                    _sectionLabel(context, 'JOKERLER — ALTIN İLE'),
                    const SizedBox(height: 12),
                    _buildHelpers(context, useAd: false),
                    const SizedBox(height: 28),
                    _sectionLabel(context, 'JOKERLER — REKLAM İLE ÜCRETSİZ'),
                    const SizedBox(height: 4),
                    Text('Reklam izleyerek joker kazan!',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 12),
                    _buildHelpers(context, useAd: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameData, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text('Mağaza',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold, fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
              Row(
                children: [
                  // Puan
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                        const SizedBox(width: 4),
                        Text('${gameData.score}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold, color: Colors.amber[800], fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Altın
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFF5543CF), size: 15),
                        const SizedBox(width: 4),
                        Text('${gameData.coins}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold, color: const Color(0xFF5543CF), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(BuildContext context, String title) {
    return Row(
      children: [
        Container(width: 4, height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.primary)),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5543CF), Color(0xFF7B6EF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('🎁', style: TextStyle(fontSize: 36))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aylık Premium Paket',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: ['Sınırsız Reklamsız', '15x Tüm Jokerler', '1000 Altın'].map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(tag,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _handlePremiumPurchase(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5543CF),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('99.99 TRY / Ay',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldPackages(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildGoldCard(context, '100 Altın', 'Bronz Kese', '\u{1F4B0}', '19.99 TRY', false)),
        const SizedBox(width: 12),
        Expanded(child: _buildGoldCard(context, '500 Altın', 'Gümüş Sandık', '\u{1F48E}', '79.99 TRY', true)),
      ],
    );
  }

  Widget _buildGoldCard(BuildContext context, String title, String subtitle,
      String emoji, String price, bool isPopular) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: isPopular
            ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20)),
              child: const Text('Popüler',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handlePurchase(context, title),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                foregroundColor: isPopular
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(price,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpers(BuildContext context, {required bool useAd}) {
    final jokers = [
      {
        'emoji': '💡', 'title': 'İpucu Jokeri',
        'desc': 'Emojilerin anlamıyla ilgili ipucu metni gösterir',
        'cost': 50, 'adCount': 1, 'badge': 'JOKER 1', 'type': 1,
        'emojiIsText': false,
      },
      {
        'emoji': '½', 'title': 'Yarıya İndir',
        'desc': '2 yanlış seçeneği siler, tahmin şansın artar',
        'cost': 120, 'adCount': 2, 'badge': 'JOKER 2', 'type': 2,
        'emojiIsText': true,
      },
      {
        'emoji': '👁', 'title': 'Cevabı Göster',
        'desc': 'Doğru seçeneği yeşil ile işaretler',
        'cost': 500, 'adCount': 3, 'badge': 'JOKER 3', 'type': 3,
        'emojiIsText': false,
      },
    ];

    return Column(
      children: jokers.map((j) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildHelperItem(context, joker: j, useAd: useAd),
        );
      }).toList(),
    );
  }

  Widget _buildHelperItem(BuildContext context,
      {required Map<String, dynamic> joker, required bool useAd}) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 1.5)),
            child: Center(
              child: joker['emojiIsText'] == true
                ? Text(joker['emoji'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20, fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary))
                : Text(joker['emoji'], style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(joker['title'],
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(joker['badge'],
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary, letterSpacing: 0.5)),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(joker['desc'], style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          useAd
            ? _buildAdButton(context, joker)
            : _buildCoinButton(context, joker),
        ],
      ),
    );
  }

  Widget _buildCoinButton(BuildContext context, Map<String, dynamic> joker) {
    return ElevatedButton.icon(
      onPressed: () {
        final success = context.read<GameProvider>().buyItem(joker['cost']);
        if (success) {
          context.read<GameProvider>().addJokerStock(joker['type'] as int);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? '${joker['title']} kazanıldı! ✅'
              : 'Yetersiz altın!'),
        ));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        foregroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.monetization_on, size: 14),
      label: Text('${joker['cost']}',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildAdButton(BuildContext context, Map<String, dynamic> joker) {
    final adCount = joker['adCount'] as int;
    return ElevatedButton.icon(
      onPressed: () => _watchAdsForJoker(context,
          jokerType: joker['type'] as int,
          adCount: adCount,
          jokerName: joker['title'] as String),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrange.withOpacity(0.1),
        foregroundColor: Colors.deepOrange,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.play_circle, size: 14),
      label: Text('$adCount 📺',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  void _watchAdsForJoker(BuildContext context,
      {required int jokerType, required int adCount, required String jokerName}) {
    _showSequentialAds(context,
        remaining: adCount, jokerType: jokerType, jokerName: jokerName, total: adCount);
  }

  void _showSequentialAds(BuildContext context,
      {required int remaining, required int jokerType, required String jokerName, required int total}) {
    if (remaining <= 0) {
      context.read<GameProvider>().addJokerStock(jokerType);
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
            Text('$jokerName için reklam izleniyor...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 4),
            const Text('(Gerçek uygulamada AdMob reklamı oynar)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSequentialAds(context,
                  remaining: remaining - 1,
                  jokerType: jokerType,
                  jokerName: jokerName,
                  total: total);
            },
            child: Text(remaining > 1 ? 'Sonraki Reklam →' : 'Ödülü Al ✅'),
          ),
        ],
      ),
    );
  }

  void _handlePurchase(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$item satın alındı (simülasyon).')));
  }

  void _handlePremiumPurchase(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen önce giriş yapın!')));
      return;
    }
    
    // Simüle satın alma dialogu veya ödeme gecikmesi
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Premium işlem sürüyor...')));
    
    final success = await auth.subscribePremium();
    if (success) {
      final g = context.read<GameProvider>();
      g.rewardCoinsFromAd(1000);
      g.addJokerStock(1, count: 15);
      g.addJokerStock(2, count: 15);
      g.addJokerStock(3, count: 15);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aylık Premium Paket Aktif! 🎉')));
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata oluştu!')));
    }
  }
}
