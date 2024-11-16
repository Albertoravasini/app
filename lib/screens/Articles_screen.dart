import 'package:flutter/material.dart';

class ArticlesWidget extends StatelessWidget {
  const ArticlesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50.0, left: 16.0, right: 16.0),
            child: Row(
              children: [
                Text(
                  'Articoli correlati',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              padding: EdgeInsets.all(16),
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      'Articolo ${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    subtitle: Text(
                      'Descrizione dell\'articolo ${index + 1}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Montserrat',
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
  }
}
