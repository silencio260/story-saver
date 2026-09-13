package com.genrevibes.whatsappstorysaver

import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract as Docs
import java.util.ArrayDeque

/** Searches only descendants exposed by the user's SAF grant, off the UI thread. */
class StatusFolderDiscovery(context: Context) {
    private val resolver = context.applicationContext.contentResolver
    private val preferences = context.getSharedPreferences("status_folder_locations", Context.MODE_PRIVATE)
    private data class Node(val id: String, val name: String, val business: Boolean)

    @Synchronized
    fun find(rawTree: String, requestedMode: String): Map<String, String> {
        val tree = Uri.parse(rawTree)
        val rootId = Docs.getTreeDocumentId(tree)
        val found = linkedMapOf<String, String>()
        fun document(id: String) = Docs.buildDocumentUriUsingTree(tree, id)
        fun readable(uri: Uri): Boolean = try {
            resolver.query(uri, arrayOf(Docs.Document.COLUMN_MIME_TYPE), null, null, null)?.use {
                it.moveToFirst() && it.getString(0) == Docs.Document.MIME_TYPE_DIR
            } ?: false
        } catch (_: Exception) { false }
        for (mode in listOf("regular", "business")) {
            preferences.getString("$rawTree:$mode", null)?.let {
                if (readable(Uri.parse(it))) found[mode] = it
            }
        }
        // Android external-storage IDs encode the path. Never probe outside
        // the granted subtree, even when the usual target is known.
        if (tree.authority == "com.android.externalstorage.documents" && rootId.contains(':')) {
            val volume = rootId.substringBefore(':')
            val rootPath = rootId.substringAfter(':').trimEnd('/')
            for ((mode, path) in listOf(
                "regular" to "Android/media/com.whatsapp/WhatsApp/Media/.Statuses",
                "business" to "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses",
                "regular" to "WhatsApp/Media/.Statuses",
                "business" to "WhatsApp Business/Media/.Statuses",
            )) {
                if (mode !in found && (rootPath.isEmpty() || path == rootPath || path.startsWith("$rootPath/"))) {
                    val uri = document("$volume:$path")
                    if (readable(uri)) found[mode] = uri.toString()
                }
            }
        }
        if (requestedMode !in found) {
            val queue = ArrayDeque<Node>()
            var rootName = rootId.substringAfterLast('/')
            try {
                resolver.query(document(rootId), arrayOf(Docs.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use {
                    if (it.moveToFirst()) rootName = it.getString(0) ?: rootName
                }
            } catch (_: Exception) { }
            queue.add(Node(rootId, rootName, rootId.contains("w4b", true) || rootId.contains("WhatsApp Business", true)))
            val visited = HashSet<String>()
            while (queue.isNotEmpty() && requestedMode !in found && !Thread.currentThread().isInterrupted) {
                val node = queue.removeFirst()
                if (!visited.add(node.id)) continue
                if (node.name.equals(".Statuses", true)) {
                    val mode = if (node.business) "business" else "regular"
                    val uri = document(node.id)
                    if (mode !in found && readable(uri)) found[mode] = uri.toString()
                    continue // Do not enumerate users' media to discover folders.
                }
                val children = ArrayList<Node>()
                try {
                    resolver.query(Docs.buildChildDocumentsUriUsingTree(tree, node.id), arrayOf(
                        Docs.Document.COLUMN_DOCUMENT_ID, Docs.Document.COLUMN_DISPLAY_NAME,
                        Docs.Document.COLUMN_MIME_TYPE,
                    ), null, null, null)?.use { cursor ->
                        while (cursor.moveToNext()) {
                            if (cursor.getString(2) != Docs.Document.MIME_TYPE_DIR) continue
                            val id = cursor.getString(0) ?: continue
                            val name = cursor.getString(1) ?: ""
                            val business = when {
                                name.equals("com.whatsapp", true) || name.equals("WhatsApp", true) -> false
                                name.contains("w4b", true) || name.equals("WhatsApp Business", true) -> true
                                else -> node.business
                            }
                            children.add(Node(id, name, business))
                        }
                    }
                } catch (_: Exception) { /* One unreadable child must not stop siblings. */ }
                // Search recognizable routes first; all other directories remain eligible.
                for (child in children.sortedByDescending { it.name.contains("whatsapp", true) || it.name.equals("media", true) || it.name.equals(".Statuses", true) }) {
                    queue.addLast(child)
                }

            }
        }
        val editor = preferences.edit()
        for ((mode, uri) in found) editor.putString("$rawTree:$mode", uri)
        editor.apply()
        return found
    }
}
