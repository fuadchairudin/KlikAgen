import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple provider to control the main shell page index from anywhere.
final navigationIndexProvider = StateProvider<int>((ref) => 0);
