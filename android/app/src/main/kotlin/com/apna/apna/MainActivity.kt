package com.apna.apna

import android.Manifest
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val SMS_CHANNEL = "com.apna.apna/sms_reader"
    private val SMS_PERMISSION_CODE = 10101
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSmsPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.READ_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }
                "requestSmsPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.READ_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    if (granted) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.READ_SMS),
                            SMS_PERMISSION_CODE
                        )
                    }
                }
                "getInboxSms" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.READ_SMS
                    ) == PackageManager.PERMISSION_GRANTED

                    if (!granted) {
                        result.error("PERMISSION_DENIED", "READ_SMS permission is not granted", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val sinceMs = (call.argument<Number>("sinceMs"))?.toLong() ?: 0L
                        val maxCount = call.argument<Int>("maxCount") ?: 250
                        val messages = readInboxSms(sinceMs, maxCount)
                        result.success(messages)
                    } catch (e: Exception) {
                        result.error("SMS_READ_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_CODE) {
            val isGranted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(isGranted)
            pendingPermissionResult = null
        }
    }

    private fun readInboxSms(sinceMs: Long, maxCount: Int): List<Map<String, Any>> {
        val list = ArrayList<Map<String, Any>>()
        val uri = Uri.parse("content://sms/inbox")
        val projection = arrayOf("_id", "address", "body", "date")
        val selection = if (sinceMs > 0) "date >= ?" else null
        val selectionArgs = if (sinceMs > 0) arrayOf(sinceMs.toString()) else null
        val sortOrder = "date DESC"

        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)
            if (cursor != null && cursor.moveToFirst()) {
                val idIdx = cursor.getColumnIndex("_id")
                val addrIdx = cursor.getColumnIndex("address")
                val bodyIdx = cursor.getColumnIndex("body")
                val dateIdx = cursor.getColumnIndex("date")

                var count = 0
                do {
                    val id = if (idIdx >= 0) cursor.getString(idIdx) ?: "" else ""
                    val address = if (addrIdx >= 0) cursor.getString(addrIdx) ?: "" else ""
                    val body = if (bodyIdx >= 0) cursor.getString(bodyIdx) ?: "" else ""
                    val date = if (dateIdx >= 0) cursor.getLong(dateIdx) else 0L

                    val map = HashMap<String, Any>()
                    map["id"] = id
                    map["address"] = address
                    map["body"] = body
                    map["date"] = date
                    list.add(map)

                    count++
                    if (count >= maxCount) break
                } while (cursor.moveToNext())
            }
        } finally {
            cursor?.close()
        }
        return list
    }
}
