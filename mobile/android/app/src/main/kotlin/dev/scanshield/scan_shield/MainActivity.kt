package dev.scanshield.scan_shield

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingText = readSharedText(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.scanshield/share")
        channel?.setMethodCallHandler { call, result ->
            if (call.method == "consumeSharedText") {
                result.success(pendingText)
                pendingText = null
            } else result.notImplemented()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val text = readSharedText(intent)
        if (text != null) channel?.invokeMethod("sharedText", text)
    }

    private fun readSharedText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND || intent.type != "text/plain") return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)?.take(20000)
    }
}
