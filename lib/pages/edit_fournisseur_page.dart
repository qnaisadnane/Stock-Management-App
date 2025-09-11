import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditFournisseurPage extends StatefulWidget {
  final String fournisseurId;
  final Map<String, dynamic> fournisseurData;

  const EditFournisseurPage({
    super.key,
    required this.fournisseurId,
    required this.fournisseurData,
  });

  @override
  State<EditFournisseurPage> createState() => _EditFournisseurPageState();
}

class _EditFournisseurPageState extends State<EditFournisseurPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  late TextEditingController _societeController;
  late TextEditingController _adresseController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.fournisseurData['nom'] ?? '');
    _telephoneController = TextEditingController(text: widget.fournisseurData['telephone'] ?? '');
    _emailController = TextEditingController(text: widget.fournisseurData['email'] ?? '');
    _societeController = TextEditingController(text: widget.fournisseurData['societe'] ?? '');
    _adresseController = TextEditingController(text: widget.fournisseurData['adresse'] ?? '');
  }

  Future<void> _modifierFournisseur() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await FirebaseFirestore.instance.collection('fournisseurs').doc(widget.fournisseurId).update({
          'nom': _nomController.text.trim(),
          'telephone': _telephoneController.text.trim(),
          'email': _emailController.text.trim(),
          'societe': _societeController.text.trim(),
          'adresse': _adresseController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fournisseur modifié avec succès !')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le fournisseur'),
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
                      onPressed: _modifierFournisseur,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Mettre à jour', style: TextStyle(fontSize: 16, color: Colors.white)),),
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
        if (label == 'Email' && !value.contains('@')) {
          return 'Entrez une adresse email valide';
        }
        return null;
      },
    );
  }
}