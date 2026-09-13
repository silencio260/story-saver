package com.genrevibes.whatsappstorysaver

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.io.File
import java.security.MessageDigest

/** Fetch metadata in one cursor instead of querying every DocumentFile property. */
class StatusDirectoryChannel(context: Context, messenger: BinaryMessenger) {
    private val discovery = StatusFolderDiscovery(context)
    private val resolver = context.applicationContext.contentResolver
    private val cacheDirectory = File(context.cacheDir, "status_media")
    private val executor = Executors.newFixedThreadPool(3)
    private val main = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(messenger, "story_saver/status_directory")

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method == "discover") {
                val uri = call.argument<String>("uri")
                if (uri == null) result.error("INVALID_ARGUMENT", "Missing folder", null)
                else executor.execute {
                    try {
                        val folders = discovery.find(uri, if (call.argument<Boolean>("business") == true) "business" else "regular")
                        main.post { result.success(folders) }
                    } catch (error: Exception) {
                        main.post { result.error("STATUS_DISCOVERY", error.message, null) }
                    }
                }
            } else if (call.method == "openWhatsApp") {
                val packageName = if (call.argument<Boolean>("business") == true)
                    "com.whatsapp.w4b" else "com.whatsapp"
                try {
                    val intent = context.packageManager.getLaunchIntentForPackage(packageName)
                    if (intent == null) {
                        result.success(false)
                    } else {
                        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                        context.startActivity(intent)
                        result.success(true)
                    }
                } catch (error: Exception) {
                    result.success(false)
                }
            } else if (call.method == "stat") {
                val rawUri = call.argument<String>("uri")
                if (rawUri == null) {
                    result.error("INVALID_ARGUMENT", "Missing status directory URI", null)
                } else {
                    executor.execute {
                        try {
                            val uri = Uri.parse(rawUri)
                            val projection = arrayOf(
                                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                                DocumentsContract.Document.COLUMN_MIME_TYPE,
                                DocumentsContract.Document.COLUMN_SIZE,
                                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
                            )
                            var entry: Map<String, Any>? = null
                            resolver.query(uri, projection, null, null, null)?.use { cursor ->
                                if (cursor.moveToFirst() && cursor.getString(1) == DocumentsContract.Document.MIME_TYPE_DIR) {
                                    entry = mapOf(
                                        "uri" to rawUri,
                                        "name" to (cursor.getString(0) ?: ".Statuses"),
                                        "type" to DocumentsContract.Document.MIME_TYPE_DIR,
                                        "size" to cursor.getLong(2),
                                        "lastModified" to cursor.getLong(3),
                                        "exists" to true, "canRead" to true,
                                        "canWrite" to false, "canDelete" to false,
                                        "canCreate" to false, "canThumbnail" to false,
                                    )
                                }
                            }
                            main.post { result.success(entry) }
                        } catch (error: Exception) {
                            main.post { result.error("STATUS_DIRECTORY", error.message, null) }
                        }
                    }
                }
            } else if (call.method == "cache") {
                val rawUri = call.argument<String>("uri")
                if (rawUri == null) {
                    result.error("INVALID_ARGUMENT", "Missing status URI", null)
                } else {
                    val modified = call.argument<Number>("modified")?.toLong() ?: 0L
                    val size = call.argument<Number>("size")?.toLong() ?: 0L
                    val name = call.argument<String>("name") ?: "status"
                    executor.execute {
                        try {
                            val key = "$rawUri:$modified:$size"
                            val hash = MessageDigest.getInstance("SHA-256")
                                .digest(key.toByteArray()).joinToString("") { "%02x".format(it) }
                            cacheDirectory.mkdirs()
                            val versionDirectory = File(cacheDirectory, hash).apply { mkdirs() }
                            val target = File(versionDirectory, File(name).name)
                            if (!target.exists() || (size > 0 && target.length() != size)) {
                                val temporary = File.createTempFile("copy_", ".tmp", cacheDirectory)
                                try {
                                    resolver.openInputStream(Uri.parse(rawUri))?.use { input ->
                                        temporary.outputStream().use { output -> input.copyTo(output) }
                                    } ?: throw IllegalStateException("Cannot read status")
                                    if (size > 0 && temporary.length() != size) {
                                        throw IllegalStateException("Incomplete status copy")
                                    }
                                    if (!temporary.renameTo(target)) throw IllegalStateException("Cannot cache status")
                                } finally {
                                    temporary.delete()
                                }
                            }
                            main.post { result.success(target.absolutePath) }
                        } catch (error: Exception) {
                            main.post { result.error("STATUS_CACHE", error.message, null) }
                        }
                    }
                }
            } else if (call.method != "list") {
                result.notImplemented()
            } else {
                val rawUri = call.argument<String>("uri")
                if (rawUri == null) {
                    result.error("INVALID_ARGUMENT", "Missing status directory URI", null)
                } else {
                    executor.execute {
                        try {
                            val uri = Uri.parse(rawUri)
                            val documentId = DocumentsContract.getDocumentId(uri)
                            val children = DocumentsContract.buildChildDocumentsUriUsingTree(uri, documentId)
                            val projection = arrayOf(
                                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                                DocumentsContract.Document.COLUMN_MIME_TYPE,
                                DocumentsContract.Document.COLUMN_SIZE,
                                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
                            )
                            val entries = ArrayList<Map<String, Any>>()
                            val cursor = resolver.query(children, projection, null, null, null)
                                ?: throw IllegalStateException("Status provider returned no cursor")
                            cursor.use {
                                while (it.moveToNext()) {
                                    val type = it.getString(2) ?: continue
                                    if (!type.startsWith("image/") && !type.startsWith("video/")) continue
                                    val id = it.getString(0) ?: continue
                                    entries.add(mapOf(
                                        "uri" to DocumentsContract.buildDocumentUriUsingTree(uri, id).toString(),
                                        "name" to (it.getString(1) ?: ""),
                                        "type" to type,
                                        "size" to it.getLong(3),
                                        "lastModified" to it.getLong(4),
                                        "exists" to true, "canRead" to true,
                                        "canWrite" to false, "canDelete" to false,
                                        "canCreate" to false, "canThumbnail" to false,
                                    ))
                                }
                            }
                            main.post { result.success(entries) }
                        } catch (error: Exception) {
                            main.post { result.error("STATUS_DIRECTORY", error.message, null) }
                        }
                    }
                }
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }
}
