package com.sleepwell.app.ui.alarms

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import com.sleepwell.app.alarm.AlarmScheduler
import com.sleepwell.app.data.Alarm
import com.sleepwell.app.data.AlarmStorage
import com.sleepwell.app.databinding.FragmentAlarmsBinding
import java.util.Calendar

class AlarmsFragment : Fragment() {

    private var _b: FragmentAlarmsBinding? = null
    private val b get() = _b!!

    private lateinit var storage: AlarmStorage
    private lateinit var adapter: AlarmAdapter
    private val clockHandler = Handler(Looper.getMainLooper())
    private val clockTick = object : Runnable {
        override fun run() {
            updateClock()
            clockHandler.postDelayed(this, 1000)
        }
    }

    override fun onCreateView(i: LayoutInflater, c: ViewGroup?, s: Bundle?): View {
        _b = FragmentAlarmsBinding.inflate(i, c, false)
        return b.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        storage = AlarmStorage(requireContext())

        adapter = AlarmAdapter(
            onToggle = { alarm, enabled -> toggleAlarm(alarm, enabled) },
            onEdit   = { alarm -> openDialog(alarm) },
            onDelete = { alarm -> deleteAlarm(alarm) },
        )
        b.rvAlarms.layoutManager = LinearLayoutManager(requireContext())
        b.rvAlarms.adapter = adapter

        b.fab.setOnClickListener { openDialog(null) }

        refreshList()
    }

    override fun onResume() {
        super.onResume()
        clockHandler.post(clockTick)
    }

    override fun onPause() {
        super.onPause()
        clockHandler.removeCallbacks(clockTick)
    }

    private fun updateClock() {
        val cal = Calendar.getInstance()
        val h   = cal.get(Calendar.HOUR_OF_DAY)
        val m   = cal.get(Calendar.MINUTE)
        val s   = cal.get(Calendar.SECOND)
        b.tvTime.text    = "%02d:%02d".format(h, m)
        b.tvSeconds.text = "%02d".format(s)
        b.tvDate.text    = cal.time.toString().let {
            // "Среда, 21 мая"
            val days    = listOf("Вс","Пн","Вт","Ср","Чт","Пт","Сб")
            val months  = listOf("","янв","фев","мар","апр","мая","июн","июл","авг","сен","окт","ноя","дек")
            val dow     = cal.get(Calendar.DAY_OF_WEEK)
            val day     = cal.get(Calendar.DAY_OF_MONTH)
            val mon     = cal.get(Calendar.MONTH) + 1
            "${days[dow]}, $day ${months[mon]}"
        }
        updateNextHint()
    }

    private fun updateNextHint() {
        val alarms  = storage.loadAlarms().filter { it.enabled }
        if (alarms.isEmpty()) { b.tvNextAlarm.text = "Нет активных будильников"; return }
        val minMs   = alarms.mapNotNull { a ->
            val ms = a.nextTriggerMs() - System.currentTimeMillis()
            if (ms > 0) ms else null
        }.minOrNull() ?: run { b.tvNextAlarm.text = "Нет активных будильников"; return }
        val h = minMs / 3_600_000
        val m = (minMs % 3_600_000) / 60_000
        b.tvNextAlarm.text = if (h > 0) "Следующий через ${h}ч ${m}м" else "Следующий через ${m}м"
    }

    private fun refreshList() {
        val list = storage.loadAlarms()
        adapter.submitList(list.toList())
        b.tvEmpty.visibility = if (list.isEmpty()) View.VISIBLE else View.GONE
    }

    private fun openDialog(alarm: Alarm?) {
        AddEditAlarmDialog(alarm) { saved ->
            val list = storage.loadAlarms().toMutableList()
            val idx  = list.indexOfFirst { it.id == saved.id }
            if (idx >= 0) list[idx] = saved else list.add(saved)
            storage.saveAlarms(list)
            AlarmScheduler.schedule(requireContext(), saved)
            refreshList()
        }.show(parentFragmentManager, "alarm_dialog")
    }

    private fun toggleAlarm(alarm: Alarm, enabled: Boolean) {
        val list = storage.loadAlarms().toMutableList()
        val idx  = list.indexOfFirst { it.id == alarm.id }
        if (idx < 0) return
        val updated = alarm.copy(enabled = enabled)
        list[idx] = updated
        storage.saveAlarms(list)
        if (enabled) AlarmScheduler.schedule(requireContext(), updated)
        else         AlarmScheduler.cancel(requireContext(), updated)
        refreshList()
    }

    private fun deleteAlarm(alarm: Alarm) {
        AlarmScheduler.cancel(requireContext(), alarm)
        val list = storage.loadAlarms().toMutableList()
        list.removeAll { it.id == alarm.id }
        storage.saveAlarms(list)
        refreshList()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _b = null
    }
}
