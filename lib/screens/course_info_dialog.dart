// lib/widgets/course_info_dialog.dart

import 'package:flutter/material.dart';
import '../models/course.dart';

class CourseInfoDialog extends StatefulWidget {
  final Course course;

  const CourseInfoDialog({Key? key, required this.course}) : super(key: key);

  @override
  _CourseInfoDialogState createState() => _CourseInfoDialogState();
}

class _CourseInfoDialogState extends State<CourseInfoDialog> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Builds the page indicator
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: _currentPage == index ? 12 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.yellowAccent : Colors.white54,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  /// Builds an icon with text for the sections
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Builds the content of each page
  Widget _buildPageContent() {
    return PageView(
      controller: _pageController,
      onPageChanged: (int page) {
        setState(() {
          _currentPage = page;
        });
      },
      children: [
        // Page 1: Description
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Description', Icons.description),
                SizedBox(height: 12),
                Text(
                  widget.course.description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Page 2: Sources and Acknowledgments
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Sources & Thanks', Icons.source),
                SizedBox(height: 12),
                if (widget.course.sources.isNotEmpty) ...[
                  Text(
                    'Sources:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...widget.course.sources.map((source) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                source,
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      )),
                  SizedBox(height: 16),
                ],
                if (widget.course.acknowledgments.isNotEmpty) ...[
                  Text(
                    'Acknowledgments:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...widget.course.acknowledgments.map((ack) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ack,
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),

        // Page 3: Further Reading
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Further Reading', Icons.book),
                SizedBox(height: 12),

                // Recommended Books
                if (widget.course.recommendedBooks.isNotEmpty) ...[
                  Text(
                    'Recommended Books:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...widget.course.recommendedBooks.map((book) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                book,
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      )),
                  SizedBox(height: 16),
                ],

                // Recommended Podcasts
                if (widget.course.recommendedPodcasts.isNotEmpty) ...[
                  Text(
                    'Recommended Podcasts:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...widget.course.recommendedPodcasts.map((podcast) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                podcast,
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      )),
                  SizedBox(height: 16),
                ],

                // Recommended Websites
                if (widget.course.recommendedWebsites.isNotEmpty) ...[
                  Text(
                    'Recommended Websites:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...widget.course.recommendedWebsites.map((website) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                website,
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.6, // Dynamic height
        child: Column(
          children: [
            // Header with close button
            Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.course.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // You can add a close button here if needed
              ],
            ),

            // Divider
            Divider(color: Colors.white54),

            // Page content
            Expanded(
              child: _buildPageContent(),
            ),

            // Page indicators
            _buildPageIndicator(),

            // Page navigation
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Add navigation buttons if needed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}