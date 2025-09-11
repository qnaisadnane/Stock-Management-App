import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddArticlePage extends StatefulWidget {
  const AddArticlePage({super.key});

  @override
  State<AddArticlePage> createState() => _AddArticlePageState();
}

class _AddArticlePageState extends State<AddArticlePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idArticleController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _seuilMinController = TextEditingController();
  final TextEditingController _uniteController = TextEditingController();
  final TextEditingController _posteController = TextEditingController();

  String? _selectedCategorie;

  final List<String> _categories = [
    'Instrument de mesure',
    'Vanne',
    'DCS',
    'Autre',
  ];

  bool _isLoading = false;

  Future<void> _addArticle() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String idArticle = _idArticleController.text.trim();

      try {
        // Vérifie si un article avec le même ID existe déjà
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('articles')
            .doc(idArticle)
            .get();

        if (doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur : ID Article déjà utilisé.')),
          );
        } else {
          // Crée le document avec l'ID personnalisé
          await FirebaseFirestore.instance
              .collection('articles')
              .doc(idArticle)
              .set({
            'categorie': _selectedCategorie,
            'type': _typeController.text.trim(),
            'quantite': int.parse(_quantiteController.text.trim()),
            'seuil_min': int.parse(_seuilMinController.text.trim()),
            'unite': _uniteController.text.trim(),
            'poste': _posteController.text.trim(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article ajouté avec succès !')),
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
    _idArticleController.dispose();
    _typeController.dispose();
    _quantiteController.dispose();
    _seuilMinController.dispose();
    _uniteController.dispose();
    _posteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un article'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(_idArticleController, 'ID Article'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategorie,
                  items: _categories.map((categorie) {
                    return DropdownMenuItem<String>(
                      value: categorie,
                      child: Text(categorie),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Catégorie de l’article',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategorie = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une catégorie';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(_typeController, 'Type de l’article'),
                const SizedBox(height: 16),
                _buildTextField(_quantiteController, 'Quantité', isNumber: true),
                const SizedBox(height: 16),
                _buildTextField(_seuilMinController, 'Seuil minimum', isNumber: true),
                const SizedBox(height: 16),
                _buildTextField(_uniteController, 'Unité'),
                const SizedBox(height: 16),
                _buildTextField(_posteController, 'Poste ciblé'),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _addArticle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Ajouter',
                            style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
          return 'Entrez un nombre valide';
        }
        return null;
      },
    );
  }
}
