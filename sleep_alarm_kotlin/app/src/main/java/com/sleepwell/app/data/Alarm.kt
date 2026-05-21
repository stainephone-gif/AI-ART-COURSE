package com.sleepwell.app.data

import java.util.Calendar

data class Alarm(
    val id: Long = System.currentTimeMillis(),
    val hour: Int,
    val minute: Int,
    val label: String = "",
    val enabled: Boolean = true,
    val days: List<Boolean> = List(7) { false },  // Mon=0 .. Sun=6
    val smart: Boolean = false,
    val smartWindowMin: Int = 30,
    val gradual: Boolean = false,
) {
    val timeString: String get() = "%02d:%02d".format(hour, minute)

    fun nextTriggerMs(): Long {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (cal.timeInMillis <= System.currentTimeMillis()) {
            cal.add(Calendar.DAY_OF_YEAR, 1)
        }
        if (days.any { it }) {
            repeat(14) {
                val dow = cal.get(Calendar.DAY_OF_WEEK)
                val idx = (dow - 2 + 7) % 7  // Calendar Sun=1 → Mon=0
                if (days[idx] && cal.timeInMillis > System.currentTimeMillis()) return cal.timeInMillis
                cal.add(Calendar.DAY_OF_YEAR, 1)
            }
        }
        return cal.timeInMillis
    }
}

data class SleepRecord(
    val id: Long = System.currentTimeMillis(),
    val sleepStartMs: Long,
    val wakeMs: Long,
    val quality: Int,
) {
    val durationHours: Float get() = (wakeMs - sleepStartMs) / 3_600_000f
}
