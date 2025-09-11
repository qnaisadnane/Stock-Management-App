import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/ocp.png', height: 80),
              const SizedBox(height: 30),
              const Text(
                'Créer un compte',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF2E7D32)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF2E7D32)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF2E7D32)),
                  border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                          onPressed: () async {
                          final name = nameController.text.trim();
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();

                          if (name.isEmpty || email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuiller remplir tous les champs'),
                           backgroundColor: Colors.red,),
                          );
                         return;
                         }

                         try {
                        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                        );

                         await FirebaseFirestore.instance
                            .collection('users')
                             .doc(userCredential.user!.uid)
                              .set({
                               'name': name,
                               'email': email,
                                 });


                        ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Compte créé avec succès'),
                       backgroundColor: Colors.green,
                       ),
                       );

                      Navigator.pop(context); // Retour à l'écran de connexion
                      } on FirebaseAuthException catch (e) {
                      String message = 'Une erreur est survenue';
                      if (e.code == 'email-already-in-use') {
                      message = 'Cet email est déjà utilisé.';
                     } else if (e.code == 'weak-password') {
                     message = 'Le mot de passe est trop faible.';
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(message), backgroundColor: Colors.red,),
                  );
                 }
                 },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Créer un compte',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Déja un compte ?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Se connecter",
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
