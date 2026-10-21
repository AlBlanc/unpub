import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AwsCredentials {
  String? awsAccessKeyId;
  String? awsSecretAccessKey;
  String? awsSessionToken;
  Map<String, String>? environment;
  Map<String, String>? containerCredentials;

  AwsCredentials({
    this.awsAccessKeyId,
    this.awsSecretAccessKey,
    this.awsSessionToken,
    this.environment,
    this.containerCredentials,
  }) {
    final env = environment ?? Platform.environment;
    environment ??= Platform.environment;
    awsAccessKeyId = awsAccessKeyId ?? env['AWS_ACCESS_KEY_ID'];
    awsSecretAccessKey = awsSecretAccessKey ?? env['AWS_SECRET_ACCESS_KEY'];

    final isInContainer = env['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'];

    if ((isInContainer != null || containerCredentials != null) &&
        (awsAccessKeyId == null && awsSecretAccessKey == null)) {
      final data = containerCredentials;
      if (data != null) {
        awsAccessKeyId = data['AccessKeyId'];
        awsSecretAccessKey = data['SecretAccessKey'];
        awsSessionToken = data['Token'];
      }
    }

    if (awsAccessKeyId == null || awsSecretAccessKey == null) {
      throw ArgumentError(
        'You must provide a valid Access Key and Secret for AWS.',
      );
    }
  }

  static Future<AwsCredentials> fromEnvironment({
    Map<String, String>? environment,
    String? awsAccessKeyId,
    String? awsSecretAccessKey,
    String? awsSessionToken,
  }) async {
    final env = environment ?? Platform.environment;
    var accessKey = awsAccessKeyId ?? env['AWS_ACCESS_KEY_ID'];
    var secretKey = awsSecretAccessKey ?? env['AWS_SECRET_ACCESS_KEY'];
    var sessionToken = awsSessionToken ?? env['AWS_SESSION_TOKEN'];

    if (accessKey == null &&
        secretKey == null &&
        env['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'] != null) {
      final containerData = await getContainerCredentials(env);
      if (containerData != null) {
        accessKey = containerData['AccessKeyId'] as String?;
        secretKey = containerData['SecretAccessKey'] as String?;
        sessionToken = containerData['Token'] as String?;
      }
    }

    return AwsCredentials(
      awsAccessKeyId: accessKey,
      awsSecretAccessKey: secretKey,
      awsSessionToken: sessionToken,
      environment: env,
    );
  }

  static Future<Map<String, dynamic>?> getContainerCredentials(
    Map<String, String> environment,
  ) async {
    try {
      final relativeUri =
          environment['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'] ?? '';
      final url = Uri.parse('http://169.254.170.2$relativeUri');
      final response = await http.read(url);
      return json.decode(response) as Map<String, dynamic>?;
    } catch (e) {
      print('failed to get container credentials: $e');
      return null;
    }
  }
}
