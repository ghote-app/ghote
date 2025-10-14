import 'package:flutter/material.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Upgrade to Ghote Pro', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text('What Pro includes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('• 10GB cloud storage (sync across devices)', style: TextStyle(color: Colors.white70)),
            Text('• Unlimited projects and files', style: TextStyle(color: Colors.white70)),
            Text('• Collaboration and sharing', style: TextStyle(color: Colors.white70)),
            Text('• 500 AI analyses per month', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 24),
            Text('Purchase flow coming soon (Stripe / In‑app purchase).', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}


