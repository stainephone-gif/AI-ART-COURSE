package com.sleepwell.app.data

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class AlarmStorage(context: Context) {
    private val prefs = context.getSharedPreferences("sleepwell", Context.MODE_PRIVATE)
    private val gson  = Gson()

    fun loadAlarms(): MutableList<Alarm> {
        val json = prefs.getString("alarms", null) ?: return mutableListOf()
        val type = object : TypeToken<MutableList<Alarm>>() {}.type
        return gson.fromJson(json, type) ?: mutableListOf()
    }

    fun saveAlarms(list: List<Alarm>) =
        prefs.edit().putString("alarms", gson.toJson(list)).apply()

    fun loadRecords(): MutableList<SleepRecord> {
        val json = prefs.getString("records", null) ?: return mutableListOf()
        val type = object : TypeToken<MutableList<SleepRecord>>() {}.type
        return gson.fromJson(json, type) ?: mutableListOf()
    }

    fun saveRecords(list: List<SleepRecord>) =
        prefs.edit().putString("records", gson.toJson(list)).apply()

    fun saveSleepStart(ms: Long) = prefs.edit().putLong("sleep_start", ms).apply()
    fun loadSleepStart(): Long  = prefs.getLong("sleep_start", 0L)
    fun clearSleepStart()       = prefs.edit().remove("sleep_start").apply()
}
