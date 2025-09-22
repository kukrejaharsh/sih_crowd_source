import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Gets the current GPS coordinates. Your original code is perfect here.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// NEW: Converts GPS coordinates into a human-readable, structured address.
  Future<Map<String, String?>> getAddressFromPosition(Position position) async {
    try {
      // Use the geocoding package to get placemark details
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        // Return a structured map of the address details
        return {
          'street': place.street,
          'subLocality': place.subLocality,
          'locality': place.locality,
          'city': place.administrativeArea, // In India, administrativeArea is often the city
          'postalCode': place.postalCode,
          'state': place.subAdministrativeArea, // In India, subAdministrativeArea is often the state
          'country': place.country,
        };
      }
      return {}; // Return empty map if no address is found
    } catch (e) {
      print('Error getting address from position: $e');
      // Return an empty map on error, the UI can handle this gracefully
      return {};
    }
  }
}
