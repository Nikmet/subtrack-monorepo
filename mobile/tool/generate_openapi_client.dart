import 'dart:convert';
import 'dart:io';

/// Lightweight generator entrypoint.
///
/// This project currently keeps generated client sources in `lib/api/generated/`.
/// The script validates OpenAPI snapshot existence and basic structure so CI/local
/// can fail fast before manual regeneration.
Future<void> main() async {
  final openApiFile = File('openapi/openapi.json');
  if (!await openApiFile.exists()) {
    stderr.writeln('openapi/openapi.json not found');
    exitCode = 1;
    return;
  }

  final raw = await openApiFile.readAsString();
  final json = jsonDecode(raw);
  if (json is! Map<String, dynamic>) {
    stderr.writeln('Invalid OpenAPI JSON format');
    exitCode = 1;
    return;
  }

  final hasPaths = json['paths'] is Map<String, dynamic>;
  final hasOpenApiVersion = (json['openapi'] ?? '').toString().isNotEmpty;

  if (!hasPaths || !hasOpenApiVersion) {
    stderr.writeln('OpenAPI snapshot is missing required fields (openapi/paths)');
    exitCode = 1;
    return;
  }

  stdout.writeln('OpenAPI snapshot is valid.');
  stdout.writeln('Generated sources are located in lib/api/generated/.');
}
