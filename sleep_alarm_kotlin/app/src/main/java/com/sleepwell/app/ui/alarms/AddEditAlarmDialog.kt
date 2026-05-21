package com.sleepwell.app.ui.alarms

import android.app.Dialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import com.sleepwell.app.data.Alarm
import com.sleepwell.app.databinding.DialogAddAlarmBinding
import java.util.Calendar

class AddEditAlarmDialog(
    private val alarm: Alarm? = null,
    private val onSave: (Alarm) -> Unit,
) : BottomSheetDialogFragment() {

    private var _b: DialogAddAlarmBinding? = null
    private val b get() = _b!!
    private val selectedDays = BooleanArray(7)

    override fun onCreateView(i: LayoutInflater, c: ViewGroup?, s: Bundle?): View {
        _b = DialogAddAlarmBinding.inflate(i, c, false)
        return b.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Pre-fill if editing
        if (alarm != null) {
            b.npHour.value   = alarm.hour
            b.npMinute.value = alarm.minute
            b.etLabel.setText(alarm.label)
            b.swSmart.isChecked   = alarm.smart
            b.swGradual.isChecked = alarm.gradual
            b.sbWindow.progress   = (alarm.smartWindowMin - 10) / 10
            alarm.days.forEachIndexed { i, v -> selectedDays[i] = v }
        } else {
            val cal = Calendar.getInstance()
            b.npHour.value   = cal.get(Calendar.HOUR_OF_DAY)
            b.npMinute.value = (cal.get(Calendar.MINUTE) + 1).coerceAtMost(59)
        }

        b.npHour.minValue   = 0; b.npHour.maxValue   = 23
        b.npMinute.minValue = 0; b.npMinute.maxValue = 59
        b.npHour.setFormatter   { "%02d".format(it) }
        b.npMinute.setFormatter { "%02d".format(it) }

        updateDayButtons()
        updateWindowRow()

        val dayBtns = listOf(b.btnMon, b.btnTue, b.btnWed, b.btnThu, b.btnFri, b.btnSat, b.btnSun)
        dayBtns.forEachIndexed { i, btn ->
            btn.setOnClickListener {
                selectedDays[i] = !selectedDays[i]
                updateDayButtons()
            }
        }

        b.swSmart.setOnCheckedChangeListener { _, _ -> updateWindowRow() }

        b.tvWindowVal.text = "${10 + b.sbWindow.progress * 10} мин"
        b.sbWindow.setOnSeekBarChangeListener(object : android.widget.SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(sb: android.widget.SeekBar, p: Int, u: Boolean) {
                b.tvWindowVal.text = "${10 + p * 10} мин"
            }
            override fun onStartTrackingTouch(sb: android.widget.SeekBar) {}
            override fun onStopTrackingTouch(sb: android.widget.SeekBar) {}
        })

        b.btnSave.setOnClickListener { save() }
        b.btnCancel.setOnClickListener { dismiss() }
    }

    private fun updateDayButtons() {
        val btns = listOf(b.btnMon, b.btnTue, b.btnWed, b.btnThu, b.btnFri, b.btnSat, b.btnSun)
        btns.forEachIndexed { i, btn ->
            btn.isSelected = selectedDays[i]
        }
    }

    private fun updateWindowRow() {
        b.rowSmartWindow.visibility = if (b.swSmart.isChecked) View.VISIBLE else View.GONE
    }

    private fun save() {
        val windowMin = 10 + b.sbWindow.progress * 10
        val saved = Alarm(
            id            = alarm?.id ?: System.currentTimeMillis(),
            hour          = b.npHour.value,
            minute        = b.npMinute.value,
            label         = b.etLabel.text.toString().trim(),
            enabled       = true,
            days          = selectedDays.toList(),
            smart         = b.swSmart.isChecked,
            smartWindowMin= windowMin,
            gradual       = b.swGradual.isChecked,
        )
        onSave(saved)
        dismiss()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _b = null
    }
}
