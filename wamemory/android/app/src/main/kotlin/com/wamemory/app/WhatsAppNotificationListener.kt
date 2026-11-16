package com.wamemory.app

import android.app.Notification
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Captures WhatsApp notification payloads and forwards them to Flutter.
 * Only text available in the notification shade can be archived.
 */
class WhatsAppNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val pkg = sbn.packageName ?: return
        if (!WHATSAPP_PACKAGES.contains(pkg)) return

        val extras: Bundle = sbn.notification.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim()
            ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim()

        if (title.isNullOrEmpty() || text.isNullOrEmpty()) return

        val payload = hashMapOf<String, Any?>(
            "title" to title,
            "body" to text,
            "key" to sbn.key,
            "package" to pkg,
            "postedAt" to sbn.postTime,
        )

        val lower = text.lowercase()
        val deleteMarker = lower.contains("this message was deleted") ||
            lower.contains("удалили это сообщение") ||
            lower.contains("это сообщение удалено")

        MainActivity.engineReady?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod(
                if (deleteMarker) "onPossiblyDeleted" else "onWhatsAppNotification",
                payload,
            )
        } ?: run {
            // App may be in background — stash for later if needed.
            pending.add(payload to deleteMarker)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Optional: removal alone is not a reliable delete signal.
    }

    companion object {
        const val CHANNEL = "com.wamemory.app/notifications"
        val WHATSAPP_PACKAGES = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
        )
        val pending = mutableListOf<Pair<Map<String, Any?>, Boolean>>()
        var eventSink: EventChannel.EventSink? = null
    }
}
