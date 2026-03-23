import '../../data/models/nas_server_model.dart';
import '../../domain/entities/nas_server.dart';

class ServerMapper {
  static NasServerModel toModel(NasServer server) {
    return NasServerModel(
      id: server.id,
      name: server.name,
      host: server.host,
      port: server.port,
      https: server.https,
      basePath: server.basePath,
    );
  }

  static NasServer toEntity(NasServerModel model) {
    return NasServer(
      id: model.id,
      name: model.name,
      host: model.host,
      port: model.port,
      https: model.https,
      basePath: model.basePath,
      ignoreBadCertificate: model.ignoreBadCertificate,
    );
  }
}

