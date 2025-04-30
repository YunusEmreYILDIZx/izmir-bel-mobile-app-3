// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../widgets/event_card.dart';
import '../models/event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  String _searchQuery = '';
  DateTime? _filterDate;
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    HomeScreen.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    HomeScreen.routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<EventProvider>().loadEvents();
  }

  /// Uygulamadan çıkmak istendiğinde çağrılacak onay dialog’u
  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Çıkmak İstiyor musunuz?'),
            content: const Text(
              'Uygulamadan çıkmak istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hayır'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Evet'),
              ),
            ],
          ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final events = context.watch<EventProvider>().events;
    final q = _searchQuery.toLowerCase();
    var filtered =
        events.where((e) {
          return e.title.toLowerCase().contains(q) ||
              e.location.toLowerCase().contains(q);
        }).toList();
    if (_filterDate != null) {
      filtered =
          filtered.where((e) {
            return e.date.year == _filterDate!.year &&
                e.date.month == _filterDate!.month &&
                e.date.day == _filterDate!.day;
          }).toList();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Anasayfa'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _filterDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _filterDate = picked);
              },
            ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/add-event',
                  ).then((_) => context.read<EventProvider>().loadEvents());
                },
              ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Ara… (başlık veya konum)',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              ),
            ),
            Expanded(
              child:
                  filtered.isEmpty
                      ? const Center(child: Text('Bulunamadı'))
                      : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final e = filtered[i];
                          return EventCard(
                            event: e,
                            onTap:
                                () => Navigator.pushNamed(
                                  context,
                                  '/event-detail',
                                  arguments: e,
                                ),
                            onEdit:
                                isAdmin
                                    ? () {
                                      Navigator.pushNamed(
                                        context,
                                        '/edit-event',
                                        arguments: e,
                                      ).then(
                                        (_) =>
                                            context
                                                .read<EventProvider>()
                                                .loadEvents(),
                                      );
                                    }
                                    : null,
                            onDelete:
                                isAdmin
                                    ? () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (_) => AlertDialog(
                                              title: const Text('Silinsin mi?'),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: const Text('Hayır'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    context
                                                        .read<EventProvider>()
                                                        .removeEvent(e.id!);
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Evet'),
                                                ),
                                              ],
                                            ),
                                      );
                                    }
                                    : null,
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
