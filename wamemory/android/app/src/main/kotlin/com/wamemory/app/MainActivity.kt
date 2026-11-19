package com.wamemory.app

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private var pendingPick: MethodChannel.Result? = null
    private var pickFolder: String = "profile"
    private var pickFileName: String = "avatar.jpg"
    private var pickMime: String = "image/*"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        engineReady = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WhatsAppNotificationListener.CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "isNotificationAccessEnabled" -> {
                            result.success(isNotificationServiceEnabled())
                        }
                        "openNotificationAccessSettings" -> {
                            startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                            result.success(true)
                        }
                        "flushPending" -> {
                            val pending = synchronized(WhatsAppNotificationListener.pending) {
                                val copy = WhatsAppNotificationListener.pending.toList()
                                WhatsAppNotificationListener.pending.clear()
                                copy
                            }
                            val messenger = flutterEngine.dartExecutor.binaryMessenger
                            for ((payload, deleted) in pending) {
                                try {
                                    MethodChannel(
                                        messenger,
                                        WhatsAppNotificationListener.CHANNEL,
                                    ).invokeMethod(
                                        if (deleted) "onPossiblyDeleted" else "onWhatsAppNotification",
                                        payload,
                                    )
                                } catch (e: Exception) {
                                    Log.w(TAG, "flush item failed: ${e.message}")
                                }
                            }
                            result.success(pending.size)
                        }
                        "pickProfileImage" -> {
                            startPick(result, "profile", "avatar.jpg", "image/*")
                        }
                        "pickChatMedia" -> {
                            val mime = call.argument<String>("mime") ?: "image/*"
                            val name = call.argument<String>("fileName")
                                ?: "media_${System.currentTimeMillis()}.bin"
                            startPick(result, "media", name, mime)
                        }
                        "openMediaFile" -> {
                            val path = call.argument<String>("path")
                            val mime = call.argument<String>("mime") ?: "*/*"
                            if (path.isNullOrBlank()) {
                                result.error("bad_args", "path required", null)
                                return@setMethodCallHandler
                            }
                            try {
                                val file = File(path)
                                if (!file.exists()) {
                                    result.error("missing", "File not found", null)
                                    return@setMethodCallHandler
                                }
                                val uri = FileProvider.getUriForFile(
                                    this,
                                    "${applicationContext.packageName}.fileprovider",
                                    file,
                                )
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(uri, mime)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                startActivity(Intent.createChooser(intent, "Open media"))
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("open_failed", e.message, null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "channel error ${call.method}: ${e.message}", e)
                    try {
                        result.error("native_error", e.message, null)
                    } catch (_: Exception) {
                    }
                }
            }
    }

    override fun onDestroy() {
        if (isFinishing) {
            engineReady = null
        }
        super.onDestroy()
    }

    private fun startPick(
        result: MethodChannel.Result,
        folder: String,
        fileName: String,
        mime: String,
    ) {
        if (pendingPick != null) {
            result.error("busy", "Picker already open", null)
            return
        }
        pendingPick = result
        pickFolder = folder
        pickFileName = fileName
        pickMime = mime

        val intent = buildPickIntent(mime)
        @Suppress("DEPRECATION")
        startActivityForResult(Intent.createChooser(intent, "Choose media"), REQ_PICK_IMAGE)
    }

    /**
     * Prefer system Photo Picker / gallery (shows real photos).
     * ACTION_GET_CONTENT alone often opens empty DocumentsUI on some OEMs.
     */
    private fun buildPickIntent(mime: String): Intent {
        val isImage = mime.startsWith("image/")
        val isVideo = mime.startsWith("video/")
        val isAudio = mime.startsWith("audio/")

        if (isImage && Build.VERSION.SDK_INT >= 33) {
            return Intent(MediaStore.ACTION_PICK_IMAGES).apply {
                type = "image/*"
            }
        }

        if (isImage || isVideo) {
            val uri = when {
                isVideo -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                else -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            }
            return Intent(Intent.ACTION_PICK, uri).apply {
                type = if (isVideo) "video/*" else "image/*"
            }
        }

        if (isAudio) {
            return Intent(Intent.ACTION_GET_CONTENT).apply {
                type = "audio/*"
                addCategory(Intent.CATEGORY_OPENABLE)
            }
        }

        // Documents / any file
        return Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = if (mime == "*/*") "*/*" else mime
        }
    }

    @Deprecated("Deprecated in Android; still used for FlutterActivity result bridge")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ_PICK_IMAGE) return
        val reply = pendingPick
        pendingPick = null
        if (reply == null) return
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            reply.success(null)
            return
        }
        try {
            val path = copyUriToFile(data.data!!, pickFolder, pickFileName)
            reply.success(path)
        } catch (e: Exception) {
            reply.error("copy_failed", e.message, null)
        }
    }

    private fun copyUriToFile(uri: Uri, folder: String, fileName: String): String {
        val dir = File(filesDir, folder)
        if (!dir.exists()) dir.mkdirs()
        val safe = fileName.replace(Regex("[^a-zA-Z0-9._-]"), "_")
        val out = File(dir, safe)
        contentResolver.openInputStream(uri).use { input ->
            requireNotNull(input) { "Cannot open gallery file" }
            FileOutputStream(out).use { output -> input.copyTo(output) }
        }
        return out.absolutePath
    }

    private fun isNotificationServiceEnabled(): Boolean {
        return try {
            val cn = ComponentName(this, WhatsAppNotificationListener::class.java)
            val flat = Settings.Secure.getString(
                contentResolver,
                "enabled_notification_listeners",
            ) ?: return false
            flat.split(":").any {
                ComponentName.unflattenFromString(it)?.equals(cn) == true ||
                    (!TextUtils.isEmpty(it) && it.contains(packageName))
            }
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        private const val TAG = "WAMemoryMain"
        private const val REQ_PICK_IMAGE = 44021
        @Volatile
        var engineReady: BinaryMessenger? = null
    }
}
