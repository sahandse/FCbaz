package ir.fcbaz.app

import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ir.fcbaz.app/share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareImage" -> {
                        try {
                            val bytes = call.argument<ByteArray>("bytes")
                            if (bytes == null || bytes.isEmpty()) {
                                result.error("invalid_args", "Image bytes are missing", null)
                                return@setMethodCallHandler
                            }
                            val requestedName =
                                call.argument<String>("fileName") ?: "fcbaz-share.png"
                            val fileName = File(requestedName).name.let {
                                if (it.lowercase().endsWith(".png")) it else "$it.png"
                            }
                            val text = call.argument<String>("text")
                            val dir = File(cacheDir, "shares").apply { mkdirs() }
                            val cutoff = System.currentTimeMillis() - 24L * 60L * 60L * 1000L
                            dir.listFiles()?.forEach { file ->
                                if (file.lastModified() < cutoff) file.delete()
                            }
                            val file = File(dir, fileName)
                            file.writeBytes(bytes)
                            val uri = FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                file
                            )
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "image/png"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                clipData = ClipData.newRawUri("FCBaz card", uri)
                                if (!text.isNullOrBlank()) {
                                    putExtra(Intent.EXTRA_TEXT, text)
                                }
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(Intent.createChooser(intent, "اشتراک‌گذاری کارت FCBaz"))
                            result.success("shared")
                        } catch (error: Exception) {
                            result.error("share_failed", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
