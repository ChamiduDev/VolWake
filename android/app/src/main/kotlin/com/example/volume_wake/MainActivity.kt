package com.example.volume_wake

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.volumewake/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceInfo" -> {
                        val info = getDeviceInfoMap()
                        result.success(info)
                    }
                    "openSettings" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "openOemAutostart" -> {
                        val opened = openOemAutostartSettings()
                        result.success(opened)
                    }
                    "openBatteryOptimization" -> {
                        openBatterySettings()
                        result.success(true)
                    }
                    "openAppDetails" -> {
                        openAppDetailsSettings()
                        result.success(true)
                    }
                    "openOverlaySettings" -> {
                        openOverlaySettings()
                        result.success(true)
                    }
                    "isAccessibilityEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "isBatteryOptimizationIgnored" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val isIgnored = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            pm.isIgnoringBatteryOptimizations(packageName)
                        } else {
                            true
                        }
                        result.success(isIgnored)
                    }
                    "testWakeScreen" -> {
                        // Delay 3 seconds so the user has time to press the phone screen off and test the wake
                        Handler(Looper.getMainLooper()).postDelayed({
                            ScreenWaker.wake(this)
                        }, 3000)
                        result.success(true)
                    }
                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (!url.isNullOrEmpty()) {
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("OPEN_URL_FAILED", e.message, null)
                            }
                        } else {
                            result.error("INVALID_URL", "URL is null or empty", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getDeviceInfoMap(): Map<String, Any> {
        val (category, romDescription) = detectOemCategory()
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        val isBatteryIgnored = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            pm.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
        val canDrawOverlays = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }

        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "androidRelease" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "oemCategory" to category,
            "romDescription" to romDescription,
            "isAccessibilityEnabled" to isAccessibilityServiceEnabled(),
            "isBatteryOptimizationIgnored" to isBatteryIgnored,
            "canDrawOverlays" to canDrawOverlays
        )
    }

    private fun detectOemCategory(): Pair<String, String> {
        val mfg = Build.MANUFACTURER.lowercase(Locale.ROOT)
        val brand = Build.BRAND.lowercase(Locale.ROOT)

        val category = when {
            mfg.contains("xiaomi") || mfg.contains("redmi") || brand.contains("poco") -> "xiaomi"
            mfg.contains("samsung") -> "samsung"
            mfg.contains("oppo") || mfg.contains("realme") || mfg.contains("oneplus") -> "oppo"
            mfg.contains("vivo") || brand.contains("iqoo") -> "vivo"
            mfg.contains("huawei") || mfg.contains("honor") -> "huawei"
            mfg.contains("transsion") || mfg.contains("infinix") || mfg.contains("tecno") || mfg.contains("itel") -> "transsion"
            mfg.contains("asus") -> "asus"
            mfg.contains("motorola") || brand.contains("moto") -> "motorola"
            mfg.contains("google") -> "google"
            else -> "stock"
        }
        return Pair(category, "Android Device Compatibility")
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedClass = VolumeWakeService::class.java.name
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)

        while (colonSplitter.hasNext()) {
            val componentNameString = colonSplitter.next()
            val enabledComponent = ComponentName.unflattenFromString(componentNameString)
            if (enabledComponent != null && enabledComponent.packageName == packageName &&
                (enabledComponent.className == expectedClass || enabledComponent.className.endsWith("VolumeWakeService"))
            ) {
                return true
            }
        }
        return false
    }

    private fun openOemAutostartSettings(): Boolean {
        val mfg = Build.MANUFACTURER.lowercase(Locale.ROOT)
        val brand = Build.BRAND.lowercase(Locale.ROOT)

        val candidateIntents = mutableListOf<Intent>()

        when {
            // Xiaomi / Redmi / POCO
            mfg.contains("xiaomi") || mfg.contains("redmi") || brand.contains("poco") -> {
                candidateIntents.add(Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.miui.powerkeeper", "com.miui.powerkeeper.ui.HiddenAppsConfigActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.permissions.PermissionsEditorActivity")))
            }

            // Samsung
            mfg.contains("samsung") -> {
                candidateIntents.add(Intent().setComponent(ComponentName("com.samsung.android.lool", "com.samsung.android.sm.battery.ui.BatteryActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.samsung.android.sm", "com.samsung.android.sm.battery.ui.BatteryActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.samsung.android.sm_cn", "com.samsung.android.sm.ui.battery.BatteryActivity")))
            }

            // Oppo / Realme / OnePlus
            mfg.contains("oppo") || mfg.contains("realme") || mfg.contains("oneplus") -> {
                candidateIntents.add(Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.oplus.battery", "com.oplus.battery.AppListActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.oneplus.security", "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity")))
            }

            // Vivo / iQOO
            mfg.contains("vivo") || brand.contains("iqoo") -> {
                candidateIntents.add(Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.PurviewTabActivity")))
            }

            // Huawei / Honor
            mfg.contains("huawei") || mfg.contains("honor") -> {
                candidateIntents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.bootstart.BootStartActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity")))
            }

            // Transsion (Infinix, Tecno, itel)
            mfg.contains("transsion") || mfg.contains("infinix") || mfg.contains("tecno") || mfg.contains("itel") -> {
                candidateIntents.add(Intent().setComponent(ComponentName("com.transsion.phonemanager", "com.transsion.phonemanager.settings.AutoRunListActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.transsion.phonemanager", "com.transsion.phonemanager.view.AutoRunListActivity")))
            }

            // Asus
            mfg.contains("asus") -> {
                candidateIntents.add(Intent().setComponent(ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.entry.FunctionActivity")))
                candidateIntents.add(Intent().setComponent(ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.autostart.AutoStartActivity")))
            }
        }

        for (intent in candidateIntents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                val list = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                if (list.isNotEmpty()) {
                    startActivity(intent)
                    return true
                }
            } catch (_: Exception) {}
        }

        // Fallback: App Details
        return openAppDetailsSettings()
    }

    private fun openAppDetailsSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            openBatterySettings()
            false
        }
    }

    private fun openOverlaySettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
            } catch (_: Exception) {
                openAppDetailsSettings()
            }
        }
    }

    private fun openBatterySettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
            }
        } catch (_: Exception) {
            try {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
            } catch (_: Exception) {}
        }
    }
}
