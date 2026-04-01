package com.qunhui.mage

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "syno_keeper/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 创建通知渠道
        createNotificationChannels()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPublicDownloadsPath" -> {
                        val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                        result.success(dir?.absolutePath)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            
            // 下载任务渠道
            val downloadChannel = NotificationChannel(
                "download_channel",
                "下载任务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "显示文件下载进度"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(downloadChannel)
            
            // 上传任务渠道
            val uploadChannel = NotificationChannel(
                "upload_channel",
                "上传任务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "显示文件上传进度"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(uploadChannel)
        }
    }
}
