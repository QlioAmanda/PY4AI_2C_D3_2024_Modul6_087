// Nama : Qlio Amanda Febriany | Nim : 241511087 | Kelas : 2C
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'log_editor_page.dart'; 
import '../../auth/login_view.dart';
import 'widgets/log_item_widget.dart';
import '../../services/mongo_service.dart'; 
import '../vision/vision_view.dart';

class LogView extends StatefulWidget {
  final String username;
  final String role; 
  final String teamId; 
  
  const LogView({super.key, required this.username, required this.role, required this.teamId});
  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true; 

  String _filterCategory = 'Semua'; 
  final List<String> _filterCategories = ['Semua', 'Pekerjaan', 'Pribadi', 'Urgent', 'Mechanical', 'Electronic', 'Software'];

  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // PREMIUM BLUE & WHITE THEME
  final Color _bgPastel = const Color(0xFFF4F7FA); // Soft bluish white     
  final Color _themeColor = const Color(0xFF2563EB); // Royal Blue   
  final Color _textNavy = const Color(0xFF0F172A); // Deep slate blue   

  @override
  void initState() {
    super.initState();
    _controller = LogController(widget.username, widget.role, widget.teamId);
    
    _controller.filteredLogsNotifier.addListener(() {
      if (mounted) setState(() => _currentPage = 0);
    });

    Future.microtask(() => _initDatabase());
  }

