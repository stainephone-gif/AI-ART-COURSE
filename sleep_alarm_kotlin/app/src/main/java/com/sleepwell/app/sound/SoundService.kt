package com.sleepwell.app.sound

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.sleepwell.app.MainActivity
import com.sleepwell.app.R
import kotlin.math.sin
import kotlin.random.Random

class SoundService : Service() {

    inner class LocalBinder : Binder() {
        fun getService() = this@SoundService
    }

    private val binder    = LocalBinder()
    private var audioTrack: AudioTrack? = null
    @Volatile private var playing  = false
    @Volatile private var soundType = "white"
    @Volatile var volume = 0.7f

    override fun onBind(intent: Intent): IBinder = binder

    fun playSound(type: String) {
        soundType = type
        if (playing) return
        playing = true
        Thread { generateLoop() }.start()
        startForeground()
    }

    fun stopSound() {
        playing = false
        audioTrack?.stop()
        audioTrack?.release()
        audioTrack = null
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    fun isPlaying() = playing
    fun currentSound() = soundType

    private fun generateLoop() {
        val sampleRate = 44100
        val bufSize    = maxOf(AudioTrack.getMinBufferSize(
            sampleRate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT
        ), 4096)

        audioTrack = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build())
            .setAudioFormat(AudioFormat.Builder()
                .setSampleRate(sampleRate)
                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .build())
            .setBufferSizeInBytes(bufSize)
            .build()

        audioTrack?.play()
        val buf = ShortArray(bufSize)

        // State for noise generators
        var brownLast = 0f
        var b0=0f; var b1=0f; var b2=0f; var b3=0f; var b4=0f; var b5=0f
        var sampleIdx = 0L

        while (playing) {
            for (i in buf.indices) {
                val sample = when (soundType) {
                    "white"  -> Random.nextFloat() * 2f - 1f
                    "brown"  -> {
                        val w = Random.nextFloat() * 2f - 1f
                        brownLast = (brownLast + 0.02f * w) / 1.02f
                        brownLast
                    }
                    "fan"    -> {
                        val w = Random.nextFloat() * 2f - 1f
                        b0 = 0.99886f*b0 + w*0.0555179f
                        b1 = 0.99332f*b1 + w*0.0750759f
                        b2 = 0.96900f*b2 + w*0.1538520f
                        b3 = 0.86650f*b3 + w*0.3104856f
                        b4 = 0.55000f*b4 + w*0.5329522f
                        b5 = -0.7616f*b5 - w*0.0168980f
                        (b0+b1+b2+b3+b4+b5+w*0.5362f) / 6f
                    }
                    "rain"   -> {
                        val w = Random.nextFloat() * 2f - 1f
                        brownLast = (brownLast + 0.01f * w) / 1.01f
                        val crackle = if (Random.nextFloat() < 0.001f) w * 0.6f else 0f
                        (brownLast * 2f + crackle).coerceIn(-1f, 1f)
                    }
                    "forest" -> {
                        val rustle = (Random.nextFloat() - 0.5f) * 0.4f
                        val wind   = sin(sampleIdx * 0.003).toFloat() * 0.05f
                        val bird   = if (Random.nextFloat() < 0.002f) sin(sampleIdx * 0.05).toFloat() * 0.3f else 0f
                        rustle + wind + bird
                    }
                    "ocean"  -> {
                        val w = Random.nextFloat() * 2f - 1f
                        brownLast = (brownLast + 0.02f * w) / 1.02f
                        val wave = 0.5f + 0.5f * sin(2 * Math.PI * sampleIdx / (sampleRate * 8.0)).toFloat()
                        (brownLast * wave * 2f).coerceIn(-1f, 1f)
                    }
                    else -> Random.nextFloat() * 2f - 1f
                }
                buf[i] = (sample * volume * Short.MAX_VALUE).toInt().toShort()
                sampleIdx++
            }
            audioTrack?.write(buf, 0, buf.size)
        }
    }

    private fun startForeground() {
        val channelId = "sound_service"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(channelId, "Звуки сна", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(ch)
        }
        val pi = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        val notif = NotificationCompat.Builder(this, channelId)
            .setContentTitle("SleepWell")
            .setContentText("Звук сна воспроизводится")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(pi)
            .setSilent(true)
            .build()
        startForeground(2, notif)
    }

    override fun onDestroy() {
        super.onDestroy()
        stopSound()
    }
}
