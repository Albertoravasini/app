import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/widgets/custom_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfileEditForm extends StatefulWidget {
  final UserModel user;
  final Function(String, String, String) onSave;
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
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Nome',
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Il nome è obbligatorio';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _usernameController,
            label: 'Username',
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Username obbligatorio';
              if (value!.contains(' ')) return 'Username non può contenere spazi';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _bioController,
            label: 'Bio',
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Annulla'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onSave(
                      _nameController.text,
                      _usernameController.text,
                      _bioController.text,
                    );
                  }
                },
                child: const Text('Salva'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 