import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; 

class AddBookModal extends StatefulWidget {
  const AddBookModal({super.key});

  @override
  State<AddBookModal> createState() => _AddBookModalState();
}

class _AddBookModalState extends State<AddBookModal> {
  String? _bookTitle; 
  String? _selectedOption; // 'pdf' o 'ia'

  // Definición de colores
  static const Color purpleButton = Color(0xFF6A1B9A);
  static final Color disabledTextColor = Colors.grey.shade700; 
  static final Color disabledBackgroundColor = Colors.grey.shade300; 
  
  // RESTRICCIÓN AGREGADA: Longitud mínima requerida para el título
  static const int MIN_TITLE_LENGTH = 3; 

  // Función de validación: TRUE si el título no está vacío/solo espacios, cumple la longitud mínima, y hay una opción seleccionada
  bool get _isContinueEnabled {
    final isTitleValid = _bookTitle != null && 
                         _bookTitle!.trim().isNotEmpty &&
                         _bookTitle!.trim().length >= MIN_TITLE_LENGTH;

    return isTitleValid && _selectedOption != null;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary; 

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 1. Botón de Cierre (X) ---
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // --- 2. Campo de Título del Libro ---
          const Text(
            'Título del libro',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextFormField(
            onChanged: (value) {
              setState(() {
                _bookTitle = value;
              });
            },
            // Color de texto negro para el input
            style: const TextStyle(color: Colors.black), 
            cursorColor: Colors.black, 
            decoration: InputDecoration(
              hintText: 'Ej. Mi Árbol Lima Limón',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.menu_book, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // --- 3. Pregunta y Opciones ---
          const Text(
            '¿Cómo deseas continuar?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOptionCard(
                icon: Icons.cloud_upload_outlined,
                label: 'Subir PDF propio',
                optionKey: 'pdf',
                color: purpleButton,
                isSelected: _selectedOption == 'pdf',
              ),
              _buildOptionCard(
                icon: Icons.stars_outlined,
                label: 'Continuar con resultados generados por IA',
                optionKey: 'ia',
                color: purpleButton,
                isSelected: _selectedOption == 'ia',
              ),
            ],
          ),
          const SizedBox(height: 40),

          // --- 4. Botón CONTINUAR ---
          ElevatedButton(
            // El botón está deshabilitado si _isContinueEnabled es FALSE
            onPressed: _isContinueEnabled ? () {
              // Lógica de Continuar
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Continuando con el libro: $_bookTitle, Opción: $_selectedOption', style: TextStyle(color: primaryColor)),
                  backgroundColor: Colors.black,
                )
              );
            } : null, 
            
            style: ButtonStyle(
              // FONDO: Morado si habilitado, Gris claro si deshabilitado.
              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) => states.contains(WidgetState.disabled) ? disabledBackgroundColor : purpleButton,
              ),
              // TEXTO: Blanco si habilitado, Gris oscuro si deshabilitado.
              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) => states.contains(WidgetState.disabled) ? disabledTextColor : Colors.white,
              ),
              // ELEVACIÓN: 0 si deshabilitado, 2 si habilitado.
              elevation: WidgetStateProperty.resolveWith<double?>(
                (states) => states.contains(WidgetState.disabled) ? 0 : 2,
              ),
              // BORDE: Ninguno (porque el fondo es sólido)
              side: WidgetStateProperty.all(BorderSide.none),
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 15)),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
            child: const Text(
              'CONTINUAR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // WIDGET AUXILIAR PARA LAS OPCIONES DE SUBIDA
  Widget _buildOptionCard({
    required IconData icon, 
    required String label, 
    required String optionKey, 
    required Color color,
    required bool isSelected, 
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOption = optionKey;
          });
        },
        child: Card(
          color: Colors.white,
          elevation: isSelected ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            // Borde resaltado si está seleccionado
            side: BorderSide(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 2.5 : 1), 
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              height: 100, // Altura fija para que ambos sean del mismo tamaño
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Icon(icon, size: 40, color: isSelected ? color : Colors.grey), 
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 3, 
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12, 
                      color: isSelected ? Colors.black : Colors.black54, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}