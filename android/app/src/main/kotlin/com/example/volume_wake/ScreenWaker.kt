package com.example.volume_wake

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

/**
 * ScreenWaker combines WakeLock, Haptic feedback, and WakeActivity to illuminate
 * the display across Android versions (Android 8.0 through Android 15+) and diverse OEM skins.
 */
object ScreenWaker {
    private const val TAG = "ScreenWaker"
    private var lastWakeTime = 0L

    @Suppress("DEPRECATION")
    fun wake(context: Context) {
        val now = System.currentTimeMillis()
        if (now - lastWakeTime < 1000) {
            // Debounce rapid volume clicks (1000ms threshold)
            return
        }
        lastWakeTime = now
        Log.d(TAG, "ScreenWaker triggering wake on ${Build.MANUFACTURER} ${Build.MODEL} (Android ${Build.VERSION.RELEASE}, API ${Build.VERSION.SDK_INT})")

        try {
            // 1. Tactile feedback (50ms vibration) to confirm button press was received
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                    vm?.defaultVibrator?.vibrate(VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE))
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                    vibrator?.vibrate(VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                    vibrator?.vibrate(50)
                }
            } catch (ve: Exception) {
                Log.w(TAG, "Vibration feedback skipped: ${ve.message}")
            }

            // 2. Hardware WakeLock with ACQUIRE_CAUSES_WAKEUP and ON_AFTER_RELEASE
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = pm.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK
                        or PowerManager.ACQUIRE_CAUSES_WAKEUP
                        or PowerManager.ON_AFTER_RELEASE,
                "VolWake::ScreenWaker"
            )
            wakeLock.acquire(3500L) // hold for 3.5 seconds

            // 3. Launch WakeActivity (needed for Android 8.0+ to light up lockscreen & show over keyguard)
            val intent = Intent(context, WakeActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_NO_ANIMATION or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                )
            }
            context.startActivity(intent)
            Log.d(TAG, "ScreenWaker successfully dispatched WakeLock and WakeActivity")
        } catch (e: Exception) {
            Log.e(TAG, "Error in ScreenWaker: ${e.message}", e)
        }
    }
}
