package com.carlodflores.txtflow

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.provider.Telephony
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.carlodflores.txtflow/settings"
    private val REQUEST_CODE_DEFAULT_SMS = 1001

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "openDefaultSmsSettings") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
                    if (roleManager.isRoleAvailable(RoleManager.ROLE_SMS)) {
                        val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS)
                        startActivityForResult(intent, REQUEST_CODE_DEFAULT_SMS)
                        result.success(true)
                    } else {
                        // Fallback for devices where role is not available (unlikely for phones)
                        openDefaultSmsSettingsLegacy(result)
                    }
                } else {
                    openDefaultSmsSettingsLegacy(result)
                }
            } else if (call.method == "isDefaultSmsApp") {
                val defaultSmsPackage = Telephony.Sms.getDefaultSmsPackage(context)
                result.success(defaultSmsPackage == packageName)
            } else if (call.method == "getSystemPhoneNumber") {
                try {
                    val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as android.telephony.TelephonyManager
                    // Requires READ_PHONE_STATE or READ_SMS permission, which we should have requested.
                    // Note: This often returns null or empty string depending on carrier/SIM.
                    val number = telephonyManager.line1Number
                    result.success(number)
                } catch (e: SecurityException) {
                    result.error("PERMISSION_DENIED", "Missing permissions", null)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Could not get phone number", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openDefaultSmsSettingsLegacy(result: MethodChannel.Result) {
        try {
            val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
            intent.putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, packageName)
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                startActivity(intent)
                result.success(true)
            } catch (e2: Exception) {
                result.error("UNAVAILABLE", "Could not open settings", null)
            }
        }
    }
}
