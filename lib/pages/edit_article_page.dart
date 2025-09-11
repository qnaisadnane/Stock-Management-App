import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditArticlePage extends StatefulWidget {
  final String articleId;

  const EditArticlePage({super.key, required this.articleId});

  @override
  State<EditArticlePage> createState() => _EditArticlePageState();
}

class _EditArticlePageState extends State<EditArticlePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _seuilMinController = TextEditingController();
  final TextEditingController _uniteController = TextEditingController();
  final TextEditingController _posteController = TextEditingController();

  String? _selectedCategorie;
  bool _isLoading = true;

  final List<String> _categories = [
    'Instrument de mesure',
    'Vanne',
    'DCS',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadArticleData();
  }

  Future<void> _loadArticleData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.articleId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _selectedCategorie = data['categorie'];
          _typeController.text = data['type'];
          _quantiteController.text = data['quantite'].toString();
          _seuilMinController.text = data['seuil_min'].toString();
          _uniteController.text = data['unite'];
          _posteController.text = data['poste'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement : $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateArticle() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('articles')
            .doc(widget.articleId)
            .update({
          'categorie': _selectedCategorie,
          'type': _typeController.text.trim(),
          'quantite': int.parse(_quantiteController.text.trim()),
          'seuil_min': int.parse(_seuilMinController.text.trim()),
          'unite': _uniteController.text.trim(),
          'poste': _posteController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article mis à jour !')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier un article'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategorie,
                        items: _categories.map((categorie) {
                          return DropdownMenuItem<String>(
                            value: categorie,
                            child: Text(categorie),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: 'Catégorie de l’article',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => setState(() => _selectedCategorie = value),
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
                      ElevatedButton(
                        onPressed: _updateArticle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Mettre à jour', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
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
