import 'package:flutter/material.dart';

class WebCreatorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 48, vertical: 64),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diventa un Creator',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Condividi la tua conoscenza con studenti in tutto il mondo',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 32),
                        _CreatorRegistrationForm(),
                      ],
                    ),
                  ),
                  SizedBox(width: 64),
                  Expanded(
                    child: Column(
                      children: [
                        _BenefitCard(
                          icon: Icons.people,
                          title: 'Raggiungi studenti globali',
                          description: 'Connettiti con studenti da tutto il mondo interessati al tuo campo.',
                        ),
                        SizedBox(height: 24),
                        _BenefitCard(
                          icon: Icons.monetization_on,
                          title: 'Guadagna insegnando',
                          description: 'Trasforma la tua passione in una fonte di reddito.',
                        ),
                        SizedBox(height: 24),
                        _BenefitCard(
                          icon: Icons.schedule,
                          title: 'Flessibilità totale',
                          description: 'Crea contenuti secondo i tuoi tempi e il tuo ritmo.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorRegistrationForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inizia il tuo percorso come creator',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 24),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Nome completo',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Area di expertise',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            child: Text('Invia richiesta'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: Theme.of(context).primaryColor),
          SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
} 