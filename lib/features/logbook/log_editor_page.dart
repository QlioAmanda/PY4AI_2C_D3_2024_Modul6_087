// Nama : Qlio Amanda Febriany | Nim : 241511087 | Kelas : 2C
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'models/log_model.dart';
import 'log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final String username; // Disesuaikan dengan strukturmu

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.username,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  
  // Fitur Kategori (Disesuaikan agar tidak merusak kodemu yang lama)
  String _selectedCategory = 'Pekerjaan';
  final List<String> _categories = ['Pekerjaan', 'Pribadi', 'Urgent', 'Mechanical', 'Electronic', 'Software'];
  
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(text: widget.log?.description ?? '');
    _selectedCategory = widget.log?.category ?? 'Pekerjaan';
    if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'Pekerjaan';
    }
    _isPublic = widget.log?.isPublic ?? false;

    // Listener agar Tab Pratinjau terupdate otomatis saat mengetik
    _descController.addListener(() {
      setState(() {}); 
    });
  }

  void _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Judul tidak boleh kosong!"), backgroundColor: Colors.red));
      return;
    }

    try {
      if (widget.log == null) {
        // Tambah Baru
        await widget.controller.addLog(
          _titleController.text,
          _descController.text,
          _selectedCategory,
          _isPublic,
        );
      } else {
        // Update Catatan Lama
        await widget.controller.updateLog(
          widget.index!,
          _titleController.text,
          _descController.text,
          _selectedCategory,
          _isPublic,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Catatan berhasil disimpan!"), backgroundColor: Colors.green));
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // Premium deep blue to bright blue gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Editor", icon: Icon(Icons.edit_document)),
              Tab(text: "Pratinjau", icon: Icon(Icons.preview_rounded)),
            ],
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: EDITOR ---
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Judul Catatan",
                      labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blue.shade100, width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dropdown Kategori
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade100, width: 1.5)
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        items: _categories.map((String value) {
                          // Menentukan warna berdasarkan kategori (seperti LogView)
                          // PERBAIKAN 1: Menambahkan kurung kurawal pada if-else
                          Color catColor;
                          if (value == 'Pribadi') {
                            catColor = const Color(0xFFC084FC); // Purple
                          } else if (value == 'Urgent') {
                            catColor = const Color(0xFFF43F5E); // Rose Red
                          } else if (value == 'Mechanical') {
                            catColor = const Color(0xFF14B8A6); // Teal
                          } else if (value == 'Electronic') {
                            catColor = const Color(0xFF6366F1); // Indigo
                          } else if (value == 'Software') {
                            catColor = const Color(0xFFF59E0B); // Amber
                          } else if (value == 'Pekerjaan') {
                            catColor = const Color(0xFF0EA5E9); // Sky Blue
                          } else {
                            catColor = const Color(0xFF94A3B8); // Slate
                          }
                          
                          return DropdownMenuItem<String>(
                            value: value, 
                            child: Row(
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                                const SizedBox(width: 12),
                                Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: catColor)),
                              ]
                            )
                          );
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedCategory = newValue!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Switch Privasi
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade100, width: 1.5)
                    ),
                    child: SwitchListTile(
                      title: const Text("Publikasikan Catatan"),
                      subtitle: const Text("Jika aktif, anggota tim lain dapat melihat catatan ini."),
                      value: _isPublic,
                      onChanged: (bool value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                      // PERBAIKAN 2: activeColor diganti menjadi activeThumbColor
                      activeThumbColor: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // UBAH: Menghapus 'Expanded' dan mengatur 'minLines' agar kotak tidak tergencet
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blue.shade100, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _descController,
                      maxLines: null, // Bisa mengetik panjang ke bawah tanpa batas
                      minLines: 12,   // Tinggi minimal kotak dibuat 12 baris teks
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: "Tulis dengan Markdown...\n\nContoh:\n# Judul Besar\n## Subjudul\n**Teks Tebal**\n* Item List\n\n`Kode Program`",
                        hintStyle: TextStyle(color: Colors.blueGrey.shade300, height: 1.5),
                        border: InputBorder.none, 
                        contentPadding: const EdgeInsets.all(20), 
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: const Text("Simpan Catatan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  )
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20.0),
              color: const Color(0xFFF4F7FA), // Light background for preview
              child: _descController.text.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_off_rounded, size: 64, color: Colors.blueGrey.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text("Belum ada teks untuk dipratinjau", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 16)),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade50, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade900.withValues(alpha: 0.05),
                          blurRadius: 12, offset: const Offset(0, 4)
                        )
                      ]
                    ),
                    child: MarkdownBody(
                        data: _descController.text,
                        selectable: true, // Teks bisa di-copy
                        styleSheet: MarkdownStyleSheet(
                          h1: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
                          h2: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                          p: TextStyle(fontSize: 16, color: Colors.blueGrey.shade700, height: 1.6),
                          strong: const TextStyle(fontWeight: FontWeight.w900),
                          code: TextStyle(backgroundColor: Colors.blueGrey.shade50, color: const Color(0xFFEF4444), fontFamily: 'monospace', fontSize: 14),
                          codeblockDecoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.shade200)),
                          blockquoteDecoration: BoxDecoration(color: Colors.blue.shade50, border: const Border(left: BorderSide(color: Color(0xFF3B82F6), width: 4))),
                          blockquote: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey.shade600, fontSize: 16),
                        ),
                      ),
                ),
            )
          ],
        ),
      ),
    );
  }
}