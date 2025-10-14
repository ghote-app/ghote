import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'upgrade_screen.dart';
import '../services/subscription_service.dart';
import '../models/subscription.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Subscription>(
        future: SubscriptionService().getUserSubscription(user?.uid ?? ''),
        builder: (context, snapshot) {
          final sub = snapshot.data;
          final planLabel = sub == null ? 'free' : sub.plan;
          final storageText = sub == null || sub.isFree || sub.isPlus ? 'Limited cloud storage' : 'Unlimited cloud storage';
          final aiText = sub == null || sub.usesGeminiFree ? 'Gemini Flash 2.5 (free)' : 'OpenAI/Claude (higher quality)';
          return ListView(
        children: <Widget>[
          const SizedBox(height: 8),
          _sectionTitle('Plan'),
          _planTile(planLabel, storageText, aiText, context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _planCompareCard(context),
          ),
          const Divider(color: Colors.white24, height: 1),
          _sectionTitle('Account'),
          _tile(
            context,
            icon: Icons.person_outline,
            title: 'Change display name',
            onTap: () => _changeDisplayName(context),
          ),
          _tile(
            context,
            icon: Icons.image_outlined,
            title: 'Change avatar',
            onTap: () => _changeAvatar(context),
          ),
          const Divider(color: Colors.white24, height: 1),
          _sectionTitle('Ghote Pro'),
          _tile(
            context,
            icon: Icons.workspace_premium_rounded,
            title: 'Upgrade to Ghote Pro',
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UpgradeScreen()),
              );
            },
          ),
          const Divider(color: Colors.white24, height: 1),
          _sectionTitle('Security'),
          _tile(
            context,
            icon: Icons.logout_rounded,
            title: 'Sign out',
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 20),
        ],
      );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.0),
      ),
    );
  }

  Widget _planTile(String plan, String storage, String ai, BuildContext context) {
    final color = plan == 'pro' ? Colors.amber : (plan == 'plus' ? Colors.blueAccent : Colors.white70);
    return ListTile(
      leading: Icon(Icons.workspace_premium_rounded, color: color),
      title: Text('Current plan: ${plan.toUpperCase()}', style: const TextStyle(color: Colors.white)),
      subtitle: Text('$storage • $ai', style: const TextStyle(color: Colors.white70)),
      trailing: TextButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
        },
        child: const Text('Upgrade'),
      ),
    );
  }

  Widget _planCompareCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Plans', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _planLine('Free / Plus', 'Limited cloud • Gemini 2.5 Flash'),
            _planLine('Pro', 'Unlimited cloud • OpenAI/Claude'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
                },
                child: const Text('Change plan'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _planLine(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white))),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, {required IconData icon, required String title, Widget? trailing, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Future<void> _changeDisplayName(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final controller = TextEditingController(text: user?.displayName ?? '');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Change display name', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  hintText: 'Enter new name',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('3–30 characters. Letters, numbers, spaces.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await user?.updateDisplayName(controller.text.trim());
                if (context.mounted) Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated')));
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeAvatar(BuildContext context) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar change will be available soon')));
  }
}


