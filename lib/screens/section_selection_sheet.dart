import 'package:flutter/material.dart';
import '../models/course.dart';

class SectionSelectionSheet extends StatefulWidget {
  final Course course;
  final Section? currentSection;
  final Function(Section) onSelectSection;

  const SectionSelectionSheet({
    Key? key,
    required this.course,
    this.currentSection,
    required this.onSelectSection,
  }) : super(key: key);

  @override
  _SectionSelectionSheetState createState() => _SectionSelectionSheetState();
}

class _SectionSelectionSheetState extends State<SectionSelectionSheet> {
  Section? _selectedSection;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.currentSection;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
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
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Titolo del corso
              Text(
                widget.course.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              
              // Lista delle sezioni
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.course.sections.length,
                  itemBuilder: (context, index) {
                    final section = widget.course.sections[index];
                    final isSelected = _selectedSection == section;
                    final isCompleted = false; // Implementa la logica per verificare se la sezione è completata
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedSection = section);
                        widget.onSelectSection(section);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? Colors.white.withOpacity(0.1) 
                            : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Indicatore di completamento
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted 
                                  ? Colors.yellowAccent 
                                  : Colors.white.withOpacity(0.1),
                              ),
                              child: Icon(
                                isCompleted ? Icons.check : Icons.play_arrow,
                                size: 16,
                                color: isCompleted ? Colors.black : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Informazioni della sezione
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Section ${index + 1}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    section.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${section.steps.length} steps',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Indicatore di selezione
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.yellowAccent,
                                size: 24,
                              ),
                          ],
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