package com.sleepwell.app.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.sleepwell.app.data.AlarmStorage
import com.sleepwell.app.data.Alarm

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                // Re-schedule all enabled alarms after reboot
                val storage = AlarmStorage(context)
                AlarmScheduler.scheduleAll(context, storage.loadAlarms())
                return
            }
        }

        val ringIntent = Intent(context, AlarmRingActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("alarm_id",      intent.getLongExtra("alarm_id", 0))
            putExtra("alarm_hour",    intent.getIntExtra("alarm_hour", 0))
            putExtra("alarm_minute",  intent.getIntExtra("alarm_minute", 0))
            putExtra("alarm_label",   intent.getStringExtra("alarm_label") ?: "")
            putExtra("alarm_gradual", intent.getBooleanExtra("alarm_gradual", false))
            putExtra("alarm_days",    intent.getBooleanArrayExtra("alarm_days"))
        }
        context.startActivity(ringIntent)
    }
}
