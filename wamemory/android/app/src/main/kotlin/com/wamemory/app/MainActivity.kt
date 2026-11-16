package com.wamemory.app

import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        engineReady = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WhatsAppNotificationListener.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNotificationAccessEnabled" -> {
                        result.success(isNotificationServiceEnabled())
                    }
                    "openNotificationAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(true)
                    }
                    "flushPending" -> {
                        val pending = WhatsAppNotificationListener.pending.toList()
                        WhatsAppNotificationListener.pending.clear()
                        for ((payload, deleted) in pending) {
                            MethodChannel(
                                flutterEngine.dartExecutor.binaryMessenger,
                                WhatsAppNotificationListener.CHANNEL,
                            ).invokeMethod(
                                if (deleted) "onPossiblyDeleted" else "onWhatsAppNotification",
                                payload,
                            )
                        }
                        result.success(pending.size)
                    }
                    else -> result.notImplemented()
                }
            }

        // Do not invoke unknown Dart methods here — can race before handler is set.
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val cn = ComponentName(this, WhatsAppNotificationListener::class.java)
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        return flat.split(":").any {
            ComponentName.unflattenFromString(it)?.equals(cn) == true ||
                (!TextUtils.isEmpty(it) && it.contains(packageName))
        }
    }

    companion object {
        var engineReady: BinaryMessenger? = null
    }
}
