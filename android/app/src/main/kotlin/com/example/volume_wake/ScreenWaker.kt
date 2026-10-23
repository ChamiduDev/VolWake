package com.example.volume_wake

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log

/**
 * ScreenWaker combines WakeLock, Haptic feedback, and WakeActivity to turn on
 * the display even when the device is locked or in deep sleep.
 */
object ScreenWaker {
    private const val TAG = "ScreenWaker"
    private var lastWakeTime = 0L

    @Suppress("DEPRECATION")
    fun wake(context: Context) {
        val now = System.currentTimeMillis()
        if (now - lastWakeTime < 1200) {
            // Debounce rapid volume clicks
            return
        }
        lastWakeTime = now
        Log.d(TAG, "ScreenWaker triggering screen wake on ${Build.MANUFACTURER} ${Build.MODEL}...")

        try {
            // 1. Tactile feedback (vibrate 50ms) to confirm the key was detected
            try {
                val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                if (vibrator?.hasVibrator() == true) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        vibrator.vibrate(VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE))
                    } else {
                        vibrator.vibrate(50)
                    }
                }
            } catch (ve: Exception) {
                Log.w(TAG, "Vibration skipped: ${ve.message}")
            }

            // 2. Hardware WakeLock with ACQUIRE_CAUSES_WAKEUP
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = pm.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK
                        or PowerManager.ACQUIRE_CAUSES_WAKEUP
                        or PowerManager.ON_AFTER_RELEASE,
                "VolumeWake::ScreenWaker"
            )
            wakeLock.acquire(4000L) // hold for 4 seconds

            // 3. Launch WakeActivity (needed for Android 8.1 / Vivo Funtouch OS to light up the display over lockscreen)
            val intent = Intent(context, WakeActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_NO_ANIMATION or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                )
            }
            context.startActivity(intent)
            Log.d(TAG, "ScreenWaker successfully triggered WakeActivity and WakeLock")
        } catch (e: Exception) {
            Log.e(TAG, "Error in ScreenWaker: ${e.message}", e)
        }
    }
}
