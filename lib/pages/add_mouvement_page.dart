import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMouvementPage extends StatefulWidget {
  const AddMouvementPage({super.key});

  @override
  State<AddMouvementPage> createState() => _AddMouvementPageState();
}

class _AddMouvementPageState extends State<AddMouvementPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  DateTime? _selectedDateTime;
  String _type = 'Ajout';
  bool _isLoading = false;
  String? _selectedCategorie;

  final List<String> _categories = [
    'Instrument de mesure',
    'Vanne',
    'DCS',
    'Autre',
  ];

  Future<void> _addMouvement() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    final String idMouvement = _idController.text.trim();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('mouvements')
          .doc(idMouvement)
          .get();

      if (doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur : ID Mouvement déjà utilisé.')),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('mouvements')
            .doc(idMouvement)
            .set({
          'id': idMouvement,
          'type': _type,
          'categorie': _selectedCategorie,
          'quantite': int.parse(_quantiteController.text.trim()),
          'date': Timestamp.fromDate(_selectedDateTime ?? DateTime.now()),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mouvement ajouté avec succès !')),
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


  Future<void> _selectDateTime() async {
    final now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedDateTime = fullDateTime;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Ajouter un Mouvement'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ID Mouvement
                TextFormField(
                  controller: _idController,
                  readOnly: false,
                  decoration: InputDecoration(
                    labelText: 'ID Mouvement',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 16),

                // Type de mouvement
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Type de mouvement',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Ajout', child: Text('Ajout')),
                    DropdownMenuItem(value: 'Retrait', child: Text('Retrait')),
                  ],
                  onChanged: (value) => setState(() => _type = value!),
                ),
                const SizedBox(height: 16),

                // Catégorie
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
                  onChanged: (value) => setState(() => _selectedCategorie = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une catégorie';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Quantité
                _buildTextField(_quantiteController, 'Quantité', isNumber: true),
                const SizedBox(height: 16),

                // Date & Heure
                TextFormField(
                  readOnly: true,
                  onTap: _selectDateTime,
                  decoration: InputDecoration(
                    labelText: 'Date et heure',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: _selectedDateTime == null
                        ? ''
                        : '${_selectedDateTime!.day.toString().padLeft(2, '0')}/'
                            '${_selectedDateTime!.month.toString().padLeft(2, '0')}/'
                            '${_selectedDateTime!.year} à '
                            '${_selectedDateTime!.hour.toString().padLeft(2, '0')}:'
                            '${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                  ),
                  validator: (_) {
                    if (_selectedDateTime == null) {
                      return 'Veuillez sélectionner une date et une heure';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Bouton Ajouter
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _addMouvement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Ajouter',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
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
