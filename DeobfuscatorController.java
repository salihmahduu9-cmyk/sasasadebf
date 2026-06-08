package com.harbawi.deobfuscator.controller;

import org.luaj.vm2.Globals;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.jse.JsePlatform;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class DeobfuscatorController {

    @PostMapping("/deobfuscate")
    public ResponseEntity<Map<String, String>> handleDeobfuscation(@RequestBody Map<String, String> request) {
        Map<String, String> response = new HashMap<>();
        String encryptedCode = request.get("code");

        if (encryptedCode == null || encryptedCode.trim().isEmpty()) {
            response.put("error", "الكود الممرر فارغ!");
            return ResponseEntity.badRequest().body(response);
        }

        try {
            // تهيئة بيئة تشغيل اللوا داخل الجافا
            Globals globals = JsePlatform.standardGlobals();
            
            // تحميل السكربت الرئيسي للمحرك الاستكشافي
            globals.loadfile("lua-deobfuscator-extreme.lua").call();
            
            // سحب دالة جدار الحماية والويب من السكربت
            LuaValue deobfuscatorModule = globals.get("deobfuscator");
            LuaValue webInterfaceFunc = deobfuscatorModule.get("webInterface");
            
            // تنفيذ الفك الفوري عبر الواجهة البرمجية
            LuaValue result = webInterfaceFunc.call(LuaValue.valueOf(encryptedCode));
            
            response.put("deobfuscated", result.toString());
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            response.put("error", "فشل المحرك في تفكيك البنية التحتية للسكربت: " + e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }
}
