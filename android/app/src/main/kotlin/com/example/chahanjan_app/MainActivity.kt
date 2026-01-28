package com.example.chahanjan_app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.util.Base64
import android.util.Log
import java.security.MessageDigest
import android.content.pm.PackageManager

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 카카오 키 해시 출력
        try {
            val info = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            val signatures = info.signatures
            if (signatures != null) {
                for (signature in signatures) {
                    val md = MessageDigest.getInstance("SHA")
                    md.update(signature.toByteArray())
                    val keyHash = Base64.encodeToString(md.digest(), Base64.DEFAULT)
                    Log.d("카카오 키 해시", keyHash)
                    println("=========================================")
                    println("내 카카오 키 해시: $keyHash")
                    println("=========================================")
                }
            }
        } catch (e: Exception) {
            Log.e("카카오 키 해시", "에러: ${e.message}")
        }
    }
}
