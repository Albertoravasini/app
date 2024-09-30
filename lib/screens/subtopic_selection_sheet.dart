import 'package:flutter/material.dart';

class SubtopicSelectionSheet extends StatefulWidget {
  final List<String> subtopics;  // Assumi che questi subtopics siano già ordinati
  final String? selectedSubtopic;
  final Function(String?) onSelectSubtopic;

  const SubtopicSelectionSheet({
    super.key,
    required this.subtopics,
    required this.selectedSubtopic,
    required this.onSelectSubtopic,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SubtopicSelectionSheetState createState() => _SubtopicSelectionSheetState();
}

class _SubtopicSelectionSheetState extends State<SubtopicSelectionSheet> {
  String? _selectedSubtopic;

  @override
  void initState() {
    super.initState();
    _selectedSubtopic = widget.selectedSubtopic;
  }

  void _handleSelectSubtopic(String? subtopic) {
    setState(() {
      if (_selectedSubtopic == subtopic) {
        _selectedSubtopic = null;  // Deseleziona se è già selezionato
      } else {
        _selectedSubtopic = subtopic;
      }
    });
    widget.onSelectSubtopic(_selectedSubtopic);
    Navigator.pop(context);  // Chiude il foglio di selezione
  }

  @override
  Widget build(BuildContext context) {
    // Se i subtopics sono già ordinati nel parent, non devi fare altro qui.
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lineetta estetica in alto
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.subtopics.length,
                  itemBuilder: (context, index) {
                    final subtopic = widget.subtopics[index];
                    return GestureDetector(
                      onTap: () => _handleSelectSubtopic(subtopic),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 17),
                        decoration: ShapeDecoration(
                          color: _selectedSubtopic == subtopic ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(width: 1, color: Colors.black),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            subtopic,
                            style: TextStyle(
                              color: _selectedSubtopic == subtopic ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}