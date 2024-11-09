import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class TopicSelectionSheet extends StatefulWidget {
  final List<String> allTopics;
  final String? selectedTopic;
  final Function(String) onSelectTopic;

  const TopicSelectionSheet({
    super.key,
    required this.allTopics,
    required this.selectedTopic,
    required this.onSelectTopic,
  });

  @override
  // ignore: library_private_types_in_public_api
  _TopicSelectionSheetState createState() => _TopicSelectionSheetState();
}

class _TopicSelectionSheetState extends State<TopicSelectionSheet> {
  String? _selectedTopic;

  @override
  void initState() {
    super.initState();
    _selectedTopic = widget.selectedTopic;
  }

void _handleSelectTopic(String topic) {
  setState(() {
    if (_selectedTopic == topic) {
      _selectedTopic = null; // Deseleziona se è già selezionato
    } else {
      _selectedTopic = topic;
    }
  });
  
  widget.onSelectTopic(_selectedTopic ?? 'Just Learn');
  
  // Registra l'evento di selezione del topic su Firebase Analytics
  FirebaseAnalytics.instance.logEvent(
    name: 'topic_selected',
    parameters: {
      'topic': _selectedTopic ?? 'Just Learn',
    },
  );
  
  Navigator.pop(context); // Chiude il foglio di selezione
}

  @override
  Widget build(BuildContext context) {
    final filteredTopics = widget.allTopics.where((topic) => topic != 'Just Learn').toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.black, // Sfondo semi-trasparente
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
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
                    color: Colors.white, // Linea bianca
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filteredTopics.length,
                  itemBuilder: (context, index) {
                    final topic = filteredTopics[index];
                    return GestureDetector(
                      onTap: () => _handleSelectTopic(topic),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 17),
                        decoration: ShapeDecoration(
                          color: _selectedTopic == topic
                              ? Colors.white.withOpacity(0.1) // Selezionato
                              : Colors.white.withOpacity(0.05), // Non selezionato
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: Colors.white.withOpacity(0.12), // Bordi semi-trasparenti
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            topic,
                            style: TextStyle(
                              color: _selectedTopic == topic
                                  ? Colors.white // Testo bianco se selezionato
                                  : Colors.white70, // Testo semi-trasparente se non selezionato
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