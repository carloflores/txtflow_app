package com.carlodflores.txtflow

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.provider.Telephony
import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import android.telephony.SmsManager
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
            when (call.method) {
                "openDefaultSmsSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
                        if (roleManager.isRoleAvailable(RoleManager.ROLE_SMS)) {
                            val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS)
                            startActivityForResult(intent, REQUEST_CODE_DEFAULT_SMS)
                            result.success(true)
                        } else {
                            openDefaultSmsSettingsLegacy(result)
                        }
                    } else {
                        openDefaultSmsSettingsLegacy(result)
                    }
                }
                "isDefaultSmsApp" -> {
                    val defaultSmsPackage = Telephony.Sms.getDefaultSmsPackage(context)
                    result.success(defaultSmsPackage == packageName)
                }
                "getSystemPhoneNumber" -> {
                    try {
                        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as android.telephony.TelephonyManager
                        val number = telephonyManager.line1Number
                        result.success(number)
                    } catch (e: SecurityException) {
                        result.error("PERMISSION_DENIED", "Missing permissions", null)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not get phone number", null)
                    }
                }
                "getSimCards" -> {
                    try {
                        val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
                        val subscriptions = subscriptionManager.activeSubscriptionInfoList
                        
                        if (subscriptions == null) {
                            result.success(listOf<Map<String, Any?>>())
                            return@setMethodCallHandler
                        }
                        
                        val simCards = subscriptions.map { sub ->
                            mapOf(
                                "subscriptionId" to sub.subscriptionId,
                                "simSlotIndex" to sub.simSlotIndex,
                                "carrierName" to sub.carrierName.toString(),
                                "displayName" to sub.displayName.toString(),
                                "phoneNumber" to (sub.number ?: ""),
                                "iccId" to (sub.iccId ?: ""),
                                "countryIso" to (sub.countryIso ?: "")
                            )
                        }
                        result.success(simCards)
                    } catch (e: SecurityException) {
                        result.error("PERMISSION_DENIED", "Missing READ_PHONE_STATE permission", null)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not get SIM cards: ${e.message}", null)
                    }
                }
                "sendSmsWithSim" -> {
                    try {
                        val to = call.argument<String>("to") ?: ""
                        val message = call.argument<String>("message") ?: ""
                        val subscriptionId = call.argument<Int>("subscriptionId") ?: -1
                        
                        if (to.isEmpty() || message.isEmpty()) {
                            result.error("INVALID_ARGUMENTS", "to and message are required", null)
                            return@setMethodCallHandler
                        }
                        
                        val smsManager = if (subscriptionId != -1 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                            SmsManager.getSmsManagerForSubscriptionId(subscriptionId)
                        } else {
                            SmsManager.getDefault()
                        }
                        
                        // Check if multipart is needed
                        if (message.length > 160) {
                            val parts = smsManager.divideMessage(message)
                            smsManager.sendMultipartTextMessage(to, null, parts, null, null)
                        } else {
                            smsManager.sendTextMessage(to, null, message, null, null)
                        }
                        
                        result.success(true)
                    } catch (e: SecurityException) {
                        result.error("PERMISSION_DENIED", "Missing SEND_SMS permission", null)
                    } catch (e: Exception) {
                        result.error("SEND_FAILED", "Could not send SMS: ${e.message}", null)
                    }
                }
                "getDefaultSimSubscriptionId" -> {
                    try {
                        val subscriptionId = SmsManager.getDefaultSmsSubscriptionId()
                        result.success(subscriptionId)
                    } catch (e: Exception) {
                        result.success(-1)
                    }
                }
                else -> {
                    result.notImplemented()
                }
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
