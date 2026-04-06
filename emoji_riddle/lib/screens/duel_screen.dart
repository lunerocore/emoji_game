import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../providers/auth_provider.dart';

class DuelScreen extends StatefulWidget {
  final bool isCreator;
  final String? roomCode;
  final String? category;

  const DuelScreen({super.key, required this.isCreator, this.roomCode, this.category});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> with TickerProviderStateMixin {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // Connection state
  String _status = 'Bağlanıyor...';
  bool _connected = false;
  bool _connecting = true;

  // Room
  String? _myRoomCode;
  List<dynamic> _players = [];

  // Game states
  bool _gameStarted = false;
  bool _gameOver = false;
  String? _winnerName;
  Timer? _timer;
  int _timeLeft = 30;

  // Current question
  String? _questionEmojis;
  String? _questionCategory;
  List<String> _questionOptions = [];
  int _currentQ = 0;
  int _totalQ = 0;

  // Answer state
  String? _myAnswer;       // what I tapped
  bool? _myAnswerCorrect;  // revealed after round
  bool _roundResolved = false;
  String? _correctAnswer;  // revealed after round
  List<dynamic> _roundScores = [];

  // Timer
  late AnimationController _timerAnimCtrl;

  // Result screen anim
  bool _showingResult = false;

  @override
  void initState() {
    super.initState();
    _timerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _connectSocket();
  }

  Future<void> _connectSocket() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:3000/ws'));
      await _channel!.ready;
      if (!mounted) return;
      setState(() { _connected = true; _connecting = false; });

      _subscription = _channel!.stream.listen(
        (msg) { if (mounted) _handleMessage(msg); },
        onError: (_) { if (mounted) setState(() { _connected = false; _status = 'Bağlantı hatası.'; }); },
        onDone: () { if (mounted) setState(() { _connected = false; _status = 'Bağlantı koptu.'; }); },
      );

      final username = context.read<AuthProvider>().user?['username'] ?? 'Misafir';
      if (widget.isCreator) {
        _channel!.sink.add(jsonEncode({
          'type': 'create_room',
          'username': username,
          'category': widget.category ?? 'tümü',
        }));
      } else if (widget.roomCode != null) {
        _channel!.sink.add(jsonEncode({
          'type': 'join_room',
          'code': widget.roomCode,
          'username': username,
        }));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _connecting = false; _connected = false; _status = 'Bağlantı kurulamadı.'; });
    }
  }

  void _handleMessage(dynamic raw) {
    Map<String, dynamic> msg;
    try { msg = jsonDecode(raw as String); } catch (_) { return; }

    setState(() {
      switch (msg['type']) {
        case 'room_created':
          _myRoomCode = msg['code'];
          _status = 'Oda oluşturuldu. Rakip bekleniyor...';
          break;

        case 'player_joined':
          _players = msg['players'];
          _status = '${_players.length} oyuncu hazır.';
          break;

        case 'game_start':
          _players = msg['players'];
          _gameStarted = true;
          _totalQ = msg['totalQuestions'] ?? 5;
          _status = 'Oyun başlıyor!';
          break;

        case 'question':
          _questionEmojis = msg['emojis'];
          _questionCategory = msg['category'] ?? 'Genel';
          _questionOptions = List<String>.from(msg['options'] ?? []);
          _currentQ = (msg['questionIndex'] ?? 0) + 1;
          _totalQ = msg['totalQuestions'] ?? _totalQ;
          _myAnswer = null;
          _myAnswerCorrect = null;
          _roundResolved = false;
          _correctAnswer = null;
          _roundScores = [];
          _showingResult = false;
          _startTimer(msg['timeLimit'] ?? 30);
          break;

        case 'answer_received':
          // Server acknowledged our answer, wait for round_result
          break;

        case 'round_result':
          _stopTimer();
          _correctAnswer = msg['correctAnswer'];
          _roundScores = msg['scores'] ?? [];
          _roundResolved = true;
          _showingResult = true;
          // Check if my answer was correct
          final me = context.read<AuthProvider>().user?['username'] ?? 'Misafir';
          final myScore = (_roundScores as List).firstWhere(
              (s) => s['username'] == me, orElse: () => null);
          _myAnswerCorrect = myScore?['answeredCorrect'];
          break;

        case 'next_question':
          _showingResult = false;
          _status = 'Sıradaki soru geliyor...';
          break;

        case 'game_over':
          _stopTimer();
          _gameOver = true;
          _winnerName = msg['winner'];
          _players = msg['scores'];
          _status = 'OYUN BİTTİ!';
          // Show end-of-game ad
          WidgetsBinding.instance.addPostFrameCallback((_) => _showEndGameAd());
          break;

        case 'player_left':
          _status = msg['message'];
          break;

        case 'error':
          _status = msg['message'];
          break;
      }
    });
  }

  void _startTimer(int seconds) {
    _stopTimer();
    _timeLeft = seconds;
    _timerAnimCtrl.value = 1.0;
    _timerAnimCtrl.animateTo(0.0, duration: Duration(seconds: seconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) { t.cancel(); }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerAnimCtrl.stop();
  }

  void _submitAnswer(String answer) {
    if (_myAnswer != null || _roundResolved) return; // already answered
    setState(() => _myAnswer = answer);

    final code = _myRoomCode ?? widget.roomCode;
    if (code == null || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'submit_answer',
      'code': code,
      'answer': answer,
    }));
  }

  void _showEndGameAd() {
    if (!mounted) return;
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
            Text('Düello Sonu Reklamı',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Teşekkürler! Harika bir düello oldu.',
              textAlign: TextAlign.center),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopTimer();
    _timerAnimCtrl.dispose();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('⚔️ Düello Modu',
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
        child: _connecting
          ? const Center(child: CircularProgressIndicator())
          : !_connected
            ? _buildOfflineState()
            : _gameOver
              ? _buildGameOver()
              : _gameStarted
                ? _buildGameArea()
                : _buildLobby(),
      ),
    );
  }

  // ── LOBBY ─────────────────────────────────────────────────────────────────
  Widget _buildLobby() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(_status, textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
          ),

          if (_myRoomCode != null && _players.length < 2) ...[
            const SizedBox(height: 40),
            Text('Arkadaşına bu kodu gönder:',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5543CF), Color(0xFF9E93FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF5543CF).withOpacity(0.3),
                  blurRadius: 20, offset: const Offset(0, 8),
                )],
              ),
              child: SelectableText(_myRoomCode!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 40, fontWeight: FontWeight.w900,
                  letterSpacing: 12, color: Colors.white)),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            const Text('Rakip bekleniyor...'),
          ],

          if (_players.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildPlayerCards(),
          ],
        ],
      ),
    );
  }

  // ── GAME AREA ─────────────────────────────────────────────────────────────
  Widget _buildGameArea() {
    if (_questionEmojis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Skor bar
          _buildPlayerCards(),
          const SizedBox(height: 16),

          // İlerleme & Timer
          Row(
            children: [
              Text('Soru $_currentQ / $_totalQ',
                style: TextStyle(fontSize: 12, color: Colors.grey[600],
                    fontWeight: FontWeight.w700)),
              const Spacer(),
              _buildTimer(),
            ],
          ),
          const SizedBox(height: 12),

          // Round result banner
          if (_roundResolved && _correctAnswer != null)
            _buildRoundResultBanner(),

          if (!_roundResolved) ...[
            // Emoji Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                    Theme.of(context).colorScheme.surfaceContainerLow,
                  ],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  blurRadius: 20, offset: const Offset(0, 8),
                )],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Konu: ${_questionCategory ?? "Tümü"}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold, fontSize: 13,
                        color: Theme.of(context).colorScheme.primary)),
                  ),
                  const SizedBox(height: 12),
                  Text(_questionEmojis!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 48, letterSpacing: 6)),
                  if (_myAnswer != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hourglass_top, color: Colors.orange, size: 14),
                          const SizedBox(width: 6),
                          Text('Cevabın gönderildi, rakip bekleniyor...',
                            style: TextStyle(color: Colors.orange[800], fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Options
            ..._questionOptions.asMap().entries.map((e) {
              final idx = e.key;
              final opt = e.value;
              final isSelected = _myAnswer == opt;
              final isAnswered = _myAnswer != null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: isAnswered ? null : () => _submitAnswer(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                          : Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary.withOpacity(0.08),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(['A', 'B', 'C', 'D'][idx],
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold, fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(opt,
                          style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface))),
                        if (isSelected)
                          const Icon(Icons.check_circle_outline,
                              color: Color(0xFF5543CF), size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final isLow = _timeLeft <= 10;
    return Row(
      children: [
        SizedBox(
          width: 36, height: 36,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _timerAnimCtrl,
                builder: (_, __) => CircularProgressIndicator(
                  value: _timerAnimCtrl.value,
                  strokeWidth: 3,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  color: isLow ? Colors.red : Theme.of(context).colorScheme.primary,
                ),
              ),
              Center(
                child: Text('$_timeLeft',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isLow ? Colors.red : Theme.of(context).colorScheme.primary,
                  )),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text('sn', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildRoundResultBanner() {
    final isCorrect = _myAnswerCorrect == true;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCorrect ? Colors.green : Colors.red.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                isCorrect ? '+10 Puan! 🎉' : 'Yanlış cevap 😔',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold, fontSize: 16,
                  color: isCorrect ? Colors.green : Colors.red),
              ),
              const SizedBox(height: 6),
              Text('Doğru cevap:',
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text(_correctAnswer ?? '',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold, fontSize: 14,
                  color: Colors.green.shade700)),
            ],
          ),
        ),
        Text('Sıradaki soru hazırlanıyor...',
          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: (_roundScores as List).map<Widget>((s) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(s['username'] ?? '?',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 3),
                      Text('${s['score'] ?? 0}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPlayerCards() {
    return Row(
      children: (_players as List).map<Widget>((p) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildPlayerCard(p),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayerCard(dynamic player) {
    final myName = context.read<AuthProvider>().user?['username'] ?? 'Misafir';
    final isMe = player['username'] == myName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: isMe
            ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.4))
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isMe
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              (player['username'] ?? '?')[0].toUpperCase(),
              style: TextStyle(
                color: isMe ? Colors.white : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player['username'] ?? '?',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, fontSize: 12)),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Text('${player['score'] ?? 0}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const Icon(Icons.arrow_left, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  // ── GAME OVER ─────────────────────────────────────────────────────────────
  Widget _buildGameOver() {
    final myName = context.read<AuthProvider>().user?['username'] ?? 'Misafir';
    final amIWinner = _winnerName == myName;
    final sortedPlayers = List.from(_players)
      ..sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Trophy + winner banner
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, val, child) => Transform.scale(scale: val, child: child),
              child: Text(amIWinner ? '🏆' : '🎮',
                style: const TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5543CF), Color(0xFF9E93FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF5543CF).withOpacity(0.3),
                  blurRadius: 20, offset: const Offset(0, 8),
                )],
              ),
              child: Column(
                children: [
                  Text('DÜELLO SONA ERDİ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      letterSpacing: 3, color: Colors.white.withOpacity(0.8))),
                  const SizedBox(height: 8),
                  Text('🏆 ${_winnerName ?? '?'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('kazandı!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sıralama kartları
            Text('SIRALAMA',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 12),

            ...sortedPlayers.asMap().entries.map((e) {
              final idx = e.key;
              final p = e.value;
              final isMe = p['username'] == myName;
              final medal = idx == 0 ? '🥇' : idx == 1 ? '🥈' : '🥉';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isMe
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: isMe
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    Text(medal, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: isMe
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        (p['username'] ?? '?')[0].toUpperCase(),
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['username'] ?? '?',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                          if (isMe)
                            Text('SEN', style: TextStyle(
                              fontSize: 10, color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text('${p['score'] ?? 0}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20, fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                        Text('puan', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.home),
                label: Text('Ana Menüye Dön',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── OFFLINE ───────────────────────────────────────────────────────────────
  Widget _buildOfflineState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text('Backend Bağlantısı Yok',
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Düello modu için backend çalışıyor olmalı.\n\nDocker konteynerini başlatıp tekrar deneyin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Başlatma komutu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(height: 6),
                Text('docker-compose up -d --build',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF5543CF))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () { setState(() => _connecting = true); _connectSocket(); },
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

// ── Entry Dialog ──────────────────────────────────────────────────────────────

class DuelEntryDialog extends StatefulWidget {
  const DuelEntryDialog({super.key});

  @override
  State<DuelEntryDialog> createState() => _DuelEntryDialogState();
}

class _DuelEntryDialogState extends State<DuelEntryDialog> {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  String _selectedCategory = 'tümü';

  final List<Map<String, String>> categories = [
    {'id': 'tümü', 'title': 'Tümü'},
    {'id': 'atasözü', 'title': 'Atasözleri'},
    {'id': 'deyim', 'title': 'Deyimler'},
    {'id': 'özlü_söz', 'title': 'Özlü Sözler'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('⚔️ Düello Modu',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: const Text('Mevcut odaya katıl'),
            value: _isJoining,
            onChanged: (v) => setState(() => _isJoining = v),
          ),
          if (_isJoining) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Oda Kodunu Girin',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text('Konu Seçin',
              style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: categories.map((c) => DropdownMenuItem(
                    value: c['id'], child: Text(c['title']!),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => DuelScreen(
              isCreator: !_isJoining,
              roomCode: _isJoining ? _codeController.text.trim() : null,
              category: !_isJoining ? _selectedCategory : null,
            )));
          },
          child: Text(_isJoining ? 'Katıl' : 'Oda Oluştur'),
        ),
      ],
    );
  }
}
