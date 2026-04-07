// Nama : Qlio Amanda Febriany | Nim : 241511087 | Kelas : 2C
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/log_model.dart';
import '../../../services/access_control_service.dart'; // TAMBAHAN MODUL 5

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final String currentUser;      // Baru: untuk cek pemilik data
  final String currentUserRole;  // Baru: untuk cek role (Ketua/Anggota)
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LogItemWidget({
    super.key,
    required this.log,
    required this.currentUser,
    required this.currentUserRole,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onSyncTap,
  });

  final VoidCallback? onSyncTap;

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('d MMM yyyy, HH:mm').format(dt);
    } catch (e) { return isoDate; }
  }

  Color get _categoryColor {
    switch (log.category) {
      case 'Pribadi': return const Color(0xFFC084FC); // Purple
      case 'Urgent': return const Color(0xFFF43F5E); // Rose Red
      case 'Mechanical': return const Color(0xFF14B8A6); // Teal
      case 'Electronic': return const Color(0xFF6366F1); // Indigo
      case 'Software': return const Color(0xFFF59E0B); // Amber
      case 'Pekerjaan': default: return const Color(0xFF0EA5E9); // Sky Blue
    }
  }
  
  IconData get _categoryIcon {
    switch (log.category) {
      case 'Pribadi': return Icons.favorite_rounded;
      case 'Urgent': return Icons.warning_rounded;
      case 'Mechanical': return Icons.settings_rounded;
      case 'Electronic': return Icons.memory_rounded;
      case 'Software': return Icons.code_rounded;
      case 'Pekerjaan': default: return Icons.work_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _categoryColor;

    // --- GATEKEEPER UI (CONDITIONAL RENDERING) ---
    bool canEdit = AccessControlService.canPerform(currentUserRole, AccessControlService.actionUpdate, isOwner: log.author == currentUser);
    bool canDelete = AccessControlService.canPerform(currentUserRole, AccessControlService.actionDelete, isOwner: log.author == currentUser);

    return Dismissible(
      key: ValueKey(log.id ?? log.date + log.title), // Lebih aman pakai ID
      // Jika tidak boleh delete, matikan fitur swipe-nya!
      direction: canDelete ? DismissDirection.endToStart : DismissDirection.none, 
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async => await _showConfirmDialog(context),
      onDismissed: (direction) => onDelete(),

      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade50, width: 1.5), // subtle blue border
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withValues(alpha: 0.05), // subtle blue shadow
              blurRadius: 12,
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap, 
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- TAMBAHAN TASK 4: INDIKATOR CLOUD/SYNC ---
                    Column(
                      children: [
                        Tooltip(
                          message: log.id != null ? "Tersimpan di Cloud" : "Ketuk untuk Sinkronisasi",
                          child: InkWell(
                            onTap: log.id == null ? onSyncTap : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                log.id != null ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                                size: 20,
                                color: log.id != null ? Colors.teal.shade500 : Colors.amber.shade600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1), 
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Icon(_categoryIcon, color: themeColor, size: 24),
                        ),
                      ],
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6, runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.1), 
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_categoryIcon, size: 10, color: themeColor),
                                  const SizedBox(width: 4),
                                  Text(log.category.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: themeColor, letterSpacing: 0.5)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(4)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person, size: 10, color: Colors.blueGrey.shade600),
                                  const SizedBox(width: 2),
                                  Text(log.author, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(log.title, style: const TextStyle(color: Color(0xFF37474F), fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(log.description, style: const TextStyle(color: Color(0xFF757575), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatDate(log.date), style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 8),
                      // Tampilkan tombol edit HANYA jika canEdit bernilai true
                      if (canEdit) _buildActionButton(Icons.edit_rounded, themeColor, onEdit, "Edit") else const SizedBox(height: 30),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return Container(
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: color, size: 18), onPressed: onTap, tooltip: tooltip, constraints: const BoxConstraints(), padding: const EdgeInsets.all(6)),
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Hapus Catatan?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Yakin ingin menghapus catatan ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}