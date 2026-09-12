package com.genrevibes.whatsappstorysaver

import io.flutter.embedding.android.FlutterFragmentActivity

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "video_thumbnail"
    private var statusDirectoryChannel: StatusDirectoryChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        statusDirectoryChannel = StatusDirectoryChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getThumbnail") {
                val videoPath: String? = call.argument("videoPath")
                if (videoPath != null) {
                    val thumbnail = generateThumbnail(videoPath)
                    if (thumbnail != null) {
                        result.success(thumbnail)
                    } else {
                        result.error("UNAVAILABLE", "Thumbnail generation failed", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Video path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        statusDirectoryChannel?.dispose()
        statusDirectoryChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun generateThumbnail(videoPath: String): ByteArray? {
        if (videoPath.isNullOrEmpty()) {
            return null  // Return null if videoPath is invalid
        }

        return try {
            val retriever = MediaMetadataRetriever()
            retriever.setDataSource(videoPath)
            val bitmap = retriever.getFrameAtTime(0) // Get the first frame

            if (bitmap == null) {
                return null  // Return null if bitmap extraction fails
            }

            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, 8, stream) // Compress to JPEG
            retriever.release()
            stream.toByteArray()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

}


