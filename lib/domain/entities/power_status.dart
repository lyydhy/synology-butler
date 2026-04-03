/// 电源状态模型
class PowerStatus {
  /// ZRAM 启用状态
  final bool zramEnabled;

  /// 断电恢复设置
  final PowerRecoverySettings? powerRecovery;

  /// 蜂鸣器控制
  final BeepControlSettings? beepControl;

  /// 风扇速度设置
  final FanSpeedSettings? fanSpeed;

  /// LED 亮度设置
  final LedBrightnessSettings? ledBrightness;

  /// 硬盘休眠设置
  final HibernationSettings? hibernation;

  const PowerStatus({
    this.zramEnabled = false,
    this.powerRecovery,
    this.beepControl,
    this.fanSpeed,
    this.ledBrightness,
    this.hibernation,
  });

  factory PowerStatus.fromApiResponse(List<dynamic> results) {
    bool zramEnabled = false;
    PowerRecoverySettings? powerRecovery;
    BeepControlSettings? beepControl;
    FanSpeedSettings? fanSpeed;
    LedBrightnessSettings? ledBrightness;
    HibernationSettings? hibernation;

    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      if (item['success'] != true) continue;

      final api = item['api'] as String?;
      final data = item['data'] as Map<String, dynamic>?;
      if (data == null) continue;

      switch (api) {
        case 'SYNO.Core.Hardware.ZRAM':
          zramEnabled = data['enable_zram'] as bool? ?? false;
          break;
        case 'SYNO.Core.Hardware.PowerRecovery':
          powerRecovery = PowerRecoverySettings.fromJson(data);
          break;
        case 'SYNO.Core.Hardware.BeepControl':
          beepControl = BeepControlSettings.fromJson(data);
          break;
        case 'SYNO.Core.Hardware.FanSpeed':
          fanSpeed = FanSpeedSettings.fromJson(data);
          break;
        case 'SYNO.Core.Hardware.Led.Brightness':
          ledBrightness = LedBrightnessSettings.fromJson(data);
          break;
        case 'SYNO.Core.Hardware.Hibernation':
          hibernation = HibernationSettings.fromJson(data);
          break;
      }
    }

    return PowerStatus(
      zramEnabled: zramEnabled,
      powerRecovery: powerRecovery,
      beepControl: beepControl,
      fanSpeed: fanSpeed,
      ledBrightness: ledBrightness,
      hibernation: hibernation,
    );
  }
}

/// 断电恢复设置
class PowerRecoverySettings {
  final int? rcPowerConfig;
  final bool wol1;
  final bool wol2;

  const PowerRecoverySettings({
    this.rcPowerConfig,
    this.wol1 = false,
    this.wol2 = false,
  });

  factory PowerRecoverySettings.fromJson(Map<String, dynamic> json) {
    // 处理 rc_power_config 可能的类型问题（API 可能返回 bool 或 int）
    int? rcPowerConfig;
    final rcValue = json['rc_power_config'];
    if (rcValue is int) {
      rcPowerConfig = rcValue;
    } else if (rcValue is bool) {
      rcPowerConfig = rcValue ? 1 : 0;
    } else if (rcValue != null) {
      rcPowerConfig = int.tryParse(rcValue.toString());
    }

    return PowerRecoverySettings(
      rcPowerConfig: rcPowerConfig,
      wol1: json['wol1'] as bool? ?? false,
      wol2: json['wol2'] as bool? ?? false,
    );
  }
}

/// 蜂鸣器控制设置
class BeepControlSettings {
  final bool fanFail;
  final bool volumeCrash;
  final bool ssdCacheCrash;
  final bool poweronBeep;
  final bool poweroffBeep;

  const BeepControlSettings({
    this.fanFail = false,
    this.volumeCrash = false,
    this.ssdCacheCrash = false,
    this.poweronBeep = false,
    this.poweroffBeep = false,
  });

  factory BeepControlSettings.fromJson(Map<String, dynamic> json) {
    return BeepControlSettings(
      fanFail: json['fan_fail'] as bool? ?? false,
      volumeCrash: json['volume_crash'] as bool? ?? false,
      ssdCacheCrash: json['ssd_cache_crash'] as bool? ?? false,
      poweronBeep: json['poweron_beep'] as bool? ?? false,
      poweroffBeep: json['poweroff_beep'] as bool? ?? false,
    );
  }
}

/// 风扇速度设置
class FanSpeedSettings {
  final String? fanSpeedMode; // "cool", "quiet", "auto"

  const FanSpeedSettings({
    this.fanSpeedMode,
  });

  factory FanSpeedSettings.fromJson(Map<String, dynamic> json) {
    // API 可能返回 fan_speed 或 fanSpeedMode
    final value = json['fan_speed'] ?? json['fan_speed_mode'];
    return FanSpeedSettings(
      fanSpeedMode: value?.toString(),
    );
  }
}

/// LED 亮度设置
class LedBrightnessSettings {
  final int brightness; // 0-5

  const LedBrightnessSettings({
    this.brightness = 3,
  });

  factory LedBrightnessSettings.fromJson(Map<String, dynamic> json) {
    // API 可能返回 led_brightness 或 brightness
    final value = json['led_brightness'] ?? json['brightness'];
    int brightness = 3;
    if (value is int) {
      brightness = value;
    } else if (value is bool) {
      // 某些情况下 API 可能返回 bool
      brightness = value ? 1 : 0;
    } else if (value != null) {
      brightness = int.tryParse(value.toString()) ?? 3;
    }
    return LedBrightnessSettings(brightness: brightness);
  }
}

/// 硬盘休眠设置
class HibernationSettings {
  final int internalHdIdletime;
  final bool sataDeepSleep;
  final int usbIdletime;
  final bool enableLog;

  const HibernationSettings({
    this.internalHdIdletime = 0,
    this.sataDeepSleep = false,
    this.usbIdletime = 0,
    this.enableLog = false,
  });

  factory HibernationSettings.fromJson(Map<String, dynamic> json) {
    // 处理整数类型可能的类型问题（API 可能返回 bool 或 int）
    int internalHdIdletime = 0;
    final internalHdValue = json['internal_hd_idletime'];
    if (internalHdValue is int) {
      internalHdIdletime = internalHdValue;
    } else if (internalHdValue is bool) {
      internalHdIdletime = internalHdValue ? 1 : 0;
    } else if (internalHdValue != null) {
      internalHdIdletime = int.tryParse(internalHdValue.toString()) ?? 0;
    }

    int usbIdletime = 0;
    final usbValue = json['usb_idletime'];
    if (usbValue is int) {
      usbIdletime = usbValue;
    } else if (usbValue is bool) {
      usbIdletime = usbValue ? 1 : 0;
    } else if (usbValue != null) {
      usbIdletime = int.tryParse(usbValue.toString()) ?? 0;
    }

    return HibernationSettings(
      internalHdIdletime: internalHdIdletime,
      sataDeepSleep: json['sata_deep_sleep'] as bool? ?? false,
      usbIdletime: usbIdletime,
      enableLog: json['enable_log'] as bool? ?? false,
    );
  }
}
