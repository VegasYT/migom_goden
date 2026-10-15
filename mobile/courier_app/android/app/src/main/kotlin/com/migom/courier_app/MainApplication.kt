package com.migom.courier_app

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // ключ задаётся при сборке (android/local.properties или MAPKIT_API_KEY), в репозитории его нет
        MapKitFactory.setApiKey(BuildConfig.MAPKIT_API_KEY)
    }
}
