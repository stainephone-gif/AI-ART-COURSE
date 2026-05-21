package com.sleepwell.app.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.sleepwell.app.data.Alarm

object AlarmScheduler {

    fun schedule(context: Context, alarm: Alarm) {
        if (!alarm.enabled) return
        val pi = pendingIntent(context, alarm)
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerMs = alarm.nextTriggerMs()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pi)
        } else {
            am.setExact(AlarmManager.RTC_WAKEUP, triggerMs, pi)
        }
    }

    fun cancel(context: Context, alarm: Alarm) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pendingIntent(context, alarm))
    }

    fun scheduleAll(context: Context, alarms: List<Alarm>) {
        alarms.forEach { if (it.enabled) schedule(context, it) else cancel(context, it) }
    }

    private fun pendingIntent(context: Context, alarm: Alarm): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.sleepwell.app.ALARM_TRIGGER"
            putExtra("alarm_id",      alarm.id)
            putExtra("alarm_hour",    alarm.hour)
            putExtra("alarm_minute",  alarm.minute)
            putExtra("alarm_label",   alarm.label)
            putExtra("alarm_gradual", alarm.gradual)
            putExtra("alarm_days",    alarm.days.toBooleanArray())
        }
        return PendingIntent.getBroadcast(
            context, alarm.id.toInt(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
