import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  fetchData();
}

void fetchData() async {
  final apiUrl = 'https://jsonplaceholder.typicode.com/';

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      // Successful API call
      final jsonData = jsonDecode(response.body);
      handleData(jsonData);
    } else {
      // Error handling for unsuccessful API call
      print('API request failed with status code: ${response.statusCode}');
    }
  } catch (e) {
    // Error handling for exceptions during the API call
    print('An error occurred: $e');
  }
}

void handleData(dynamic jsonData) {
  // Process the parsed data here based on your application's logic
  // For example, extract values, create model objects, update UI, etc.

  // Sample handling: Printing the JSON data
  print('Received data: $jsonData');
}
