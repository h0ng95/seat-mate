class AppConfig {
  const AppConfig({required this.baseUrl});

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      baseUrl: String.fromEnvironment(
        'APP_BASE_URL',
        defaultValue: 'http://localhost:8080',
      ),
    );
  }

  final String baseUrl;
}
