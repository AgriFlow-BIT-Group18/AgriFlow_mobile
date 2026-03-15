import 'dart:math';

class WeatherData {
  final double temperature;
  final String condition;
  final String advice;
  final String region;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.advice,
    required this.region,
  });
}

class WeatherService {
  final List<String> _conditions = ['Sunny', 'Rainy', 'Cloudy', 'Partly Cloudy'];
  
  final Map<String, List<String>> _adviceMap = {
    'Sunny': [
      'Excellent time for harvesting and drying crops.',
      'Perfect conditions for maize planting in the central region.',
      'Ensure proper irrigation for vegetable gardens today.',
    ],
    'Rainy': [
      'Heavy rain expected. Avoid applying fertilizer today.',
      'Optimal conditions for rice transplanting.',
      'Check drainage systems to prevent waterlogging in fields.',
    ],
    'Cloudy': [
      'Good weather for general weeding and field maintenance.',
      'Prepare your soil for the upcoming planting season.',
      'Monitor for pests as humidity remains high.',
    ],
    'Partly Cloudy': [
      'Ideal conditions for most field activities.',
      'Apply nitrogen-based fertilizers if soil moisture is adequate.',
      'Stable weather expected for the next 24 hours.',
    ],
  };

  Future<WeatherData> getLatestWeather(String region) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    final random = Random();
    final condition = _conditions[random.nextInt(_conditions.length)];
    final adviceList = _adviceMap[condition]!;
    final advice = adviceList[random.nextInt(adviceList.length)];
    final temp = 25.0 + random.nextDouble() * 10.0;

    return WeatherData(
      temperature: temp,
      condition: condition,
      advice: advice,
      region: region,
    );
  }
}
