import 'package:flutter/material.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('升級到 Ghote Pro', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text('Pro 方案包含：', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('• 雲端儲存 10GB（跨裝置同步）', style: TextStyle(color: Colors.white70)),
            Text('• 無限專案與檔案', style: TextStyle(color: Colors.white70)),
            Text('• 協作與共享功能', style: TextStyle(color: Colors.white70)),
            Text('• AI 分析 500 次/月', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 24),
            Text('購買入口將於稍後接上支付系統（Stripe / 內購）。', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}


