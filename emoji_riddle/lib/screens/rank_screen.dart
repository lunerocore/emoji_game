import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class RankScreen extends StatefulWidget {
  const RankScreen({super.key});

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.fetchLeaderboard();
      if (!mounted) return;
      if (data.isNotEmpty) {
        setState(() { _leaderboard = data; _isLoading = false; });
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    // Fallback demo data
    setState(() {
      _leaderboard = [
        {'username': 'BilgeAdam', 'score': 1500, 'level': 15},
        {'username': 'Ustaaa', 'score': 1200, 'level': 12},
        {'username': 'CozucuX', 'score': 900, 'level': 9},
        {'username': 'BilmecePro', 'score': 850, 'level': 8},
        {'username': 'Gizemli42', 'score': 700, 'level': 7},
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('🏆 Sıralama',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
            onPressed: _fetchLeaderboard,
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchLeaderboard,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
              itemCount: _leaderboard.length,
              itemBuilder: (context, index) {
                final user = _leaderboard[index];
                final isTop3 = index < 3;
                final medal = index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isTop3
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18)
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: isTop3
                        ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Sıra
                      SizedBox(
                        width: 40,
                        child: medal != null
                          ? Text(medal, style: const TextStyle(fontSize: 24),
                              textAlign: TextAlign.center)
                          : Text('#${index + 1}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16, fontWeight: FontWeight.w900,
                                color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          (user['username'] ?? '?')[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['username'],
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('Seviye ${user['level']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text('${user['score']}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18, fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                          Text('puan', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }
}