  Future<void> _initDatabase() async {
    setState(() => _isLoading = true);
    try {
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Koneksi Timeout. Cek Sinyal."),
      );
      await _controller.loadFromDisk();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.toString().contains('SocketException') || e.toString().contains('Timeout')
                      ? "Ups, sepertinya internetmu terputus! Pastikan koneksi menyala ya."
                      : "Gagal terhubung ke Cloud. Coba lagi nanti."
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: "Coba Lagi", textColor: Colors.white, onPressed: _initDatabase),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- DIALOGS ---
  void _showDetailDialog(LogModel log) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _getCategoryColor(log.category).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(_getCategoryIcon(log.category), color: _getCategoryColor(log.category)),
                  const SizedBox(width: 10),
                  Text(log.category.toUpperCase(), style: TextStyle(color: _getCategoryColor(log.category), fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Menampilkan Nama Author di header dialog
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text(log.author, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey), 
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(log.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textNavy)),
                    const SizedBox(height: 8),
                    Text(log.date, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    const SizedBox(height: 20),
                    Text(log.description, style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade700, height: 1.6)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigasi ke Halaman Editor Full Page
  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          username: widget.username,
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar?"), content: const Text("Sesi Anda akan berakhir."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView())); },
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    if (cat == 'Pribadi') return const Color(0xFFC084FC); // Purple
    if (cat == 'Urgent') return const Color(0xFFF43F5E);  // Rose Red
    if (cat == 'Mechanical') return const Color(0xFF14B8A6); // Teal
    if (cat == 'Electronic') return const Color(0xFF6366F1); // Indigo
    if (cat == 'Software') return const Color(0xFFF59E0B); // Amber
    if (cat == 'Pekerjaan') return const Color(0xFF0EA5E9); // Sky Blue
    return const Color(0xFF94A3B8); // Slate
  }

  IconData _getCategoryIcon(String cat) {
    if (cat == 'Pribadi') return Icons.favorite_rounded;
    if (cat == 'Urgent') return Icons.warning_rounded;
    if (cat == 'Mechanical') return Icons.settings_rounded;
    if (cat == 'Electronic') return Icons.memory_rounded;
    if (cat == 'Software') return Icons.code_rounded;
    return Icons.work_rounded;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : _themeColor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPastel, 
      appBar: AppBar(
        toolbarHeight: 100,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15), 
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text("LOGBOOK PRO", style: TextStyle(fontSize: 10, color: Colors.white, letterSpacing: 2.5, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text("Hi, ${widget.username} 👋", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
          ]),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))]
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.person, color: Color(0xFF2563EB), size: 24),
                  ),
                ),
              ],
            ),
          )
        ],
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF3B82F6)], // Dark slate to vibrant blue
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Ornamen Lingkaran Kanan Atas
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
                  ),
                ),
                // Ornamen Lingkaran Kiri Bawah
                Positioned(
                  left: -30,
                  bottom: -20,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
                  ),
                ),
                // Ornamen Lingkaran Tengah
                Positioned(
                  right: 80,
                  top: 20,
                  child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
              ],
            ),
          ),
        ),
        elevation: 8,
        shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      drawer: _buildPremiumDrawer(),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'cameraBtn',
            backgroundColor: const Color(0xFF0EA5E9), 
            foregroundColor: Colors.white,
            elevation: 4,
            highlightElevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const VisionView()));
            },
            child: const Icon(Icons.camera_alt, size: 28),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'addBtn',
            backgroundColor: const Color(0xFF2563EB), 
            foregroundColor: Colors.white,
            elevation: 4,
            highlightElevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => _goToEditor(),
            child: const Icon(Icons.add_rounded, size: 32),
          ),
        ],
      ),
      body: Column(
        children: [
          // 0. OFFLINE INDICATOR (PREMIUM UI)
          ValueListenableBuilder<bool>(
            valueListenable: _controller.isOfflineNotifier,
            builder: (context, isOffline, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isOffline ? 40 : 0,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)], // Ambien warning orange
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                  ]
                ),
                child: isOffline
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Sedang Offline. Perubahan aman tersimpan lokal.",
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),

          // 1. AREA SEARCH & FILTER 
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _controller.searchLog(query: value), 
                    decoration: InputDecoration(
                      hintText: "Cari catatan...",
                      hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                      filled: true, fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30), 
                        borderSide: BorderSide(color: Colors.blue.shade100, width: 1.5)
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30), 
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.blue.shade100, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias, 
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterCategory,
                      icon: Icon(Icons.filter_list_rounded, color: _themeColor),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      items: _filterCategories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value, 
                            style: TextStyle(
                              fontSize: 13, 
                              fontWeight: FontWeight.bold,
                              color: value == 'Semua' ? _textNavy : _getCategoryColor(value)
                            )
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() => _filterCategory = newValue!);
                        _controller.searchLog(category: newValue!);
                      },
                    ),
                  ),
                ),
                
                if (_searchController.text.isNotEmpty || _filterCategory != 'Semua') 
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      radius: 24,
                      child: IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.red, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filterCategory = 'Semua');
                          _controller.resetFilter();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. LIST DATA 
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: _themeColor))
              : ValueListenableBuilder<List<LogModel>>(
                  valueListenable: _controller.filteredLogsNotifier, 
                  builder: (context, allLogsUnfiltered, child) {
                    final allLogs = allLogsUnfiltered.where((log) {
                      return log.author == widget.username || log.isPublic == true;
                    }).toList();

                    if (allLogs.isEmpty) {
                      if (_controller.isFiltering) {
                         return Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/search_not_found.svg',
                                  width: 200,
                                  height: 200,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Hasil tidak ditemukan",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    "Tidak ada log yang sesuai dengan filter '${_controller.currentCategory}' atau kata kunci '${_controller.currentQuery}'",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                     _searchController.clear();
                                     setState(() => _filterCategory = 'Semua');
                                     _controller.resetFilter();
                                  },
                                  icon: const Icon(Icons.clear_all),
                                  label: const Text("Hapus Filter"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey.shade50,
                                    foregroundColor: Colors.blueGrey.shade700,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  )
                                )
                              ],
                            ),
                          ),
                        );
                      }

                      return Center(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/empty_state.svg',
                                width: 200,
                                height: 200,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Belum ada aktivitas hari ini?",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Mulai catat kemajuan proyek Anda!",
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              TextButton.icon(
                                onPressed: _initDatabase,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Coba Refresh Data")
                              )
                            ],
                          ),
                        ),
                      );
                    }

                    // Pagination
                    final totalItems = allLogs.length;
                    final startIndex = _currentPage * _itemsPerPage;
                    final endIndex = min(startIndex + _itemsPerPage, totalItems);
                    final safeEndIndex = endIndex > totalItems ? totalItems : endIndex;
                    final safeStartIndex = startIndex > safeEndIndex ? 0 : startIndex;
                    final paginatedLogs = allLogs.sublist(safeStartIndex, safeEndIndex);

                    return RefreshIndicator(
                      onRefresh: () async {
                        await _controller.loadFromDisk();
                        _showSnackBar("Data Cloud Diperbarui!");
                      },
                      color: _themeColor,
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: paginatedLogs.length,
                              itemBuilder: (context, index) {
                                final realIndex = safeStartIndex + index; 
                                // Lokasi: lib/features/logbook/log_view.dart
                                return LogItemWidget(
                                  log: paginatedLogs[index],
                                  currentUser: widget.username,      // PASTIKAN ini widget.username
                                  currentUserRole: widget.role,      // PASTIKAN ini widget.role
                                  onTap: () => _showDetailDialog(paginatedLogs[index]), 
                                  onEdit: () => _goToEditor(log: paginatedLogs[index], index: realIndex),
                                  onDelete: () {
                                    _controller.deleteLog(realIndex);
                                    _showSnackBar("Catatan dihapus.", isError: true);
                                  },
                                  onSyncTap: () async {
                                    _showSnackBar("Mencoba sinkronisasi data ke Cloud...");
                                    await _initDatabase();
                                  },
                                );
                              },
                            ),
                          ),
                          // Pagination Controls
                          if (totalItems > _itemsPerPage) 
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null, icon: const Icon(Icons.chevron_left)),
                                  Text("Halaman ${_currentPage + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: _textNavy)),
                                  IconButton(onPressed: safeEndIndex < totalItems ? () => setState(() => _currentPage++) : null, icon: const Icon(Icons.chevron_right)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  // --- PREMIUM DRAWER / SIDEBAR ---
  Widget _buildPremiumDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))]),
                  child: const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE1F5FE), child: Icon(Icons.person, size: 36, color: Color(0xFF2563EB))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.username, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text(widget.role, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildDrawerItem(Icons.dashboard_rounded, "Beranda Utama", isSelected: true, onTap: () => Navigator.pop(context)),
                _buildDrawerItem(Icons.edit_note_rounded, "Tulis Catatan", onTap: () { Navigator.pop(context); _goToEditor(); }),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Divider(color: Colors.blueGrey.shade100)),
                _buildDrawerItem(Icons.sync_rounded, "Sinkronisasi Data", onTap: () { Navigator.pop(context); _initDatabase(); }),
                _buildDrawerItem(Icons.info_outline_rounded, "Tentang Aplikasi", onTap: () {
                    Navigator.pop(context);
                    showDialog(context: context, builder: (ctx) => AlertDialog(
                      title: const Text("Info Aplikasi"), content: const Text("Logbook App Premium v2.0\nTheme: Blue/White Edition.\nBy: Qlio Amanda Febriany"),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tutup"))]
                    ));
                  }
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: _showLogoutConfirmation,
              icon: const Icon(Icons.logout_rounded),
              label: const Text("Keluar Akun", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade600,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {bool isSelected = false, required VoidCallback onTap}) {
    final color = isSelected ? const Color(0xFF2563EB) : Colors.blueGrey.shade600;
    return ListTile(
      leading: Icon(icon, color: color, size: 26),
      title: Text(title, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      selectedTileColor: const Color(0xFFE1F5FE),
      selected: isSelected,
      onTap: onTap,
    );
  }
}