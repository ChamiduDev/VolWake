package com.example.volume_wake

import android.accessibilityservice.AccessibilityService
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.VolumeProvider
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.PowerManager
import android.util.Log
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent
import androidx.core.app.NotificationCompat

class VolumeWakeService : AccessibilityService() {

    companion object {
        private const val TAG = "VolumeWakeService"
        private const val CHANNEL_ID = "volwake_channel"
        private const val NOTIFICATION_ID = 1001
    }

    private lateinit var powerManager: PowerManager
    private var mediaSession: MediaSession? = null
    private var audioTrack: AudioTrack? = null
    private var isPlayingSilence = false
    private var isReceiverRegistered = false

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    Log.d(TAG, "Screen OFF detected: activating volume routing mechanism")
                    startScreenOffVolumeListener()
                }
                Intent.ACTION_SCREEN_ON, Intent.ACTION_USER_PRESENT -> {
                    Log.d(TAG, "Screen ON detected: pausing background volume routing")
                    stopScreenOffVolumeListener()
                }
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        startForegroundWithNotification()
        setupMediaSession()
        registerScreenReceiver()

        // If screen is currently off when service connects
        if (!powerManager.isInteractive) {
            startScreenOffVolumeListener()
        }
    }

    private fun registerScreenReceiver() {
        if (!isReceiverRegistered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_USER_PRESENT)
            }
            registerReceiver(screenReceiver, filter)
            isReceiverRegistered = true
        }
    }

    private fun setupMediaSession() {
        if (mediaSession != null) return

        try {
            mediaSession = MediaSession(this, "VolWakeMediaSession").apply {
                // Set remote volume provider to intercept volume up/down
                val volumeProvider = object : VolumeProvider(VOLUME_CONTROL_RELATIVE, 100, 50) {
                    override fun onAdjustVolume(direction: Int) {
                        Log.d(TAG, "Volume adjusted: direction=$direction (screen interactive=${powerManager.isInteractive})")
                        // If screen is off, wake the screen!
                        if (!powerManager.isInteractive) {
                            ScreenWaker.wake(this@VolumeWakeService)
                        }
                    }
                }
                setPlaybackToRemote(volumeProvider)

                val playbackState = PlaybackState.Builder()
                    .setState(PlaybackState.STATE_PLAYING, 0L, 1.0f)
                    .setActions(PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE)
                    .build()
                setPlaybackState(playbackState)
                setCallback(object : MediaSession.Callback() {})
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup MediaSession: ${e.message}", e)
        }
    }

    private fun startScreenOffVolumeListener() {
        try {
            setupMediaSession()
            mediaSession?.isActive = true
            startSilentAudio()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start screen-off volume listener: ${e.message}", e)
        }
    }

    private fun stopScreenOffVolumeListener() {
        try {
            stopSilentAudio()
            mediaSession?.isActive = false
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop screen-off volume listener: ${e.message}", e)
        }
    }

    /**
     * Loops a silent PCM buffer in hardware using static mode.
     * This forces the Android audio subsystem to recognize the app as playing media
     * and forward hardware volume key events while the screen is dark.
     */
    private fun startSilentAudio() {
        if (isPlayingSilence) return

        try {
            val sampleRate = 8000
            val minBufferSize = AudioTrack.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )
            val bufferSize = if (minBufferSize > 0) minBufferSize else 2048

            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()

            val audioFormat = AudioFormat.Builder()
                .setSampleRate(sampleRate)
                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .build()

            audioTrack = AudioTrack.Builder()
                .setAudioAttributes(audioAttributes)
                .setAudioFormat(audioFormat)
                .setBufferSizeInBytes(bufferSize)
                .setTransferMode(AudioTrack.MODE_STATIC)
                .build()

            val silentBuffer = ByteArray(bufferSize) // PCM zeroes
            audioTrack?.write(silentBuffer, 0, silentBuffer.size)
            audioTrack?.setLoopPoints(0, bufferSize / 2, -1)
            audioTrack?.play()
            isPlayingSilence = true
            Log.d(TAG, "Silent audio loop active for hardware key routing")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start silent audio: ${e.message}", e)
        }
    }

    private fun stopSilentAudio() {
        if (!isPlayingSilence) return

        try {
            audioTrack?.pause()
            audioTrack?.flush()
            audioTrack?.stop()
            audioTrack?.release()
            audioTrack = null
            isPlayingSilence = false
            Log.d(TAG, "Silent audio stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop silent audio: ${e.message}", e)
        }
    }

    // Direct fallback for Android devices or situations where AccessibilityService onKeyEvent fires
    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN) {
            val keyCode = event.keyCode
            if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
                if (!powerManager.isInteractive) {
                    ScreenWaker.wake(this)
                    return true // Consume event
                }
            }
        }
        return super.onKeyEvent(event)
    }

    private fun startForegroundWithNotification() {
        createNotificationChannel()

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent ?: Intent(),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("VolWake is active")
            .setContentText("Press Volume Up / Down to wake screen")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(pendingIntent)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val serviceTypes = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK or ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            } else {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            }
            startForeground(NOTIFICATION_ID, notification, serviceTypes)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VolWake Background Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps VolWake active to intercept volume keys when screen is off"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        stopScreenOffVolumeListener()
        mediaSession?.release()
        mediaSession = null
        if (isReceiverRegistered) {
            try {
                unregisterReceiver(screenReceiver)
            } catch (e: Exception) {
                // Ignore
            }
            isReceiverRegistered = false
        }
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not used
    }

    override fun onInterrupt() {
        // Not used
    }
}
