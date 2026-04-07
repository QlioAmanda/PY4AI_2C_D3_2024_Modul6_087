// Nama : Qlio Amanda Febriany | Nim : 241511087 | Kelas : 2C
import 'package:flutter/material.dart';
import '../../auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> with SingleTickerProviderStateMixin {
  final PageController _pageC = PageController();
  late AnimationController _animC;
  late Animation<double> _animFloat;
  int _curPage = 0;

  // --- DATA KONTEN ---
  final List<Map<String, dynamic>> _data = [
    {
      "img": "assets/images/icon_work.png",
      "title": "Kelola Pekerjaan dengan Efektif",
      "desc": "Ubah tumpukan tugas menjadi pencapaian. Kelola deadline dengan presisi untuk karir yang cemerlang.",
      "color": const Color(0xFFF4F7FA), // Soft bluish white
      "accent": const Color(0xFF2563EB), // Royal Blue
    },
    {
      "img": "assets/images/icon_personal.png",
      "title": "Ruang Cerita Pribadi",
      "desc": "Setiap ide dan perasaan berhak didengar. Simpan kenangan manismu dalam jurnal yang aman.",
      "color": const Color(0xFFE0E7FF), // Light indigo tint
      "accent": const Color(0xFF4F46E5), // Indigo
    },
    {
      "img": "assets/images/icon_urgent.png",
      "title": "Fokus Tanpa Batas",
      "desc": "Jangan biarkan hal penting terlewat. Prioritaskan target utamamu dan selesaikan tantangan hari ini!",
      "color": const Color(0xFFFEF3C7), // Light amber/orange tint
      "accent": const Color(0xFFD97706), // Deep Orange/Amber
    }
  ];

  @override
  void initState() {
    super.initState();
    _animC = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _animFloat = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _animC, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageC.dispose();
    _animC.dispose();
    super.dispose();
  }

  void _skip() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));

  @override
  Widget build(BuildContext context) {
    final activeColor = _data[_curPage]["color"] as Color;
    final activeAccent = _data[_curPage]["accent"] as Color;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        color: activeColor,
        child: SafeArea(
          child: Column(
            children: [
              // --- HEADER: JUDUL APLIKASI & SKIP ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // JUDUL "LOGBOOK"
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: activeAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: activeAccent.withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.auto_stories_rounded, color: activeAccent, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "LOGBOOK PRO",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 2.0, 
                            color: activeAccent, 
                          ),
                        ),
                      ],
                    ),
                    
                    // TOMBOL LEWATI
                    TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: Colors.white.withValues(alpha: 0.5), // Background transparan
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        "Lewati",
                        style: TextStyle(color: activeAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // --- KONTEN TENGAH ---
              Expanded(
                child: PageView.builder(
                  controller: _pageC,
                  onPageChanged: (v) => setState(() => _curPage = v),
                  itemCount: _data.length,
                  itemBuilder: (_, i) => _buildContent(_data[i]),
                ),
              ),

              // --- NAVIGASI BAWAH ---
              _buildBottomNav(activeAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animFloat,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, -_animFloat.value),
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.6),
                boxShadow: [
                  BoxShadow(
                    color: (item["accent"] as Color).withValues(alpha: 0.2),
                    blurRadius: 40, offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Image.asset(item["img"]!, width: 160, height: 160, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 50),
          Text(
            item["title"],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A), fontFamily: 'Roboto', letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item["desc"],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Color(0xFF475569), height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(_data.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 8),
              height: 8,
              width: _curPage == i ? 32 : 8,
              decoration: BoxDecoration(
                color: _curPage == i ? accentColor : Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          ElevatedButton(
            onPressed: () {
              if (_curPage == _data.length - 1) {
                _skip();
              } else {
                _pageC.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeOutQuart);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 8,
              shadowColor: accentColor.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: Row(
              children: [
                Text(_curPage == 2 ? "Siap Mulai" : "Lanjut", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(_curPage == 2 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}