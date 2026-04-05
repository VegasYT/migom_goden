package com.migom.courier_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {

    private val channel = NotificationActionReceiver.CHANNEL

    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine {
        // Reuse cached engine so NotificationActionReceiver can reach it
        return FlutterEngineCache.getInstance().get("main_engine")
            ?: FlutterEngine(context).also { engine ->
                engine.dartExecutor.executeDartEntrypoint(
                    io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint.createDefault()
                )
                FlutterEngineCache.getInstance().put("main_engine", engine)
            }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register in cache so BroadcastReceiver can also use it
        FlutterEngineCache.getInstance().put("main_engine", flutterEngine)
    }
}
