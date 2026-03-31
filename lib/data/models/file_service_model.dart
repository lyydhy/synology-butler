import '../../domain/entities/file_service.dart';

class FileServiceModel {
  static FileServicesModel fromApiResponses({
    Map<String, dynamic>? smbData,
    Map<String, dynamic>? nfsData,
    Map<String, dynamic>? ftpData,
    Map<String, dynamic>? afpData,
    Map<String, dynamic>? sftpData,
  }) {
    return FileServicesModel(
      smb: smbData != null ? _parseSmb(smbData) : null,
      nfs: nfsData != null ? _parseNfs(nfsData) : null,
      ftp: ftpData != null ? _parseFtp(ftpData) : null,
      afp: afpData != null ? _parseAfp(afpData) : null,
      sftp: sftpData != null ? _parseSftp(sftpData) : null,
    );
  }

  static FileServiceStatus _parseSmb(Map<String, dynamic> data) {
    return FileServiceStatus(
      serviceName: 'SMB',
      enabled: data['enable'] == true || data['smb_enable'] == true,
      version: _buildSmbVersion(data),
      port: 445,
      extraInfo: {
        'workgroup': data['workgroup'],
        'netbios': data['netbios_name'],
        'max_protocol': data['max_protocol'],
        'min_protocol': data['min_protocol'],
      },
    );
  }

  static String? _buildSmbVersion(Map<String, dynamic> data) {
    final max = data['max_protocol']?.toString() ?? '';
    final min = data['min_protocol']?.toString() ?? '';
    if (max.isNotEmpty || min.isNotEmpty) {
      return 'SMB ${min.isNotEmpty ? min : '1'} - ${max.isNotEmpty ? max : '3'}';
    }
    return 'SMB 1/2/3';
  }

  static FileServiceStatus _parseNfs(Map<String, dynamic> data) {
    return FileServiceStatus(
      serviceName: 'NFS',
      enabled: data['enable'] == true || data['nfs_enable'] == true,
      port: 2049,
      extraInfo: {
        'nfs_v4': data['enable_nfs_v4'],
      },
    );
  }

  static FileServiceStatus _parseFtp(Map<String, dynamic> data) {
    return FileServiceStatus(
      serviceName: 'FTP',
      enabled: data['enable'] == true || data['ftp_enable'] == true,
      port: data['ftp_port'] ?? 21,
      extraInfo: {
        'anonymous': data['anonymous'],
        'chroot': data['chroot'],
      },
    );
  }

  static FileServiceStatus _parseAfp(Map<String, dynamic> data) {
    return FileServiceStatus(
      serviceName: 'AFP',
      enabled: data['enable'] == true || data['afp_enable'] == true,
      port: 548,
      extraInfo: {
        'ddns': data['ddns_hostname'],
      },
    );
  }

  static FileServiceStatus _parseSftp(Map<String, dynamic> data) {
    return FileServiceStatus(
      serviceName: 'SFTP',
      enabled: data['enable'] == true || data['sftp_enable'] == true,
      port: data['sftp_port'] ?? 22,
      extraInfo: {
        'ssh_port': data['ssh_port'],
      },
    );
  }
}
