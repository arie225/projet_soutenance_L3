import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../service/post.dart';

class CreatePostWidget extends StatefulWidget {
  const CreatePostWidget({Key? key}) : super(key: key);

  @override
  _CreatePostWidgetState createState() => _CreatePostWidgetState();
}

class _CreatePostWidgetState extends State<CreatePostWidget> {
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categorieController = TextEditingController();
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _getImages() async {
    final List<XFile>? selectedImages = await _picker.pickMultiImage();
    if (selectedImages != null) {
      setState(() {
        _images.addAll(selectedImages);
      });
    }
  }

  Future<void> _createPost() async {
    if (_titreController.text.isEmpty ||
        _prixController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _categorieController.text.isEmpty ||
        _images.isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs et ajouter au moins une image.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<File> imageFiles = _images.map((xFile) => File(xFile.path)).toList();

      await FirebaseService.createPost(
        titre: _titreController.text,
        prix: double.parse(_prixController.text),
        description: _descriptionController.text,
        categorie: _categorieController.text,
        images: imageFiles,
      );

      _resetForm();
      _showSuccessSnackBar('Post publié avec succès!');
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la publication: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _titreController.clear();
    _prixController.clear();
    _descriptionController.clear();
    _categorieController.clear();
    setState(() => _images.clear());
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer une annonce'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section Images
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _getImages,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: Theme.of(context).primaryColor),
                                  SizedBox(height: 8),
                                  Text('Ajouter des photos',
                                      style: TextStyle(color: Theme.of(context).primaryColor)),
                                ],
                              ),
                            ),
                          ),
                          if (_images.isNotEmpty) SizedBox(height: 16),
                          if (_images.isNotEmpty)
                            Container(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _images.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: FileImage(File(_images[index].path)),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        width: 120,
                                      ),
                                      Positioned(
                                        right: 12,
                                        top: 4,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() => _images.removeAt(index));
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.close,
                                                color: Colors.white,
                                                size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Section Informations
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Informations du produit',
                              style: Theme.of(context).textTheme.titleMedium),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _titreController,
                            decoration: InputDecoration(
                              labelText: "Nom du produit",
                              hintText: "Entrez le nom du produit",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.shopping_bag_outlined),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _prixController,
                            decoration: InputDecoration(
                              labelText: "Prix",
                              hintText: "Entrez le prix",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.attach_money),
                              suffixText: 'FCFA',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _categorieController,
                            decoration: InputDecoration(
                              labelText: "Catégorie",
                              hintText: "Entrez la catégorie du produit",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: "Description",
                              hintText: "Entrez la description du produit",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.description_outlined),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text("Annuler"),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createPost,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: _isLoading
                                ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                                : Text('Publier'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _prixController.dispose();
    _descriptionController.dispose();
    _categorieController.dispose();
    super.dispose();
  }
}