import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class MosqueService {
  static final String _googleApiKey =
      dotenv.env['API_KEY']!; // Replace with your API key

  static Future<List<Marker>> fetchMosques(
    double userLat,
    double userLng,
    BitmapDescriptor? customIcon, {
    int radius = 2500,
    List<String>? keywords,
  }) async {
    keywords ??= ['masjid', 'mosque', 'masdjid'];

    final List<Marker> markers = [];
    final String baseUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=$userLat,$userLng&radius=$radius&key=$_googleApiKey';

    try {
      for (final keyword in keywords) {
        String nextPageToken = '';
        do {
          final url = Uri.parse(
              '$baseUrl&keyword=$keyword${nextPageToken.isNotEmpty ? '&pagetoken=$nextPageToken' : ''}');
          final response = await http.get(url);

          if (response.statusCode != 200) {
            throw Exception(
                'Failed to fetch mosques: ${response.reasonPhrase}');
          }

          final Map<String, dynamic> data = json.decode(response.body);
          final results =
              (data['results'] as List).cast<Map<String, dynamic>>();

          for (final place in results) {
            final location = place['geometry']['location'];
            final LatLng position = LatLng(location['lat'], location['lng']);
            final double distanceInMeters = Geolocator.distanceBetween(
              userLat,
              userLng,
              location['lat'],
              location['lng'],
            );
            final String distanceInKm =
                (distanceInMeters / 1000).toStringAsFixed(2);

            markers.add(Marker(
              markerId: MarkerId(place['place_id']),
              position: position,
              icon: customIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: place['name'],
                snippet: 'Distance: $distanceInKm km',
              ),
            ));
          }

          nextPageToken = data['next_page_token'] ?? '';
          if (nextPageToken.isNotEmpty) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } while (nextPageToken.isNotEmpty);
      }
    } catch (e) {
      print('Error fetching mosques: $e');
      rethrow;
    }

    return markers;
  }
}
