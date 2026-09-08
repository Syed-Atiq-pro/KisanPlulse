import 'dart:convert';
import 'package:http/http.dart' as http;
import 'disease_models.dart';

class DiseaseService {
  DiseaseService({this.endpoint});
  final String? endpoint;

  Future<DiseasePrediction> analyze({required List<int> imageBytes}) async {
    if (endpoint == null || endpoint!.isEmpty) {
      return const DiseasePrediction(
        crop: 'Unknown',
        disease: 'AI service not connected',
        confidence: 0,
        advice: [
          'Connect the secure disease-analysis endpoint before using live diagnosis.',
          'Use a clear photo of a single leaf in good daylight.',
        ],
        warning: 'This is a setup state, not a diagnosis.',
      );
    }

    final request = http.MultipartRequest('POST', Uri.parse(endpoint!));
    request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'leaf.jpg'));
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Disease service returned ${response.statusCode}.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return DiseasePrediction(
      crop: data['crop'] as String? ?? 'Unknown',
      disease: data['disease'] as String? ?? 'Unknown',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
      advice: List<String>.from(data['advice'] ?? const []),
      warning: data['warning'] as String?,
    );
  }
}
