const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static('public'));

app.post('/api/deobfuscate', (req, res) => {
    const rawCode = req.body.code;
    if (!rawCode) {
        return res.json({ result: "❌ الرجاء إدخال كود أولاً!" });
    }

    // إنشاء ملف مؤقت للكود المدخل لكي يقرأه ملف الـ Lua
    const tempInFile = path.join(__dirname, 'temp_input.lua');
    fs.writeFileSync(tempInFile, rawCode);

    // تشغيل ملف الـ Lua الخاص بك وتمرير الملف المؤقت له
    exec(`lua lua-deobfuscator-extreme.lua temp_input.lua`, (error, stdout, stderr) => {
        // تنظيف الملف المؤقت
        if (fs.existsSync(tempInFile)) fs.unlinkSync(tempInFile);

        if (error) {
            return res.json({ result: "❌ خطأ أثناء تشغيل Lua:\n" + stderr });
        }
        
        res.json({ result: stdout || "⚠️ تم التنفيذ ولكن لم يتم إرجاع نتيجة (ربما الكود غير متوافق)." });
    });
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
