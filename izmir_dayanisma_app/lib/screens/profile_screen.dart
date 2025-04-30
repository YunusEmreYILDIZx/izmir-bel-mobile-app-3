// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/local_db_service.dart';
import '../models/event.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Event>> _joinedFuture;

  @override
  void initState() {
    super.initState();
    final email = context.read<AuthProvider>().userEmail!;
    _joinedFuture = context.read<LocalDbService>().getJoinedEvents(email);
  }

  Future<void> _confirmLogout() async {
    final should = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Çıkış Yap'),
            content: const Text(
              'Hesabınızdan çıkmak istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hayır'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Evet'),
              ),
            ],
          ),
    );
    if (should == true) {
      context.read<AuthProvider>().logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'İsim Soyisim: ${auth.userName ?? ''}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'E-posta: ${auth.userEmail ?? ''}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Yaş: ${auth.userAge ?? ''}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Cinsiyet: ${auth.userGender ?? ''}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'İkamet İlçesi: ${auth.userDistrict ?? ''}',
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(height: 32),

          if (!isAdmin) ...[
            const Text(
              'Katıldığınız Etkinlikler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Event>>(
              future: _joinedFuture,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return const Center(
                    child: Text('Henüz katıldığınız etkinlik yok.'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final e = list[i];
                    return ListTile(
                      title: Text(e.title),
                      subtitle: Text(
                        '${e.date.day}.${e.date.month}.${e.date.year}',
                      ),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            '/event-detail',
                            arguments: e,
                          ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
