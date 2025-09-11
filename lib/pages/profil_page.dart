import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/change_password_page.dart';
import 'package:flutter_application_1/pages/settings_page.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String? fullName;
  String? email;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      setState(() {
        fullName = data?['name'] ?? 'Nom non disponible';
        email = data?['email'] ?? user.email ?? 'Email non disponible';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: const Text('Mon Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profil Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName ?? '',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Responsable Logistique',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Options
            _buildOptionTile(
              icon: Icons.settings,
              label: 'Paramètres',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
              },
            ),
            _buildOptionTile(
              icon: Icons.lock_outline,
              label: 'Changer le mot de passe',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
              },
            ),
            _buildOptionTile(
              icon: Icons.info_outline,
              label: 'À propos',
              onTap: () {
                showDialog(
                 context: context,
                  builder: (context) {
                   return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                     content: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: const [
                     Text(
                     'Application de Gestion de Stock',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    SizedBox(height: 8),
                    Text('Version 1.0.0'),
                    SizedBox(height: 8),
                    Text('© 2025 - Tous droits réservés.'),
                      ],
                      ),
                     actions: [
                      TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer', style: TextStyle(color: Colors.black),),
                      ),
                      ],
                     );
                    },
                   );
              },
            ),
            _buildOptionTile(
              icon: Icons.logout,
              label: 'Se déconnecter',
              color: Colors.red,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmation'),
                    content: const Text('Voulez-vous vraiment se déconnecter ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler',style: TextStyle(color: Colors.black),),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Se déconnecter',style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
