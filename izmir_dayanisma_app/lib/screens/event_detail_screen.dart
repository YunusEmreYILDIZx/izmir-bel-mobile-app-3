// lib/screens/event_detail_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/local_db_service.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({Key? key}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? _event;
  LatLng? _coords;
  bool _loadingGeo = true;
  bool _joining = false;
  bool _joined = false;
  final _mapCtl = Completer<GoogleMapController>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_event == null) {
      _event = ModalRoute.of(context)!.settings.arguments as Event;
      _loadGeo();
      _checkJoined();
    }
  }

  Future<void> _loadGeo() async {
    try {
      final query = '${_event!.location}, İzmir, Türkiye';
      final locs = await locationFromAddress(query);
      if (locs.isNotEmpty) {
        final l = locs.first;
        _coords = LatLng(l.latitude, l.longitude);
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    setState(() => _loadingGeo = false);
  }

  Future<void> _checkJoined() async {
    final email = context.read<AuthProvider>().userEmail;
    if (email != null && _event!.id != null) {
      final joined = await context.read<LocalDbService>().isJoined(
        email,
        _event!.id!,
      );
      setState(() => _joined = joined);
    }
  }

  Future<void> _join() async {
    final email = context.read<AuthProvider>().userEmail!;
    setState(() => _joining = true);
    await context.read<LocalDbService>().joinEvent(email, _event!.id!);
    setState(() {
      _joined = true;
      _joining = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Etkinlik Detayı')),
      body:
          _loadingGeo
              ? const Center(child: CircularProgressIndicator())
              : _coords == null
              ? Center(
                child: Text(
                  'Konum bulunamadı:\n${_event!.location}',
                  textAlign: TextAlign.center,
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Harita
                    SizedBox(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _coords!,
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId(_event!.id.toString()),
                            position: _coords!,
                            infoWindow: InfoWindow(title: _event!.title),
                          ),
                        },
                        onMapCreated: (c) => _mapCtl.complete(c),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Etkinlik Detayları
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _event!.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${_event!.date.day}.${_event!.date.month}.${_event!.date.year}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 18),
                              const SizedBox(width: 6),
                              Expanded(child: Text(_event!.location)),
                            ],
                          ),
                          const Divider(height: 32),
                          const Text(
                            'Açıklama',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_event!.description),
                        ],
                      ),
                    ),
                    // Katılımcılar (sadece admin)
                    if (isAdmin) ...[
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Katılımcılar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: context
                            .read<LocalDbService>()
                            .getParticipantsForEvent(_event!.id!),
                        builder: (ctx, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final list = snap.data!;
                          if (list.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Henüz katılım yapılmamış.'),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Liste
                                ...list.map((row) {
                                  return ListTile(
                                    leading: const Icon(Icons.person),
                                    title: Text(row['name'] as String),
                                    subtitle: Text(row['email'] as String),
                                  );
                                }).toList(),
                                const SizedBox(height: 12),
                                // Katılımcı sayısı
                                Text(
                                  'Toplam ${list.length} kişi katıldı',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
      bottomNavigationBar:
          isAdmin
              ? null
              : Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  icon:
                      _joining
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(_joined ? Icons.check : Icons.how_to_reg),
                  label: Text(_joined ? 'Katıldınız' : 'Katılmak İstiyorum'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _joined ? Colors.green : Colors.orange,
                  ),
                  onPressed: (_joined || _joining) ? null : _join,
                ),
              ),
    );
  }
}
