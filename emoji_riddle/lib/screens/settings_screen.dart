import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authPrefs = context.watch<AuthProvider>();
    final themePrefs = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Ayarlar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                   CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(authPrefs.user?['username'] ?? 'Misafir', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            onPressed: () => _showRenameDialog(context, authPrefs),
                          ),
                        ],
                      ),
                      Text(authPrefs.user?['is_premium'] == true ? 'Premium Hesap 🌟' : 'Standart Hesap', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text('HESAP BAĞLANTILARI', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _buildSocialButton(context, 'Google Play ile Senkronize Et', Icons.games, Colors.green),
            
            const SizedBox(height: 32),
            Text('TERCİHLER', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                title: Text('Karanlık Tema', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                secondary: const Icon(Icons.dark_mode),
                value: themePrefs.isDarkMode,
                onChanged: (val) {
                  context.read<ThemeProvider>().toggleTheme();
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text('Ses Efektleri', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                leading: const Icon(Icons.music_note),
                trailing: const Switch(value: true, onChanged: null),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                },
                child: Text('Çıkış Yap', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context, String text, IconData icon, Color color) {
    return ElevatedButton(
      onPressed: () {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bağlantı simüle edildi!')));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, AuthProvider authPrefs) {
    final ctrl = TextEditingController(text: authPrefs.user?['username']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcı Adını Değiştir'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Yeni isminiz'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                final success = await authPrefs.updateUsername(newName);
                if (success) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İsminiz güncellendi!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authPrefs.errorMsg)));
                }
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }
}
