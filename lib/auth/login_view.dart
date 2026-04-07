// Nama : Qlio Amanda Febriany | Nim : 241511087 | Kelas : 2C
import 'package:flutter/material.dart';
import 'login_controller.dart';
import '../features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _c = LoginController();
  final TextEditingController _userC = TextEditingController();
  final TextEditingController _passC = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObscure = true;

  // PREMIUM BLUE & WHITE THEME
  final Color _bgBlue = const Color(0xFFF4F7FA);     
  final Color _primaryBlue = const Color(0xFF2563EB); 
  final Color _errorRed = const Color(0xFFEF4444);   

  @override
  void dispose() {
    _userC.dispose(); _passC.dispose(); _c.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      if (_c.login(_userC.text, _passC.text)) {
        
        // --- [PERBAIKAN MODUL 5 LAKAH 4] ---
        String role = _c.getUserRole(_userC.text);
        String teamId = _c.getUserTeam(_userC.text); // Ambil Team ID
        
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => LogView(username: _userC.text, role: role, teamId: teamId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            _c.isLocked.value ? "Akses Terkunci Sementara!" : "Username atau Password Salah!",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: _c.isLocked.value ? _errorRed : Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlue, 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.blue.shade50, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryBlue.withValues(alpha: 0.15),
                      blurRadius: 24, offset: const Offset(0, 12),
                    )
                  ],
                ),
                child: Icon(Icons.lock_person_rounded, size: 64, color: _primaryBlue),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.blue.shade50, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade900.withValues(alpha: 0.04), // subtle shadow
                      blurRadius: 32, offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text("Welcome Back", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: -0.5)),
                      const SizedBox(height: 12),
                      Text("Silakan masuk untuk melanjutkan catatan harianmu di LogBook pribadi.", textAlign: TextAlign.center, style: TextStyle(color: const Color(0xFF64748B), fontSize: 15, height: 1.5)),
                      const SizedBox(height: 32),
                      _buildTextField(_userC, "Username", Icons.person_outline_rounded),
                      const SizedBox(height: 16),
                      _buildTextField(_passC, "Password", Icons.lock_outline_rounded, isPass: true),
                      const SizedBox(height: 30),
                      ValueListenableBuilder<bool>(
                        valueListenable: _c.isLocked,
                        builder: (ctxLock, isLocked, childLock) => ValueListenableBuilder<int>(
                          valueListenable: _c.remainingTime,
                          builder: (ctxTime, timeLeft, childTime) => SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLocked ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: isLocked ? 0 : 4,
                                shadowColor: _primaryBlue.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: isLocked 
                                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      const Icon(Icons.timer_outlined, size: 20),
                                      const SizedBox(width: 8),
                                      Text("Tunggu ${timeLeft}s", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ])
                                : const Text("Masuk", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text("Versi 1.0.0 • Secure LogBook", style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPass = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass ? _isObscure : false,
      maxLength: isPass ? 8 : null,
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: Colors.blueGrey.shade400), prefixIcon: Icon(icon, color: _primaryBlue),
        filled: true, fillColor: Colors.grey.shade50, counterText: "",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blue.shade50, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryBlue, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _errorRed, width: 1.5)),
        suffixIcon: isPass ? IconButton(icon: Icon(_isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8)), onPressed: () => setState(() => _isObscure = !_isObscure)) : null,
      ),
      validator: (v) => isPass ? (v!.length < 3 ? 'Minimal 3 karakter!' : null) : (v!.isEmpty ? 'Username wajib diisi!' : null),
    );
  }
}