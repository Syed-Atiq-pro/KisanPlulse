import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/iot_models.dart';
import '../data/iot_repository.dart';

class IotPage extends StatefulWidget {
  const IotPage({super.key});

  @override
  State<IotPage> createState() => _IotPageState();
}

class _IotPageState extends State<IotPage> {
  late final IotRepository repo;
  late final Stream<List<IotDevice>> deviceStream;
  String? selected;

  @override
  void initState() {
    super.initState();
    repo = IotRepository(Supabase.instance.client);
    deviceStream = repo.watchDevices();
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final key = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add ESP32 device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Device name'),
            ),
            TextField(
              controller: key,
              decoration: const InputDecoration(labelText: 'Device key'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok == true && name.text.trim().isNotEmpty && key.text.trim().isNotEmpty) {
      try {
        await repo.addDevice(name: name.text.trim(), key: key.text.trim());
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not add device: $error')),
          );
        }
      }
    }
    name.dispose();
    key.dispose();
  }

  Widget metric(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Farm Monitor', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            onPressed: _add,
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add device',
          ),
        ],
      ),
      body: StreamBuilder<List<IotDevice>>(
        stream: deviceStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load devices: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data!;
          if (devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sensors_off_rounded, size: 64),
                  const SizedBox(height: 12),
                  const Text('No IoT devices connected'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: const Text('Add ESP32'),
                  ),
                ],
              ),
            );
          }

          final requestedId = selected ?? devices.first.id;
          final device = devices.firstWhere(
            (item) => item.id == requestedId,
            orElse: () => devices.first,
          );
          if (selected != device.id) {
            selected = device.id;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: device.id,
                decoration: const InputDecoration(labelText: 'Device'),
                items: devices
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selected = value),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      device.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    ),
                  ),
                  title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    device.isOnline
                        ? 'Online • live telemetry'
                        : 'Offline • waiting for telemetry',
                  ),
                  trailing: IconButton(
                    onPressed: () => repo.deleteDevice(device.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<IotReading>>(
                stream: repo.watchReadings(device.id),
                builder: (context, readingSnapshot) {
                  if (readingSnapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Could not load readings: ${readingSnapshot.error}'),
                      ),
                    );
                  }
                  if (!readingSnapshot.hasData) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final rows = readingSnapshot.data!;
                  if (rows.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No sensor readings yet. Connect the ESP32 and publish readings to Supabase.',
                        ),
                      ),
                    );
                  }

                  final latest = rows.first;
                  return Column(
                    children: [
                      metric(
                        'Soil moisture',
                        latest.soilMoisture == null
                            ? '—'
                            : '${latest.soilMoisture!.toStringAsFixed(1)} %',
                        Icons.water_drop_rounded,
                      ),
                      metric(
                        'Temperature',
                        latest.temperature == null
                            ? '—'
                            : '${latest.temperature!.toStringAsFixed(1)} °C',
                        Icons.thermostat_rounded,
                      ),
                      metric(
                        'Humidity',
                        latest.humidity == null
                            ? '—'
                            : '${latest.humidity!.toStringAsFixed(1)} %',
                        Icons.cloud_rounded,
                      ),
                      metric(
                        'Water level',
                        latest.waterLevel == null
                            ? '—'
                            : '${latest.waterLevel!.toStringAsFixed(1)} %',
                        Icons.opacity_rounded,
                      ),
                      metric(
                        'Pump',
                        latest.pumpOn == null ? '—' : (latest.pumpOn! ? 'ON' : 'OFF'),
                        Icons.power_settings_new_rounded,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last reading: ${DateFormat('dd MMM yyyy, hh:mm:ss a').format(latest.recordedAt.toLocal())}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Recent readings', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      ...rows.take(10).map(
                        (reading) => ListTile(
                          dense: true,
                          title: Text(
                            '${reading.temperature?.toStringAsFixed(1) ?? '—'} °C  •  ${reading.soilMoisture?.toStringAsFixed(1) ?? '—'}% soil',
                          ),
                          subtitle: Text(
                            DateFormat('dd MMM, hh:mm a').format(reading.recordedAt.toLocal()),
                          ),
                          trailing: Text(reading.pumpOn == true ? 'PUMP ON' : 'PUMP OFF'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
