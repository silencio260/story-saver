package com.genrevibes.whatsappstorysaver

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONObject
import java.io.File
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.util.UUID

/**
 * App-owned daily campaign. Android must post and journal the outcome without
 * starting Flutter. Other local notifications still use the shared kit scheduler.
 * Alarms are inexact: no exact-alarm permission or background Flutter timer.
 */
class DailyReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            if (intent.action == DailyReminders.FIRE) {
                DailyReminders.deliver(context, intent.getIntExtra("hour", -1))
            } else {
                DailyReminders.reconcile(context)
            }
        } catch (error: Exception) {
            Log.w("DailyReminders", "Reminder operation failed", error)
            DailyReminders.record(context, "daily_reminder_failed", mapOf("stage" to "receiver"))
        }
    }
}

object DailyReminders {
    const val CHANNEL = "story_saver/daily_reminders"
    const val FIRE = "com.genrevibes.whatsappstorysaver.DAILY_REMINDER"
    const val OPEN = "com.genrevibes.whatsappstorysaver.OPEN_DAILY_REMINDER"
    private const val NOTIFICATION_CHANNEL = "daily_status_reminders"
    private val hours = listOf(11, 18)
    private fun prefs(context: Context) =
        context.getSharedPreferences("daily_status_reminders", Context.MODE_PRIVATE)
    private fun manager(context: Context) =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private fun notificationId(hour: Int) = if (hour == 11) 11001 else 18001

