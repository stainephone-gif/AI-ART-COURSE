package com.sleepwell.app.ui.sounds

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.SeekBar
import androidx.fragment.app.Fragment
import com.sleepwell.app.data.AlarmStorage
import com.sleepwell.app.databinding.FragmentSoundsBinding
import com.sleepwell.app.sound.SoundService

class SoundsFragment : Fragment() {

    private var _b: FragmentSoundsBinding? = null
    private val b get() = _b!!

    private var soundService: SoundService? = null
    private var bound = false
    private var timerMins = 0
    private var timerHandler = Handler(Looper.getMainLooper())
    private var timerRunnable: Runnable? = null

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, service: IBinder) {
            soundService = (service as SoundService.LocalBinder).getService()
            bound = true
            updateUI()
        }
        override fun onServiceDisconnected(name: ComponentName) {
            bound = false
            soundService = null
        }
    }

    override fun onCreateView(i: LayoutInflater, c: ViewGroup?, s: Bundle?): View {
        _b = FragmentSoundsBinding.inflate(i, c, false)
        return b.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val soundCards = mapOf(
            b.cardWhite  to "white",
            b.cardBrown  to "brown",
            b.cardRain   to "rain",
            b.cardForest to "forest",
            b.cardOcean  to "ocean",
            b.cardFan    to "fan",
        )

        soundCards.forEach { (card, type) ->
            card.setOnClickListener { toggleSound(type) }
        }

        b.seekVolume.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(sb: SeekBar, p: Int, u: Boolean) {
                soundService?.volume = p / 100f
            }
            override fun onStartTrackingTouch(sb: SeekBar) {}
            override fun onStopTrackingTouch(sb: SeekBar) {}
        })

        val timerBtns = mapOf(
            b.btnTimer0  to 0,
            b.btnTimer15 to 15,
            b.btnTimer30 to 30,
            b.btnTimer60 to 60,
            b.btnTimer90 to 90,
        )
        timerBtns.forEach { (btn, mins) ->
            btn.setOnClickListener {
                timerMins = mins
                timerBtns.keys.forEach { it.isSelected = false }
                btn.isSelected = true
                if (soundService?.isPlaying() == true) startTimer()
                else b.tvTimerStatus.text = if (mins == 0) "Не выключать" else "$mins мин"
            }
        }
    }

    override fun onStart() {
        super.onStart()
        Intent(requireContext(), SoundService::class.java).also { intent ->
            requireContext().bindService(intent, connection, Context.BIND_AUTO_CREATE)
        }
    }

    override fun onStop() {
        super.onStop()
        if (bound) {
            requireContext().unbindService(connection)
            bound = false
        }
    }

    private fun toggleSound(type: String) {
        val svc = soundService ?: run {
            // Start service then bind
            val intent = Intent(requireContext(), SoundService::class.java)
            requireContext().startService(intent)
            requireContext().bindService(intent, connection, Context.BIND_AUTO_CREATE)
            return
        }

        if (svc.isPlaying() && svc.currentSound() == type) {
            svc.stopSound()
            AlarmStorage(requireContext()).clearSleepStart()
        } else {
            svc.playSound(type)
            AlarmStorage(requireContext()).saveSleepStart(System.currentTimeMillis())
            if (timerMins > 0) startTimer()
        }
        updateUI()
    }

    private fun updateUI() {
        val svc = soundService ?: return
        val playing = svc.isPlaying()
        val current = svc.currentSound()

        val cards = mapOf(
            "white"  to b.cardWhite,
            "brown"  to b.cardBrown,
            "rain"   to b.cardRain,
            "forest" to b.cardForest,
            "ocean"  to b.cardOcean,
            "fan"    to b.cardFan,
        )
        cards.forEach { (type, card) ->
            card.isSelected = playing && type == current
        }
        b.seekVolume.visibility = if (playing) View.VISIBLE else View.GONE
    }

    private fun startTimer() {
        timerRunnable?.let { timerHandler.removeCallbacks(it) }
        if (timerMins == 0) { b.tvTimerStatus.text = "Не выключать"; return }

        var remaining = timerMins * 60
        val tick = object : Runnable {
            override fun run() {
                if (_b == null) return
                remaining--
                val m = remaining / 60; val s = remaining % 60
                b.tvTimerStatus.text = "Выкл. через %d:%02d".format(m, s)
                if (remaining > 0) timerHandler.postDelayed(this, 1000)
                else {
                    soundService?.stopSound()
                    b.tvTimerStatus.text = "Не выключать"
                    updateUI()
                }
            }
        }
        timerRunnable = tick
        timerHandler.postDelayed(tick, 1000)
    }

    override fun onDestroyView() {
        super.onDestroyView()
        timerRunnable?.let { timerHandler.removeCallbacks(it) }
        _b = null
    }
}
