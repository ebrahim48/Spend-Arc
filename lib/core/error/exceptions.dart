class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server exception']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache exception']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network exception']);
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException([this.message = 'Not found']);
}
