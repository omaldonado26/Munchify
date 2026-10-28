package hn.uth.munchify

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        crearCanalDeAvisos()
    }

    private fun crearCanalDeAvisos() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val canal = NotificationChannel(
            "munchify_avisos",
            "Avisos de Munchify",
            NotificationManager.IMPORTANCE_HIGH
        ).apply { description = "Cupones, evidencias y recompensas" }
        getSystemService(NotificationManager::class.java).createNotificationChannel(canal)
    }
}
