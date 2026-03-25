import '../../domain/entities/nas_server.dart';
import '../../domain/entities/nas_session.dart';

class BusinessConnectionContext {
  final NasServer server;
  final NasSession session;
  final String baseUrl;

  const BusinessConnectionContext({
    required this.server,
    required this.session,
    required this.baseUrl,
  });
}
