// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  int _age = 0;
  String _gender = '';
  String _district = '';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.register(
        _name,
        _email,
        _password,
        _age,
        _gender,
        _district,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı! Lütfen giriş yapın.')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarısız. Lütfen tekrar deneyin.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Register error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'İsim Soyisim'),
                textInputAction: TextInputAction.next,
                validator:
                    (val) =>
                        val != null && val.trim().isNotEmpty
                            ? null
                            : 'İsim Soyisim boş olamaz',
                onSaved: (val) => _name = val!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'E-posta'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator:
                    (val) =>
                        val != null && val.contains('@')
                            ? null
                            : 'Geçerli bir e-posta girin',
                onSaved: (val) => _email = val!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Şifre'),
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator:
                    (val) =>
                        val != null && val.length >= 6
                            ? null
                            : 'En az 6 karakter girin',
                onSaved: (val) => _password = val!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Yaş'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (val) {
                  final v = int.tryParse(val ?? '');
                  return (v != null && v > 0) ? null : 'Geçerli bir yaş girin';
                },
                onSaved: (val) => _age = int.parse(val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Cinsiyet'),
                items: const [
                  DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                  DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                  DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
                ],
                validator:
                    (val) =>
                        val != null && val.isNotEmpty ? null : 'Cinsiyet seçin',
                onChanged: (val) => _gender = val ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'İkamet İlçesi'),
                textInputAction: TextInputAction.done,
                validator:
                    (val) =>
                        val != null && val.trim().isNotEmpty
                            ? null
                            : 'İlçe boş olamaz',
                onSaved: (val) => _district = val!.trim(),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Kayıt Ol'),
                  ),
              const SizedBox(height: 16),
              TextButton(
                onPressed:
                    () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Zaten hesabınız var mı? Giriş Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
