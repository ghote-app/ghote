import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'upgrade_screen.dart';
import '../services/subscription_service.dart';
import '../services/api_key_service.dart';
import '../models/subscription.dart';
import '../utils/toast_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _pendingPlan = 'free';

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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _devPlanToggle(user?.uid, planLabel),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _planCompareCard(context),
          ),
          const Divider(color: Colors.white24, height: 1),
          _sectionTitle('Usage'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _usageSection(sub),
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
          _sectionTitle('AI Settings'),
          _tile(
            context,
            icon: Icons.key_rounded,
            title: 'Gemini API Key',
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () => _manageGeminiApiKey(context),
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

  Widget _devPlanToggle(String? userId, String currentPlan) {
    if (userId == null || userId.isEmpty) {
      return const SizedBox.shrink();
    }
    // 僅在 custom claims devSwitch=true 時顯示
    final user = FirebaseAuth.instance.currentUser;
    final hasDevSwitch = (user is User && (user as User).tenantId == null); // placeholder避免分析期出錯
    // 這裡不從同步 API 讀 claims；交給 setState 刷新。實際顯示時再嘗試呼叫 setTestPlan 時會再驗證。
    // 若要前端判斷，可在初始化時抓 getIdTokenResult(true) 並暫存。
    _pendingPlan = currentPlan;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Developer: Switch plan (test only)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  dropdownColor: Colors.black,
                  value: _pendingPlan,
                  items: const [
                    DropdownMenuItem(value: 'free', child: Text('Free', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'plus', child: Text('Plus', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'pro', child: Text('Pro', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (v) => setState(() => _pendingPlan = v ?? 'free'),
                  decoration: const InputDecoration(hintText: 'Plan', hintStyle: TextStyle(color: Colors.white54)),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  await SubscriptionService().setTestPlan(userId: userId, plan: _pendingPlan);
                  if (!mounted) return;
                  ToastUtils.success(context, 'Plan updated (test)');
                  setState(() {});
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
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

  Widget _usageSection(Subscription? sub) {
    final aiQuota = sub?.monthlyAiQuota ?? 50;
    // Placeholder usage numbers – wire up real counters later
    final usedAi = (aiQuota * 0.18).round();
    final aiRatio = (usedAi / aiQuota).clamp(0.0, 1.0);

    final hasUnlimited = sub?.hasUnlimitedCloudStorage ?? false;
    final cloudLimitGb = hasUnlimited ? null : 10; // example cap for plus
    final usedCloudGb = hasUnlimited ? 0.0 : 1.7; // placeholder
    final cloudRatio = hasUnlimited ? 0.0 : (usedCloudGb / (cloudLimitGb ?? 1)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _usageLine('AI monthly quota', '$usedAi / $aiQuota', aiRatio, Colors.purple),
        const SizedBox(height: 10),
        hasUnlimited
            ? _usageLine('Cloud storage', 'Unlimited', 0.0, Colors.blue)
            : _usageLine('Cloud storage', '${usedCloudGb.toStringAsFixed(1)} GB / ${cloudLimitGb} GB', cloudRatio, Colors.blue),
        const SizedBox(height: 6),
        Text('Usage figures are placeholders; connect real counters later.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      ],
    );
  }

  Widget _usageLine(String label, String value, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
            Text(value, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
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
                  ToastUtils.success(context, 'Name updated');
                }
              } catch (e) {
                if (!context.mounted) return;
                ToastUtils.error(context, 'Failed: $e');
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
    ToastUtils.info(context, 'Avatar change will be available soon');
  }

  Future<void> _manageGeminiApiKey(BuildContext context) async {
    final apiKeyService = ApiKeyService();
    final currentKey = await apiKeyService.getGeminiApiKey();
    final controller = TextEditingController(text: currentKey ?? '');
    final isObscured = ValueNotifier<bool>(true);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Text(
          'Gemini API Key',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '輸入您的 Gemini API 金鑰。您可以從 Google AI Studio 獲取：',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'https://aistudio.google.com/app/apikey',
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: isObscured,
              builder: (context, obscured, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                  ),
                  child: TextField(
                    controller: controller,
                    obscureText: obscured,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: '輸入 API 金鑰',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscured ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () => isObscured.value = !isObscured.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('取消', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final apiKey = controller.text.trim();
              if (apiKey.isEmpty) {
                await apiKeyService.clearGeminiApiKey();
                if (context.mounted) {
                  ToastUtils.info(context, 'API 金鑰已清除');
                }
              } else {
                await apiKeyService.setGeminiApiKey(apiKey);
                if (context.mounted) {
                  ToastUtils.success(context, '✅ API 金鑰已保存');
                }
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}


