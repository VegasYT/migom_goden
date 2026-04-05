package com.migom.courier_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class NotificationActionReceiver : BroadcastReceiver() {

    companion object {
        const val CHANNEL = "com.migom.courier_app/notifications"
        const val ACTION_ACCEPT   = "com.migom.courier_app.ORDER_ACCEPT"
        const val ACTION_DECLINE  = "com.migom.courier_app.ORDER_DECLINE"
        const val ACTION_PICKED_UP  = "com.migom.courier_app.ORDER_PICKED_UP"
        const val ACTION_DELIVERED  = "com.migom.courier_app.ORDER_DELIVERED"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        // Bring app to foreground
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP }
        if (launchIntent != null) context.startActivity(launchIntent)

        // Forward event to Flutter via cached engine
        val engine = FlutterEngineCache.getInstance().get("main_engine") ?: return
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        when (action) {
            ACTION_ACCEPT    -> channel.invokeMethod("orderAccept", null)
            ACTION_DECLINE   -> channel.invokeMethod("orderDecline", null)
            ACTION_PICKED_UP -> channel.invokeMethod("orderPickedUp", null)
            ACTION_DELIVERED -> channel.invokeMethod("orderDelivered", null)
        }
    }
}
