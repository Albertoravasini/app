import 'package:flutter/material.dart';
import '../models/course.dart';

class ProfileFeedTab extends StatelessWidget {
  final List<Course> userCourses;
  final bool isLoading;

  const ProfileFeedTab({
    Key? key,
    required this.userCourses,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : userCourses.isEmpty
            ? const Center(
                child: Text(
                  'Nessun corso pubblicato',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: userCourses.length,
                itemBuilder: (context, index) {
                  final course = userCourses[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (course.coverImageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              course.coverImageUrl!,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 150,
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white54,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                course.description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  // Rating
                                  const Icon(
                                    Icons.star,
                                    size: 20,
                                    color: Colors.yellowAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    course.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),

                                  ),
                                  const SizedBox(width: 16),
                                  // Numero recensioni
                                  Icon(
                                    Icons.people,
                                    size: 20,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${course.totalRatings}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Prezzo
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.stars_rounded,
                                        size: 20,
                                        color: Colors.yellowAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${course.cost}',
                                        style: const TextStyle(
                                          color: Colors.yellowAccent,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
  }
} 