package com.mendmania.pocketmemory

import android.app.Activity
import android.content.Intent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "localvault/security"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSensitiveScreenProtection" -> {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE
                    )
                    result.success(null)
                }
                "disableSensitiveScreenProtection" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                "excludeFromBackup" -> result.success(null)
                "pickBackupFile" -> pickBackupFile(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun pickBackupFile(result: MethodChannel.Result) {
        if (pendingPickResult != null) {
            result.error("pick_in_progress", "A file picker is already open.", null)
            return
        }
        pendingPickResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }
        startActivityForResult(intent, PICK_BACKUP_FILE_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_BACKUP_FILE_REQUEST) {
            return
        }
        val result = pendingPickResult
        pendingPickResult = null
        if (result == null) {
            return
        }
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }
        try {
            val bytes = contentResolver.openInputStream(data.data!!)?.use { it.readBytes() }
            result.success(bytes)
        } catch (error: Exception) {
            result.error("read_failed", "Could not read the selected backup.", null)
        }
    }

    companion object {
        private const val PICK_BACKUP_FILE_REQUEST = 4107
    }
}
