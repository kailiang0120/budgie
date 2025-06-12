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
            when (call.method) {
                "checkNotificationAccess" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "requestNotificationAccess" -> {
                    requestNotificationAccess()
                    result.success(null)
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                "startListening" -> {
                    startNotificationListener()
                    result.success(null)
                }
                "stopListening" -> {
                    stopNotificationListener()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Initialize notification listener service connection
        connectToNotificationListener()
        
        Log.d(TAG, "Flutter engine configured, notification listener initialized")
    }
    
    override fun onResume() {
        super.onResume()
        // Reconnect to notification listener on activity resume
        connectToNotificationListener()
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
            }
        } else {
            Log.e(TAG, "Cannot start listening - notification listener service not available")
            
            // Try to connect one more time after a delay
            android.os.Handler().postDelayed({
                notificationListener = NotificationListener.getInstance()
                if (notificationListener != null && methodChannel != null) {
                    notificationListener?.setMethodChannel(methodChannel!!)
                    notificationListener?.startListening()
                    Log.d(TAG, "Started notification listener after delay")
                } else {
                    Log.e(TAG, "Still cannot start listening after delay")
                }
            }, 1000)
        }
    }

    override fun onStart() {
        super.onStart()
        // Ensure notification listener is started when app comes to foreground
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
