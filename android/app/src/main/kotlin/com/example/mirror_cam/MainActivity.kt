package com.example.mirror_cam

import android.net.wifi.WifiManager
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mirrorcam/wifi"
    private var wifiLock: WifiManager.WifiLock? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "enableHighPerformance" -> {
                    enableWifiLock()
                    result.success(null)
                }
                "disableHighPerformance" -> {
                    disableWifiLock()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun enableWifiLock() {
        if (wifiLock == null) {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            // WIFI_MODE_FULL_HIGH_PERF (3) gecikmeyi düşürür
            wifiLock = wifiManager.createWifiLock(3, "MirrorCam:WifiLock").apply {
                setReferenceCounted(false)
            }
        }
        wifiLock?.let {
            if (!it.isHeld) {
                it.acquire()
            }
        }
    }

    private fun disableWifiLock() {
        wifiLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
    }

    override fun onPause() {
        super.onPause()
        disableWifiLock() // App arka plana atılınca kilidi bırak (pil tasarrufu)
    }

    override fun onResume() {
        super.onResume()
        // App tekrar öne gelince, eğer Flutter tarafı daha önce kilidi aldıysa
        // lock referansımız olduğu için tekrar acquire edebiliriz (ihtiyaca göre).
        // Bu örnekte Flutter onResume'u state üzerinden bilip çağırabilir, 
        // ancak daha güvenlisi burada otomatik almaktır (eğer MirrorCam aktifse).
        // Ancak MirrorCam sadece kamera çalışıyorsa almalı. Şimdilik manuel 
        // Dart tarafından connectTo veya _initSender ile alındığı için burada otomatik alma eklemiyoruz.
    }
}
