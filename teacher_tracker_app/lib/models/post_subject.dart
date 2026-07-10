import 'package:flutter/material.dart';

/// A subject/tag a post can be filed under. Mirrors the backend `PostSubject`
/// enum: [value] is the wire string sent to / received from the API, [label] is
/// the display name, and [icon] drives the chip.
class PostSubject {
  const PostSubject(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  /// All subjects in display order (matches the backend enum order).
  static const List<PostSubject> all = [
    PostSubject('General', 'General', Icons.forum_outlined),
    PostSubject('Math', 'Math', Icons.calculate_outlined),
    PostSubject('Reading', 'Reading', Icons.menu_book_outlined),
    PostSubject('Science', 'Science', Icons.science_outlined),
    PostSubject('SocialStudies', 'Social Studies', Icons.public_outlined),
    PostSubject('Art', 'Art', Icons.palette_outlined),
    PostSubject('Music', 'Music', Icons.music_note_outlined),
    PostSubject(
        'PhysicalEducation', 'Phys. Ed.', Icons.sports_soccer_outlined),
  ];

  /// The subject for a wire [value], defaulting to General for anything unknown.
  static PostSubject fromValue(String value) =>
      all.firstWhere((s) => s.value == value, orElse: () => all.first);

  /// The display label for a wire [value].
  static String labelFor(String value) => fromValue(value).label;

  /// The icon for a wire [value].
  static IconData iconFor(String value) => fromValue(value).icon;
}
