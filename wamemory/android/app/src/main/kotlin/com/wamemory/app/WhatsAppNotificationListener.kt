package com.wamemory.app

import android.app.Notification
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Parcelable
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.MethodChannel

/**
 * Captures WhatsApp notification payloads and forwards them to Flutter.
 * Only text available in the notification shade can be archived.
 *
 * IMPORTANT: NotificationListener callbacks run on a binder thread.
 * Flutter MethodChannel must be invoked on the main looper or the process dies.
 */
class WhatsAppNotificationListener : NotificationListenerService() {

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        try {
            if (sbn == null) return
            val pkg = sbn.packageName ?: return
            if (!WHATSAPP_PACKAGES.contains(pkg)) return

            // Group summary rows are not real messages.
            if ((sbn.notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return

            val extras: Bundle = sbn.notification.extras ?: return
            val title = resolveTitle(extras) ?: return
            val bodies = resolveBodies(extras)
            if (bodies.isEmpty()) return

            val text = bodies.last()
            val payload = hashMapOf<String, Any?>(
                "title" to title,
                "body" to text,
                "key" to sbn.key,
                "package" to pkg,
                "postedAt" to sbn.postTime,
            )

            val deleteMarker = isDeleteMarker(text)
            dispatch(payload, deleteMarker)
        } catch (e: Exception) {
            Log.w(TAG, "onNotificationPosted failed: ${e.message}")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Removal alone is not a reliable delete-for-everyone signal.
    }

    private fun dispatch(payload: Map<String, Any?>, deleteMarker: Boolean) {
        val messenger = MainActivity.engineReady
        if (messenger == null) {
            synchronized(pending) {
                if (pending.size >= MAX_PENDING) {
                    pending.removeAt(0)
                }
                pending.add(payload to deleteMarker)
            }
            return
        }

        // Binder thread → main looper before touching Flutter.
        mainHandler.post {
            try {
                val live = MainActivity.engineReady ?: run {
                    synchronized(pending) {
                        if (pending.size >= MAX_PENDING) pending.removeAt(0)
                        pending.add(payload to deleteMarker)
                    }
                    return@post
                }
                MethodChannel(live, CHANNEL).invokeMethod(
                    if (deleteMarker) "onPossiblyDeleted" else "onWhatsAppNotification",
                    payload,
                )
            } catch (e: Exception) {
                Log.w(TAG, "Flutter dispatch failed: ${e.message}")
                synchronized(pending) {
                    if (pending.size >= MAX_PENDING) pending.removeAt(0)
                    pending.add(payload to deleteMarker)
                }
            }
        }
    }

    private fun resolveTitle(extras: Bundle): String? {
        val conversation = extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)
            ?.toString()?.trim()
        if (!conversation.isNullOrEmpty()) return conversation

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim()
        if (!title.isNullOrEmpty()) return title

        val sub = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()?.trim()
        if (!sub.isNullOrEmpty()) return sub

        return null
    }

    private fun resolveBodies(extras: Bundle): List<String> {
        val fromMessages = extractMessagingStyleTexts(extras)
        if (fromMessages.isNotEmpty()) return fromMessages

        val candidates = listOfNotNull(
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim(),
            extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim(),
            extras.getCharSequence(Notification.EXTRA_INFO_TEXT)?.toString()?.trim(),
        ).filter { it.isNotEmpty() && !isNoise(it) }

        val lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            ?.mapNotNull { it?.toString()?.trim() }
            ?.filter { it.isNotEmpty() && !isNoise(it) }
            .orEmpty()

        if (lines.isNotEmpty()) return lines
        return candidates
    }

    private fun extractMessagingStyleTexts(extras: Bundle): List<String> {
        val raw: Array<Parcelable>? = try {
            if (Build.VERSION.SDK_INT >= 33) {
                extras.getParcelableArray(Notification.EXTRA_MESSAGES, Parcelable::class.java)
            } else {
                @Suppress("DEPRECATION")
                extras.getParcelableArray(Notification.EXTRA_MESSAGES)
            }
        } catch (_: Exception) {
            null
        }
        if (raw == null || raw.isEmpty()) return emptyList()

        val texts = mutableListOf<String>()
        for (item in raw) {
            val bundle = item as? Bundle ?: continue
            val text = bundle.getCharSequence("text")?.toString()?.trim()
            if (!text.isNullOrEmpty() && !isNoise(text)) {
                texts.add(text)
            }
        }
        return texts
    }

    private fun isNoise(text: String): Boolean {
        val lower = text.lowercase()
        return lower == "whatsapp" ||
            lower.startsWith("checking for new messages") ||
            (lower.contains("new messages") && lower.length < 24)
    }

    companion object {
        private const val TAG = "WAMemoryNLS"
        private const val MAX_PENDING = 200
        const val CHANNEL = "com.wamemory.app/notifications"
        val WHATSAPP_PACKAGES = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
        )
        val pending = mutableListOf<Pair<Map<String, Any?>, Boolean>>()

        fun isDeleteMarker(text: String): Boolean {
            val lower = text.lowercase()
            return lower.contains("this message was deleted") ||
                lower.contains("deleted this message") ||
                lower.contains("удалили это сообщение") ||
                lower.contains("это сообщение удалено") ||
                lower.contains("удалил(а) это сообщение") ||
                lower.contains("bu xabar o'chirildi") ||
                lower.contains("bu xabar ochirildi") ||
                lower.contains("xabar o'chirildi") ||
                lower.contains("xabar ochirildi")
        }
    }
}
