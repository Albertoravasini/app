import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/widgets/custom_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfileEditForm extends StatefulWidget {
  final UserModel user;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const ProfileEditForm({
    Key? key,
    required this.user,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'name': TextEditingController(text: widget.user.name),
      'username': TextEditingController(text: widget.user.username),
      'bio': TextEditingController(text: widget.user.bio),
      'price': TextEditingController(text: widget.user.subscriptionPrice.toString()),
      'benefit1': TextEditingController(text: widget.user.subscriptionDescription1),
      'benefit2': TextEditingController(text: widget.user.subscriptionDescription2),
      'benefit3': TextEditingController(text: widget.user.subscriptionDescription3),
    };
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField('name', 'Nome', required: true),
          const SizedBox(height: 16),
          _buildTextField('username', 'Username', 
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Username obbligatorio';
              if (value!.contains(' ')) return 'Username non può contenere spazi';
              return null;
            }
          ),
          const SizedBox(height: 16),
          _buildTextField('bio', 'Bio', maxLines: 3),
          const SizedBox(height: 24),
          _buildSubscriptionSection(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTextField(String key, String label, {
    bool required = false,
    int? maxLines,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return CustomTextField(
      controller: _controllers[key]!,
      label: label,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator ?? (required ? (v) => v?.isEmpty ?? true ? 'Campo richiesto' : null : null),
    );
  }

  Widget _buildSubscriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subscription Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField('price', 'Subscription Price',
          required: true,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Price is required';
            if (double.tryParse(value!) == null) return 'Invalid price format';
            return null;
          },
        ),
        const SizedBox(height: 8),
        ...List.generate(3, (i) => 
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildTextField('benefit${i+1}', 'Subscription Benefit ${i+1}', required: true),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Annulla'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: const Text('Salva'),
        ),
      ],
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave({
        'name': _controllers['name']!.text,
        'username': _controllers['username']!.text,
        'bio': _controllers['bio']!.text,
        'subscriptionPrice': double.parse(_controllers['price']!.text),
        'subscriptionDescription1': _controllers['benefit1']!.text,
        'subscriptionDescription2': _controllers['benefit2']!.text,
        'subscriptionDescription3': _controllers['benefit3']!.text,
      });
    }
  }
} 