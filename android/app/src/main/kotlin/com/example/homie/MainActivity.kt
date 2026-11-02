package com.example.homie

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var paymentChannel: MethodChannel? = null
    private var pendingPaymentUri: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingPaymentUri = paymentLink(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        paymentChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "homie/payment_return",
        ).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "takePendingPaymentReturn") {
                    result.success(pendingPaymentUri)
                    pendingPaymentUri = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val link = paymentLink(intent) ?: return
        pendingPaymentUri = link
        paymentChannel?.invokeMethod("paymentReturn", link)
    }

    private fun paymentLink(intent: Intent?): String? {
        val uri = intent?.data ?: return null
        return if (uri.scheme == "homie" && uri.host == "payment-result") {
            uri.toString()
        } else {
            null
        }
    }
}
