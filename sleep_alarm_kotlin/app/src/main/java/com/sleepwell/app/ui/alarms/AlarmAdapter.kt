package com.sleepwell.app.ui.alarms

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.sleepwell.app.data.Alarm
import com.sleepwell.app.databinding.ItemAlarmBinding

class AlarmAdapter(
    private val onToggle: (Alarm, Boolean) -> Unit,
    private val onEdit:   (Alarm) -> Unit,
    private val onDelete: (Alarm) -> Unit,
) : ListAdapter<Alarm, AlarmAdapter.VH>(DIFF) {

    inner class VH(private val b: ItemAlarmBinding) : RecyclerView.ViewHolder(b.root) {
        fun bind(alarm: Alarm) {
            b.tvTime.text   = alarm.timeString
            b.tvLabel.text  = alarm.label.ifEmpty { "Без названия" }

            val dayNames = listOf("Пн","Вт","Ср","Чт","Пт","Сб","Вс")
            val activeDays = alarm.days.mapIndexedNotNull { i, on -> if (on) dayNames[i] else null }
            b.tvDays.text = when {
                activeDays.isEmpty() -> "Однократно"
                activeDays.size == 7 -> "Каждый день"
                else                 -> activeDays.joinToString(", ")
            }

            val chips = buildString {
                if (alarm.smart)   append("🧠 Умный  ")
                if (alarm.gradual) append("🌅 Плавный")
            }.trim()
            b.tvChips.text = chips
            b.tvChips.visibility = if (chips.isEmpty()) android.view.View.GONE else android.view.View.VISIBLE

            b.swEnabled.isChecked = alarm.enabled
            b.root.alpha = if (alarm.enabled) 1f else 0.45f

            b.swEnabled.setOnCheckedChangeListener(null)
            b.swEnabled.setOnCheckedChangeListener { _, checked -> onToggle(alarm, checked) }
            b.btnDelete.setOnClickListener { onDelete(alarm) }
            b.root.setOnClickListener { onEdit(alarm) }
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int) =
        VH(ItemAlarmBinding.inflate(LayoutInflater.from(parent.context), parent, false))

    override fun onBindViewHolder(holder: VH, position: Int) = holder.bind(getItem(position))

    companion object {
        val DIFF = object : DiffUtil.ItemCallback<Alarm>() {
            override fun areItemsTheSame(a: Alarm, b: Alarm) = a.id == b.id
            override fun areContentsTheSame(a: Alarm, b: Alarm) = a == b
        }
    }
}
