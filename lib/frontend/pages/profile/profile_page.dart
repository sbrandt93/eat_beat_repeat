import 'package:eat_beat_repeat/frontend/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/vion/vion_cool.png',
              height: 50,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Profil',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        // backgroundColor: Colors.white70,
      ),
      backgroundColor: Colors.teal.shade50,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Einstellungen',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                hoverColor: Colors.transparent,
                leading: Icon(Icons.color_lens, color: Colors.teal.shade300),
                title: const Text(
                  'Theme & Design',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black54,
                  size: 16,
                ),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                hoverColor: Colors.transparent,
                leading: Icon(Icons.settings, color: Colors.teal.shade300),
                title: const Text(
                  'Benachrichtigungen',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black54,
                  size: 16,
                ),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'App-Verwaltung',
              style: TextStyle(fontSize: 20, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                hoverColor: Colors.transparent,
                leading: Icon(
                  Icons.download,
                  color: Colors.teal.shade300,
                ),
                title: const Text(
                  'Daten exportieren',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black54,
                  size: 16,
                ),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                hoverColor: Colors.transparent,
                leading: Icon(Icons.delete, color: Colors.teal.shade300),
                title: const Text(
                  'Papierkorb',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black54,
                  size: 16,
                ),
                onTap: () => Navigator.pushNamed(context, Routes.trash.name),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Account & Sicherheit',
              style: TextStyle(fontSize: 20, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                hoverColor: Colors.transparent,
                leading: Icon(
                  Icons.person,
                  color: Colors.teal.shade300,
                ),
                title: const Text(
                  'Mein Account',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black54,
                  size: 16,
                ),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                hoverColor: Colors.transparent,
                leading: Image.asset(
                  'assets/vion/vion_basic.png',
                  height: 30,
                ),
                title: const Text(
                  'Über Vion',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black54,
                  size: 16,
                ),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
