package com.kai.budgie

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.text.TextUtils
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import android.os.Build
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.kai.budgie/notification_listener"
    private var notificationListener: NotificationListener? = null
    private var methodChannel: MethodChannel? = null
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Create method channel for communication with Flutter
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getAndroidSdkVersion" -> {
                        Log.d(TAG, "getAndroidSdkVersion called, returning: ${Build.VERSION.SDK_INT}")
                        result.success(Build.VERSION.SDK_INT)
                    }
                    "checkNotificationAccess" -> {
                        val isEnabled = isNotificationServiceEnabled()
                        Log.d(TAG, "checkNotificationAccess called, returning: $isEnabled")
                        result.success(isEnabled)
                    }
                    "requestNotificationAccess" -> {
                        Log.d(TAG, "requestNotificationAccess called")
                        requestNotificationAccess()
                        result.success(null)
                    }
                    "openNotificationSettings" -> {
                        Log.d(TAG, "openNotificationSettings called")
                        openNotificationSettings()
                        result.success(null)
                    }
                    "startListening" -> {
                        Log.d(TAG, "startListening called")
                        startNotificationListener()
                        result.success(null)
                    }
                    "stopListening" -> {
                        Log.d(TAG, "stopListening called")
                        stopNotificationListener()
                        result.success(null)
                    }
                    "isNotificationServiceEnabled" -> {
                        val isEnabled = isNotificationServiceEnabled()
                        Log.d(TAG, "isNotificationServiceEnabled called, returning: $isEnabled")
                        result.success(isEnabled)
                    }
                    else -> {
                        Log.w(TAG, "Unknown method called: ${call.method}")
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling method call: ${call.method}", e)
                result.error("METHOD_ERROR", "Error handling method call: ${call.method}", e.message)
            }
        }
        
        // Initialize notification listener service connection
        connectToNotificationListener()
        
        Log.d(TAG, "Flutter engine configured, notification listener initialized")
    }
    
    override fun onResume() {
        super.onResume()
        // Reconnect to notification listener on activity resume
        Log.d(TAG, "App resumed - reconnecting to notification listener")
        connectToNotificationListener()
        
        // Check if we need to start listening
        if (isNotificationServiceEnabled()) {
            Log.d(TAG, "Notification service is enabled, ensuring listener is active")
            startNotificationListener()
        } else {
            Log.w(TAG, "Notification service is not enabled, user may need to grant permission")
        }
    }
    
    override fun onPause() {
        super.onPause()
        // Ensure the notification listener stays connected even when app is paused
        ensureNotificationListenerConnection()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Try to keep the notification listener connected even when activity is destroyed
        ensureNotificationListenerConnection()
    }
    
    private fun ensureNotificationListenerConnection() {
        if (notificationListener == null) {
            notificationListener = NotificationListener.getInstance()
        }
        
        // Make sure the method channel is set in the listener
        if (notificationListener != null && methodChannel != null) {
            notificationListener?.setMethodChannel(methodChannel!!)
            Log.d(TAG, "Ensured notification listener connection before app state change")
        }
    }
    
    private fun connectToNotificationListener() {
        // Get notification listener instance and connect method channel
        notificationListener = NotificationListener.getInstance()
        if (notificationListener != null && methodChannel != null) {
            notificationListener?.setMethodChannel(methodChannel!!)
            Log.d(TAG, "Connected to existing notification listener service")
            
            // If the app setting indicates listening should be active, ensure it's running
            if (isNotificationServiceEnabled()) {
                notificationListener?.startListening()
                Log.d(TAG, "Automatically started listening as service is enabled")
            }
        } else {
            Log.d(TAG, "Notification listener service not yet available: " +
                  "listener=${notificationListener != null}, channel=${methodChannel != null}")
            
            // If channel exists but service doesn't, try again shortly
            if (methodChannel != null) {
                android.os.Handler().postDelayed({
                    connectToNotificationListener()
                }, 1000)
            }
        }
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val packageName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!TextUtils.isEmpty(flat)) {
            val names = flat.split(":").toTypedArray()
            for (name in names) {
                val componentName = name.split("/").toTypedArray()
                if (componentName.size == 2 && componentName[0] == packageName) {
                    Log.d(TAG, "Notification listener service is enabled")
                    return true
                }
            }
        }
        Log.d(TAG, "Notification listener service is NOT enabled")
        return false
    }

    private fun requestNotificationAccess() {
        try {
            // Try to open notification listener settings directly using the most reliable intent
            val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            Log.d(TAG, "Opened notification listener settings")
        } catch (e: Exception) {
            try {
                // First fallback: standard notification listener settings
                val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                Log.d(TAG, "Opened notification listener settings (fallback 1)")
            } catch (e2: Exception) {
                try {
                    // Second fallback: notification settings
                    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    Log.d(TAG, "Opened app notification settings (fallback 2)")
                } catch (e3: Exception) {
                    // Final fallback: app details settings
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        intent.data = Uri.parse("package:$packageName")
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        Log.d(TAG, "Opened app details settings (fallback 3)")
                    } catch (e4: Exception) {
                        Log.e(TAG, "Failed to open notification settings", e4)
                    }
                }
            }
        }
    }

    private fun openNotificationSettings() {
        try {
            // Try to open app-specific notification settings first
            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            Log.d(TAG, "Opened app notification settings")
        } catch (e: Exception) {
            try {
                // Fallback to general notification settings
                val intent = Intent("android.settings.NOTIFICATION_SETTINGS").apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                Log.d(TAG, "Opened general notification settings (fallback)")
            } catch (e2: Exception) {
                try {
                    // Final fallback to app details settings
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    Log.d(TAG, "Opened app details settings (final fallback)")
                } catch (e3: Exception) {
                    Log.e(TAG, "Failed to open any notification settings", e3)
                }
            }
        }
    }

    private fun startNotificationListener() {
        // Check and establish connection first
        connectToNotificationListener()
        
        if (notificationListener != null) {
            Log.d(TAG, "Starting notification listener service")
            notificationListener?.startListening()
            
            // Verify the listener is enabled at the system level
            val isEnabled = isNotificationServiceEnabled()
            Log.d(TAG, "Notification service enabled at system level: $isEnabled")
            
            if (!isEnabled) {
                Log.e(TAG, "Notification service is not enabled at the system level")
                // Prompt user to enable service if not already enabled
                requestNotificationAccess()
            } else {
                Log.d(TAG, "Notification service is enabled and listener should be active")
                // Double-check that the listener is actually listening
                if (notificationListener?.isListening == true) {
                    Log.d(TAG, "✅ Notification listener is confirmed to be listening")
                } else {
                    Log.w(TAG, "⚠️ Notification listener service exists but may not be listening")
                }
            }
        } else {
            Log.e(TAG, "Cannot start listening - notification listener service not available")
            
            // Try to connect one more time after a delay
            android.os.Handler().postDelayed({
                Log.d(TAG, "Retrying notification listener connection after delay...")
                notificationListener = NotificationListener.getInstance()
                if (notificationListener != null && methodChannel != null) {
                    notificationListener?.setMethodChannel(methodChannel!!)
                    notificationListener?.startListening()
                    Log.d(TAG, "✅ Started notification listener after delay")
                    
                    // Verify it's working
                    val isEnabled = isNotificationServiceEnabled()
                    Log.d(TAG, "Service enabled after retry: $isEnabled")
                } else {
                    Log.e(TAG, "❌ Still cannot start listening after delay - listener: ${notificationListener != null}, channel: ${methodChannel != null}")
                }
            }, 1000)
        }
    }

    override fun onStart() {
        super.onStart()
        // Ensure notification listener is started when app comes to foreground
        Log.d(TAG, "App started - ensuring notification listener is active")
        startNotificationListener()
    }

    private fun stopNotificationListener() {
        if (notificationListener != null) {
            Log.d(TAG, "Stopping notification listener service")
            notificationListener?.stopListening()
        } else {
            Log.e(TAG, "Cannot stop listening - notification listener service not available")
        }
    }
}
