import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFournisseurPage extends StatefulWidget {
  const AddFournisseurPage({super.key});

  @override
  State<AddFournisseurPage> createState() => _AddFournisseurPageState();
}

class _AddFournisseurPageState extends State<AddFournisseurPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _societeController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;

  Future<void> _addFournisseur() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String idFournisseur = _idController.text.trim();

      try {
        // Vérifie si un fournisseur avec le même ID existe déjà
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('fournisseurs')
            .doc(idFournisseur)
            .get();

        if (doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur : ID Fournisseur déjà utilisé.')),
          );
        } else {
          await FirebaseFirestore.instance
              .collection('fournisseurs')
              .doc(idFournisseur)
              .set({
            'societe': _societeController.text.trim(),
            'adresse': _adresseController.text.trim(),
            'telephone': _telephoneController.text.trim(),
            'email': _emailController.text.trim(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fournisseur ajouté avec succès !')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _societeController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un fournisseur'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_idController, 'ID Fournisseur'),
              const SizedBox(height: 16),
              _buildTextField(_societeController, 'Société'),
              const SizedBox(height: 16),
              _buildTextField(_adresseController, 'Adresse'),
              const SizedBox(height: 16),
              _buildTextField(_telephoneController, 'Téléphone', isNumber: true),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Email', inputType: TextInputType.emailAddress),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addFournisseur,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Ajouter', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    TextInputType? inputType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType ?? (isNumber ? TextInputType.phone : TextInputType.text),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ce champ est requis';
        }
        if (isNumber && int.tryParse(value.trim()) == null) {
          return 'Entrez un numéro valide';
        }
        return null;
      },
    );
  }
}
