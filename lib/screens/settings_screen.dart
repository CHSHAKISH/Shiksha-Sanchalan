import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiksha_sanchalan/providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // **FIXED**: Replaced ListTile with a more robust Row layout.
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () => themeProvider.toggleTheme(),
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                    Switch.adaptive(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildSettingsCard(
            context,
            icon: Icons.info_outline,
            title: "About App",
            subtitle: "Information about Shiksha Sanchalan",
            onTap: () {
              showAboutDialog(
                  context: context,
                  applicationName: "Shiksha Sanchalan",
                  applicationVersion: "1.0.0",
                  applicationLegalese: "© 2025 Your College Name",
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text("An app for managing examination duties and logistics efficiently."),
                    )
                  ]
              );
            },
          ),
          _buildSettingsCard(
            context,
            icon: Icons.numbers_outlined,
            title: "App Version",
            subtitle: "1.0.0",
            onTap: () {},
          ),
          _buildSettingsCard(
            context,
            icon: Icons.person_outline,
            title: "About Creator",
            subtitle: "Meet the developer behind the app",
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("About the Creator"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("This app is designed and developed by:"),
                      const SizedBox(height: 8),
                      const Text(
                        "CH Shakish", // Replace with your name
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff1F319D)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "A passionate UI/UX designer and Flutter developer.",
                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const Text(
                        "The idea turned into reality just because of god's blessings and Samiksha Mam's guidance throughout the journey.",

                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(icon: const Icon(Icons.link), onPressed: () {}, tooltip: "LinkedIn"),
                          IconButton(icon: const Icon(Icons.code), onPressed: () {}, tooltip: "GitHub"),
                        ],
                      )
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Close"))
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
