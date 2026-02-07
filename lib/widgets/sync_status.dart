import 'package:flutter/material.dart';
import '../services/data_storage.dart';

/// Widget qui affiche l'état de synchronisation
class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  Map<String, dynamic>? _syncStatus;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    final status = await DataStorage.getSyncStatus();
    if (mounted) {
      setState(() {
        _syncStatus = status;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);

    try {
      await DataStorage.syncPendingChanges();
      await _loadSyncStatus();
    } catch (e) {
      debugPrint('Erreur refresh: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_syncStatus == null) {
      return const SizedBox.shrink();
    }

    final isOnline = _syncStatus!['isOnline'] as bool;
    final isSyncing = _syncStatus!['isSyncing'] as bool;
    final pendingCount = _syncStatus!['pendingCount'] as int;
    final isAuthenticated = _syncStatus!['isAuthenticated'] as bool;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: isOnline ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline ? 'En ligne' : 'Hors ligne',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isOnline && isAuthenticated)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _isRefreshing ? null : _refresh,
                    tooltip: 'Synchroniser maintenant',
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // État d'authentification
            Row(
              children: [
                Icon(
                  isAuthenticated ? Icons.check_circle : Icons.error,
                  color: isAuthenticated ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isAuthenticated ? 'Authentifié' : 'Non authentifié',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            // Modifications en attente
            if (pendingCount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.sync_problem,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$pendingCount modification(s) en attente',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              if (isOnline && isAuthenticated) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isRefreshing ? null : _refresh,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: Text(_isRefreshing ? 'Sync...' : 'Synchroniser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ] else if (isOnline) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Toutes les données sont synchronisées',
                    style: TextStyle(fontSize: 14, color: Colors.green),
                  ),
                ],
              ),
            ],

            // Message hors ligne
            if (!isOnline) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les modifications seront synchronisées au retour de la connexion',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget compact pour la barre d'état
class CompactSyncIndicator extends StatefulWidget {
  const CompactSyncIndicator({super.key});

  @override
  State<CompactSyncIndicator> createState() => _CompactSyncIndicatorState();
}

class _CompactSyncIndicatorState extends State<CompactSyncIndicator> {
  Map<String, dynamic>? _syncStatus;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();

    // Rafraîchir toutes les 30 secondes
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadSyncStatus();
      }
    });
  }

  Future<void> _loadSyncStatus() async {
    final status = await DataStorage.getSyncStatus();
    if (mounted) {
      setState(() {
        _syncStatus = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_syncStatus == null) {
      return const SizedBox.shrink();
    }

    final isOnline = _syncStatus!['isOnline'] as bool;
    final isSyncing = _syncStatus!['isSyncing'] as bool;
    final pendingCount = _syncStatus!['pendingCount'] as int;

    if (isSyncing) {
      return const Tooltip(
        message: 'Synchronisation en cours...',
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (!isOnline) {
      return Tooltip(
        message: pendingCount > 0
            ? 'Hors ligne - $pendingCount modification(s) en attente'
            : 'Hors ligne',
        child: Icon(
          Icons.cloud_off,
          color: pendingCount > 0 ? Colors.orange : Colors.grey,
          size: 20,
        ),
      );
    }

    if (pendingCount > 0) {
      return Tooltip(
        message: '$pendingCount modification(s) en attente de sync',
        child: Badge(
          label: Text('$pendingCount'),
          child: const Icon(Icons.sync_problem, color: Colors.orange, size: 20),
        ),
      );
    }

    return const Tooltip(
      message: 'Synchronisé',
      child: Icon(Icons.cloud_done, color: Colors.green, size: 20),
    );
  }
}
