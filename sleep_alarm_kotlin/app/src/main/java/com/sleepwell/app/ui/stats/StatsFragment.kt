package com.sleepwell.app.ui.stats

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.fragment.app.Fragment
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.sleepwell.app.R
import com.sleepwell.app.data.AlarmStorage
import com.sleepwell.app.data.SleepRecord
import com.sleepwell.app.databinding.FragmentStatsBinding
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

class StatsFragment : Fragment() {

    private var _b: FragmentStatsBinding? = null
    private val b get() = _b!!
    private lateinit var storage: AlarmStorage

    override fun onCreateView(i: LayoutInflater, c: ViewGroup?, s: Bundle?): View {
        _b = FragmentStatsBinding.inflate(i, c, false)
        return b.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        storage = AlarmStorage(requireContext())
        b.btnRate.setOnClickListener { showQualityDialog() }
    }

    override fun onResume() {
        super.onResume()
        renderStats()
        // Check if we should auto-show quality dialog
        val prefs = requireContext().getSharedPreferences("sleepwell", android.content.Context.MODE_PRIVATE)
        if (prefs.getBoolean("ask_quality", false)) {
            prefs.edit().remove("ask_quality").apply()
            showQualityDialog()
        }
    }

    private fun renderStats() {
        val records = storage.loadRecords().sortedBy { it.sleepStartMs }
        if (records.isEmpty()) {
            b.groupEmpty.visibility   = View.VISIBLE
            b.groupContent.visibility = View.GONE
            return
        }
        b.groupEmpty.visibility   = View.GONE
        b.groupContent.visibility = View.VISIBLE

        val avgDur = records.map { it.durationHours }.average()
        val avgQ   = records.map { it.quality }.average()
        b.tvAvgDur.text     = "%.1f ч".format(avgDur)
        b.tvAvgQuality.text = "%.1f / 5".format(avgQ)
        b.tvCount.text      = "${records.size}"

        // Records list
        b.llRecords.removeAllViews()
        records.reversed().take(10).forEach { rec ->
            addRecordView(rec)
        }
    }

    private fun addRecordView(rec: SleepRecord) {
        val fmt  = SimpleDateFormat("d MMM, HH:mm", Locale("ru"))
        val fmtD = SimpleDateFormat("d MMMM yyyy", Locale("ru"))
        val view = LayoutInflater.from(requireContext())
            .inflate(R.layout.item_record, b.llRecords, false)

        view.findViewById<TextView>(R.id.tvRecordDate).text  = fmtD.format(Date(rec.wakeMs))
        view.findViewById<TextView>(R.id.tvRecordTimes).text =
            "${fmt.format(Date(rec.sleepStartMs))} → ${fmt.format(Date(rec.wakeMs))} (%.1f ч)".format(rec.durationHours)
        view.findViewById<TextView>(R.id.tvRecordStars).text =
            "⭐".repeat(rec.quality) + "☆".repeat(5 - rec.quality)
        view.findViewById<TextView>(R.id.tvRecordEmoji).text =
            listOf("","😩","😔","😐","😊","😄")[rec.quality]

        b.llRecords.addView(view)
    }

    private fun showQualityDialog() {
        var selected = 3
        val dialog = BottomSheetDialog(requireContext())
        val sheet  = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_quality, null)
        dialog.setContentView(sheet)

        val stars = listOf(
            sheet.findViewById<TextView>(R.id.star1),
            sheet.findViewById<TextView>(R.id.star2),
            sheet.findViewById<TextView>(R.id.star3),
            sheet.findViewById<TextView>(R.id.star4),
            sheet.findViewById<TextView>(R.id.star5),
        )
        val tvEmoji = sheet.findViewById<TextView>(R.id.tvQualityEmoji)
        val tvLabel = sheet.findViewById<TextView>(R.id.tvQualityLabel)

        val emojis = listOf("","😩","😔","😐","😊","😄")
        val labels = listOf("","Ужасно","Плохо","Нормально","Хорошо","Отлично")

        fun refresh() {
            tvEmoji.text = emojis[selected]
            tvLabel.text = labels[selected]
            stars.forEachIndexed { i, tv -> tv.alpha = if (i < selected) 1f else 0.3f }
        }
        refresh()

        stars.forEachIndexed { i, tv ->
            tv.setOnClickListener { selected = i + 1; refresh() }
        }

        sheet.findViewById<View>(R.id.btnQualitySave).setOnClickListener {
            val sleepStart = storage.loadSleepStart()
            val record = SleepRecord(
                sleepStartMs = if (sleepStart > 0) sleepStart else System.currentTimeMillis() - 8*3600_000L,
                wakeMs       = System.currentTimeMillis(),
                quality      = selected,
            )
            val list = storage.loadRecords().toMutableList()
            list.add(record)
            storage.saveRecords(list)
            storage.clearSleepStart()
            dialog.dismiss()
            renderStats()
        }
        dialog.show()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _b = null
    }
}
