package com.migom.courier_app

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("7c6b9058-6e80-4064-8992-df0d337247e4")
    }
}
