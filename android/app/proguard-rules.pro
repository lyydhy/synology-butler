# Keep Flutter engine / plugin integration stable
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.**

# Keep MethodChannel / plugin reflection entry points
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * implements io.flutter.plugin.common.PluginRegistry$ActivityResultListener { *; }
-keep class * implements io.flutter.plugin.common.PluginRegistry$RequestPermissionsResultListener { *; }

# Dio / networking (generally safe, avoid over-aggressive stripping in release)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.conscrypt.**

# Keep secure storage / shared prefs plugin related classes if reflection is used internally
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep video / media plugin related classes
-keep class io.flutter.plugins.videoplayer.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Keep file / photo picker plugin entrypoints
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class com.fluttercandies.photo_manager.** { *; }

# Preserve line numbers for crash symbolication where possible
-keepattributes SourceFile,LineNumberTable,*Annotation*,EnclosingMethod,InnerClasses,Signature


# 保留 Dio 库不被混淆
-keep class com.shuyu.gsyvideoplayer.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class dio.** { *; }
-keep class com.example.你的项目包名.** { *; }

# 保留网络相关类
-keepclasseswithmembernames class * {
    native <methods>;
}
-keepattributes Signature
-keepattributes *Annotation*