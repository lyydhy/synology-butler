import '../../../../domain/entities/system_status.dart';

/// 性能页最近一段时间的历史点位缓存。
///
/// 这里只服务当前页面显示，不参与跨页面共享，因此不再使用 Riverpod。
class PerfHistoryBuffer {
  PerfHistoryBuffer([int limit = 30]) : _limit = limit;

  /// 历史点位上限，超过后丢弃最早的数据。
  final int _limit;
  final List<double> _values = [];

  /// 当前用于图表展示的历史序列。
  List<double> get values => List.unmodifiable(_values);

  /// 追加一个采样点。
  void push(double value) {
    _values.add(value);
    if (_values.length > _limit) {
      _values.removeAt(0);
    }
  }

  /// 清空当前历史缓存。
  void clear() => _values.clear();
}

/// 性能页内各指标历史记录的集合。
class PerfHistoryState {
  PerfHistoryState()
      : cpu = PerfHistoryBuffer(),
        cpuUser = PerfHistoryBuffer(),
        cpuSystem = PerfHistoryBuffer(),
        cpuIo = PerfHistoryBuffer(),
        memory = PerfHistoryBuffer(),
        storage = PerfHistoryBuffer(),
        networkUpload = PerfHistoryBuffer(),
        networkDownload = PerfHistoryBuffer(),
        diskRead = PerfHistoryBuffer(),
        diskWrite = PerfHistoryBuffer();

  final PerfHistoryBuffer cpu;
  final PerfHistoryBuffer cpuUser;
  final PerfHistoryBuffer cpuSystem;
  final PerfHistoryBuffer cpuIo;
  final PerfHistoryBuffer memory;
  final PerfHistoryBuffer storage;
  final PerfHistoryBuffer networkUpload;
  final PerfHistoryBuffer networkDownload;
  final PerfHistoryBuffer diskRead;
  final PerfHistoryBuffer diskWrite;

  /// 写入一帧新的性能数据，用于趋势图展示。
  void push(SystemStatus data) {
    cpu.push(data.cpuUsage);
    cpuUser.push(data.cpuUserUsage);
    cpuSystem.push(data.cpuSystemUsage);
    cpuIo.push(data.cpuIoWaitUsage);
    memory.push(data.memoryUsage);
    storage.push(data.storageUsage);
    networkUpload.push(data.networkUploadBytesPerSecond);
    networkDownload.push(data.networkDownloadBytesPerSecond);
    diskRead.push(data.diskReadBytesPerSecond);
    diskWrite.push(data.diskWriteBytesPerSecond);
  }

  /// 清空页面内所有历史记录。
  void clear() {
    cpu.clear();
    cpuUser.clear();
    cpuSystem.clear();
    cpuIo.clear();
    memory.clear();
    storage.clear();
    networkUpload.clear();
    networkDownload.clear();
    diskRead.clear();
    diskWrite.clear();
  }
}
