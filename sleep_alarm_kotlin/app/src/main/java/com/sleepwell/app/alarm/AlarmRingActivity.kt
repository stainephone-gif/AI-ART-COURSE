package com.sleepwell.app.alarm

import android.app.KeyguardManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.NotificationCompat
import com.sleepwell.app.R
import com.sleepwell.app.data.AlarmStorage
import com.sleepwell.app.data.SleepRecord
import com.sleepwell.app.databinding.ActivityRingBinding
import kotlin.math.sin
import kotlin.math.min

class AlarmRingActivity : AppCompatActivity() {

    private lateinit var binding: ActivityRingBinding
    private var audioTrack: AudioTrack? = null
    @Volatile private var playing = false
    private var vibrator: Vibrator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Wake + show over lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            (getSystemService(KEYGUARD_SERVICE) as KeyguardManager)
                .requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }

        binding = ActivityRingBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val hour    = intent.getIntExtra("alarm_hour", 7)
        val minute  = intent.getIntExtra("alarm_minute", 0)
        val label   = intent.getStringExtra("alarm_label")?.ifEmpty { "Будильник" } ?: "Будильник"
        val gradual = intent.getBooleanExtra("alarm_gradual", false)
        val days    = intent.getBooleanArrayExtra("alarm_days")

        binding.tvTime.text  = "%02d:%02d".format(hour, minute)
        binding.tvLabel.text = label

        startBeep(gradual)
        startVibration()

        binding.btnDismiss.setOnClickListener { dismiss() }
        binding.btnSnooze.setOnClickListener  { snooze(hour, minute, label, gradual, days) }
    }

    // ── Audio ─────────────────────────────────────────
    private fun startBeep(gradual: Boolean) {
        playing = true
        Thread {
            val sampleRate = 44100
            val minBuf = AudioTrack.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )
            val bufSize = minBuf * 4
            audioTrack = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .build()
                )
                .setBufferSizeInBytes(bufSize)
                .build()

            audioTrack?.play()

            var elapsed   = 0.0
            val dt        = 1.0 / sampleRate
            var gainLevel = if (gradual) 0.05f else 0.7f
            val gainStep  = if (gradual) 0.65f / (120f * sampleRate / bufSize) else 0f
            val buf       = ShortArray(bufSize)

            while (playing) {
                for (i in buf.indices) {
                    val t = elapsed % 0.6
                    val v = if (t < 0.25) sin(2 * Math.PI * 880.0 * elapsed) else 0.0
                    buf[i] = (v * gainLevel * Short.MAX_VALUE).toInt().toShort()
                    elapsed += dt
                }
                if (gradual) gainLevel = min(gainLevel + gainStep, 0.7f)
                audioTrack?.write(buf, 0, buf.size)
            }
        }.start()
    }

    private fun stopBeep() {
        playing = false
        audioTrack?.stop()
        audioTrack?.release()
        audioTrack = null
    }

    // ── Vibration ─────────────────────────────────────
    private fun startVibration() {
        val pattern = longArrayOf(0, 500, 300, 500)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = getSystemService(VibratorManager::class.java)
            vibrator = vm.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }

    private fun stopVibration() = vibrator?.cancel()

    // ── Actions ───────────────────────────────────────
    private fun dismiss() {
        stopBeep()
        stopVibration()
        recordWake()
        finish()
    }

    private fun snooze(hour: Int, minute: Int, label: String, gradual: Boolean, days: BooleanArray?) {
        stopBeep()
        stopVibration()
        // Reschedule via AlarmManager 10 min from now
        val snoozeAlarm = com.sleepwell.app.data.Alarm(
            id       = System.currentTimeMillis(),
            hour     = hour,
            minute   = minute,
            label    = label,
            enabled  = true,
            days     = days?.toList() ?: List(7) { false },
            gradual  = gradual,
        )
        // Calculate snooze time (10 min from now)
        val snoozeMs = System.currentTimeMillis() + 10 * 60 * 1000L
        val am = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        val pi = PendingIntent.getBroadcast(
            this, snoozeAlarm.id.toInt(),
            Intent(this, AlarmReceiver::class.java).apply {
                action = "com.sleepwell.app.ALARM_TRIGGER"
                putExtra("alarm_id",      snoozeAlarm.id)
                putExtra("alarm_hour",    hour)
                putExtra("alarm_minute",  minute)
                putExtra("alarm_label",   "$label (отложен)")
                putExtra("alarm_gradual", gradual)
            },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, snoozeMs, pi)
        } else {
            am.setExact(android.app.AlarmManager.RTC_WAKEUP, snoozeMs, pi)
        }
        finish()
    }

    private fun recordWake() {
        val storage = AlarmStorage(this)
        val sleepStart = storage.loadSleepStart()
        if (sleepStart > 0) {
            // Will show quality dialog in MainActivity via flag
            getSharedPreferences("sleepwell", MODE_PRIVATE)
                .edit().putBoolean("ask_quality", true).apply()
            storage.clearSleepStart()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopBeep()
        stopVibration()
    }
}
