import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../models/user.dart';
import 'package:intl/intl.dart';
import '../widgets/event_manager.dart'; // Importa il file event_manager.dart
import 'package:url_launcher/url_launcher.dart' show launchUrl, canLaunchUrl;
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;

class CalendarTab extends StatefulWidget {
  final UserModel profileUser;
  final User currentUser;

  const CalendarTab({
    Key? key,
    required this.profileUser,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('teacherId', isEqualTo: widget.profileUser.uid)
        .get();

    final newEvents = <DateTime, List<Event>>{};
    
    for (var doc in eventsSnapshot.docs) {
      final event = Event.fromMap(doc.data(), doc.id);
      final date = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      
      if (newEvents[date] == null) newEvents[date] = [];
      newEvents[date]!.add(event);
    }

    if (mounted) {
      setState(() {
        _events = newEvents;
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(color: Colors.white),
              weekendTextStyle: const TextStyle(color: Colors.white),
              selectedTextStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.yellowAccent,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.yellowAccent,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.yellowAccent),
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.yellowAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.yellowAccent),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.yellowAccent),
            ),
            daysOfWeekHeight: 40,
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
              weekendStyle: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _selectedDay == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Seleziona un giorno per vedere gli eventi',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildEventsList(_getEventsForDay(_selectedDay!)),
        ),
      ],
    );
  }

  Widget _buildEventsList(List<Event> events) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun evento per questo giorno',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              InkWell(
                onTap: () => _showEventDetails(event),
                child: Column(
                  children: [
                    if (event.imageUrl != null)
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(event.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildEventStats(event),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Menu per l'insegnante
              if (currentUser?.uid == event.teacherId)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                      ),
                      color: const Color(0xFF282828),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditEvent(event);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(event);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, color: Colors.white),
                              const SizedBox(width: 8),
                              const Text(
                                'Modifica',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 8),
                              const Text(
                                'Elimina',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventStats(Event event) {
    return Column(
      children: [
        Row(
          children: [
            _buildStat(
              event.isOnline ? Icons.video_call : Icons.location_on,
              event.isOnline ? 'Online' : (event.location ?? 'Non specificato'),
              'Luogo',
            ),
            _buildDivider(),
            _buildStat(
              Icons.access_time,
              DateFormat('HH:mm').format(event.startDate),
              'Orario',
            ),
            _buildDivider(),
            _buildStat(
              Icons.group,
              '${event.participants.length}/${event.maxParticipants}',
              'Partecipanti',
            ),
          ],
        ),
        if (event.isSubscriptionRequired)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.yellowAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.yellowAccent.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.star,
                  color: Colors.yellowAccent,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Solo per abbonati',
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.yellowAccent,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Stack(
              children: [
                // Immagine di copertina con effetto parallasse e bordi arrotondati
                if (event.imageUrl != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 300,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                      child: ShaderMask(
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black, Colors.transparent],
                          ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                        },
                        blendMode: BlendMode.dstIn,
                        child: Image.network(
                          event.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                // Contenuto principale
                CustomScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Indicatore di trascinamento
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // Titolo evento
                            Text(
                              event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Dettagli evento
                            _buildEventStats(event),
                            const SizedBox(height: 20),
                            const Text(
                              'Descrizione',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              event.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            // Link riunione per eventi online
                            if (event.isOnline && event.meetingLink != null) ...[
                              const SizedBox(height: 20),
                              const Text(
                                'Link Riunione',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () => _launchUrl(event.meetingLink),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.yellowAccent.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.video_call,
                                        color: Colors.yellowAccent,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          event.meetingLink!,
                                          style: const TextStyle(
                                            color: Colors.yellowAccent,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Pulsante di chiusura
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                // Pulsanti azione in basso
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black,
                          Colors.black.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _addToCalendar(event),
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Aggiungi al calendario'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (event.participants.contains(widget.currentUser.uid)) {
                                _leaveEvent(event);
                              } else {
                                _joinEvent(event);
                              }
                              Navigator.pop(context);
                            },
                            icon: Icon(event.participants.contains(widget.currentUser.uid)
                                ? Icons.person_remove
                                : Icons.group_add),
                            label: Text(
                              event.participants.contains(widget.currentUser.uid)
                                  ? 'Annulla iscrizione'
                                  : 'Partecipa',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: event.participants.contains(widget.currentUser.uid)
                                  ? Colors.red
                                  : Colors.yellowAccent,
                              foregroundColor: event.participants.contains(widget.currentUser.uid)
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null) return;
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aprire il link')),
        );
      }
    }
  }

  Future<void> _addToCalendar(Event event) async {
    try {
      final calendarEvent = calendar.Event(
        title: event.title,
        description: event.isOnline 
            ? '${event.description}\n\nLink riunione: ${event.meetingLink ?? "Non specificato"}'
            : event.description,
        location: event.isOnline ? 'Online' : (event.location ?? ''),
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      await calendar.Add2Calendar.addEvent2Cal(calendarEvent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento aggiunto al calendario')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  void _editEvent(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: EventManager(
          userId: widget.profileUser.uid,
          event: event,
        ),
      ),
    );
  }

  Future<void> _deleteEvent(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Conferma eliminazione', 
          style: TextStyle(color: Colors.white)),
        content: const Text('Sei sicuro di voler eliminare questo evento?',
          style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(event.id)
            .delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento eliminato con successo')),
        );
        
        _loadEvents(); // Ricarica gli eventi
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
        );
      }
    }
  }

  Future<void> _joinEvent(Event event) async {
    try {
      if (event.isSubscriptionRequired) {
        // Verifica se l'utente è abbonato
        final isSubscribed = await _checkSubscription(event.teacherId);
        if (!isSubscribed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Questo evento è riservato agli abbonati'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(event.id);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        final currentParticipants = List<String>.from(eventDoc.data()?['participants'] ?? []);
        
        if (currentParticipants.length >= event.maxParticipants) {
          throw 'Evento al completo';
        }
        
        if (!currentParticipants.contains(widget.currentUser.uid)) {
          currentParticipants.add(widget.currentUser.uid);
          transaction.update(eventRef, {'participants': currentParticipants});
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ti sei iscritto all\'evento con successo!')),
      );
      
      _loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  Future<bool> _checkSubscription(String teacherId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!userDoc.exists) return false;

    final subscriptions = List<String>.from(userDoc.data()?['subscriptions'] ?? []);
    return subscriptions.contains(teacherId);
  }

  Future<void> _leaveEvent(Event event) async {
    try {
      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(event.id);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        final currentParticipants = List<String>.from(eventDoc.data()?['participants'] ?? []);
        
        if (currentParticipants.contains(widget.currentUser.uid)) {
          currentParticipants.remove(widget.currentUser.uid);
          transaction.update(eventRef, {'participants': currentParticipants});
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iscrizione annullata con successo')),
      );
      
      _loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  void _showEditEvent(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: EventManager(
          userId: widget.currentUser.uid,
          event: event,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF282828),
          title: const Text(
            'Elimina evento',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Sei sicuro di voler eliminare questo evento?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annulla',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _deleteEvent(event);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Elimina',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
} 