    fun configure(context: Context, values: Map<*, *>) {
        val editor = prefs(context).edit()
            .putBoolean("configured", true)
            .putBoolean("enabled", values["enabled"] == true)
            .putBoolean("analytics_enabled", values["analytics_enabled"] == true)
        for (key in listOf("title", "morning_body", "evening_body", "channel_name")) {
            editor.putString(key, values[key] as? String ?: "")
        }
        check(editor.commit()) { "Unable to persist reminder configuration" }
        reconcile(context)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= 26) {
            val name = prefs(context).getString("channel_name", null)
                ?.takeIf { it.isNotBlank() } ?: "Daily status reminders"
            manager(context).createNotificationChannel(
                NotificationChannel(NOTIFICATION_CHANNEL, name, NotificationManager.IMPORTANCE_DEFAULT)
            )
        }
    }

    fun state(context: Context): Map<String, Any> {
        val osAllowed = Build.VERSION.SDK_INT < 24 || manager(context).areNotificationsEnabled()
        val channelAllowed = Build.VERSION.SDK_INT < 26 ||
            manager(context).getNotificationChannel(NOTIFICATION_CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE
        val p = prefs(context)
        // Persist independently so a Settings change is noticed on the next
        // alarm even if the user never reopens Flutter.
        for ((key, allowed) in mapOf("os_allowed" to osAllowed, "channel_allowed" to channelAllowed)) {
            if (p.contains(key) && p.getBoolean(key, false) != allowed) {
                record(context, if (key == "os_allowed") "notification_permission_changed"
                    else "notification_channel_changed", mapOf(
                    "allowed" to allowed,
                    "previous_allowed" to !allowed,
                    "reason" to "observed",
                    "channel_id" to NOTIFICATION_CHANNEL
                ))
            }
        }
        p.edit().putBoolean("os_allowed", osAllowed)
            .putBoolean("channel_allowed", channelAllowed).apply()
        return mapOf("permission" to osAllowed, "channel_enabled" to channelAllowed)
    }

    fun reconcile(context: Context) {
        if (!prefs(context).getBoolean("configured", false)) return
        ensureChannel(context)
        state(context)
        for (hour in hours) {
            if (prefs(context).getBoolean("enabled", true)) {
                scheduleNext(context, hour)
            } else {
                val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                alarms.cancel(alarmIntent(context, hour))
                manager(context).cancel(notificationId(hour))
            }
        }
    }

    private fun alarmIntent(context: Context, hour: Int): PendingIntent =
        PendingIntent.getBroadcast(context, notificationId(hour),
            Intent(context, DailyReminderReceiver::class.java).setAction(FIRE).putExtra("hour", hour),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    private fun scheduleNext(context: Context, hour: Int, afterDelivery: Boolean = false) {
        val zone = ZoneId.systemDefault()
        val now = ZonedDateTime.now(zone)
        var next = now.toLocalDate().atTime(hour, 0).atZone(zone)
        val alreadyPosted = prefs(context).getString("posted_$hour", null) == now.toLocalDate().toString()
        if (afterDelivery || alreadyPosted || now.hour >= hour + 3) {
            next = now.toLocalDate().plusDays(1).atTime(hour, 0).atZone(zone)
        }
        if (!next.isAfter(now)) next = now.plusSeconds(1)
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (Build.VERSION.SDK_INT >= 23) {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.toInstant().toEpochMilli(), alarmIntent(context, hour))
        } else {
            alarms.set(AlarmManager.RTC_WAKEUP, next.toInstant().toEpochMilli(), alarmIntent(context, hour))
        }
    }

    fun deliver(context: Context, hour: Int) {
        if (hour !in hours || !prefs(context).getBoolean("enabled", false)) return
        // Schedule tomorrow before delivery, including denied-permission paths.
        scheduleNext(context, hour, afterDelivery = true)
        val now = ZonedDateTime.now(ZoneId.systemDefault())
        val date = now.toLocalDate().toString()
        val p = prefs(context)
        if (p.getString("posted_$hour", null) == date) return
        // Do not dump an overnight backlog or fire an old-zone alarm early.
        if (now.hour < hour || now.hour >= hour + 3) {
            record(context, "daily_reminder_skipped", mapOf("hour" to hour, "reason" to "outside_delivery_window"))
            return
        }
        val status = state(context)
        if (status["permission"] != true || status["channel_enabled"] != true) {
            record(context, "daily_reminder_skipped", mapOf("hour" to hour, "reason" to "notifications_disabled"))
            return
        }
        ensureChannel(context)
        val occurrence = "$date-$hour"
        val open = Intent(context, MainActivity::class.java).setAction(OPEN)
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra("reminder_hour", hour).putExtra("reminder_occurrence", occurrence)
        val pendingOpen = PendingIntent.getActivity(context, notificationId(hour), open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val body = p.getString(if (hour == 11) "morning_body" else "evening_body", "") ?: ""
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, NOTIFICATION_CHANNEL)
            else Notification.Builder(context)
        val notification = builder.setSmallIcon(R.drawable.ic_stat_download)
            .setContentTitle(p.getString("title", "Story Saver"))
            .setContentText(body).setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(true).setContentIntent(pendingOpen).build()
        manager(context).notify(notificationId(hour), notification)
        p.edit().putString("posted_$hour", date).apply()
        // This means notify() returned successfully, not that the user saw it.
        record(context, "local_notification_posted", mapOf(
            "notification_id" to notificationId(hour), "campaign_id" to "daily_status_reminders",
            "slot" to hour, "occurrence_id" to occurrence, "success" to true,
            "channel_id" to NOTIFICATION_CHANNEL, "timezone" to now.zone.id
        ))
    }

    fun handleOpen(context: Context, intent: Intent?): Boolean {
        if (intent?.action != OPEN) return false
        val hour = intent.getIntExtra("reminder_hour", -1)
        val occurrence = intent.getStringExtra("reminder_occurrence") ?: return false
        if (hour !in hours || !occurrence.matches(Regex("\\d{4}-\\d{2}-\\d{2}-(11|18)"))) return false
        val p = prefs(context)
        if (p.getString("last_open", null) == occurrence) return false
        p.edit().putString("last_open", occurrence).putBoolean("pending_open", true).apply()
        record(context, "local_notification_opened", mapOf(
            "notification_id" to notificationId(hour), "campaign_id" to "daily_status_reminders",
            "slot" to hour, "occurrence_id" to occurrence
        ))
        return true
    }

    fun takePendingOpen(context: Context): Boolean {
        val p = prefs(context)
        val pending = p.getBoolean("pending_open", false)
        p.edit().putBoolean("pending_open", false).apply()
        return pending
    }

    fun record(context: Context, name: String, fields: Map<String, Any>) {
        if (!prefs(context).getBoolean("analytics_enabled", false)) return
        try {
            val directory = File(context.filesDir, "analytics_pending")
            directory.mkdirs()
            val id = UUID.randomUUID().toString()
            val data = JSONObject().put("name", name)
                .put("occurred_at", Instant.now().toString())
                .put("properties", JSONObject(fields).put("provider", "local").put("platform", "android"))
            val temporary = File(directory, "$id.tmp")
            temporary.writeText(data.toString())
            check(temporary.renameTo(File(directory, "$id.json"))) { "Unable to journal reminder event" }
        } catch (error: Exception) {
            Log.w("DailyReminders", "Unable to journal notification event", error)
        }
    }
}
