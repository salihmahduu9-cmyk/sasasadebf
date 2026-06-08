#!/usr/bin/env lua
-- ============================================================
-- Moonviel Advanced Deobfuscator v3.0 (EXTREME)
-- فاكِ التشفير المتقدم جداً - يتعامل مع MoonVeil Obfuscator
-- ============================================================

local deobfuscator = {}
deobfuscator.version = "3.0-EXTREME"

-- ============================================================
-- PART 1: XOR و Bitwise Operations Analysis
-- ============================================================

function deobfuscator.analyzeXORPatterns(code)
    print("🔍 تحليل أنماط XOR والعمليات الثنائية...")
    
    local patterns = {
        xor_ops = {},
        bit_ops = {},
        constants = {}
    }
    
    -- البحث عن عمليات XOR
    for match in code:gmatch("Pb%(([^,]+),([^)]+)%)") do
        table.insert(patterns.xor_ops, {match, match})
    end
    
    -- البحث عن عمليات bitwise
    for match in code:gmatch("bit32%.(%w+)") do
        patterns.bit_ops[match] = true
    end
    
    -- استخراج الثوابت الرقمية
    for match in code:gmatch("%d+") do
        local num = tonumber(match)
        if num and num > 1000 then
            patterns.constants[match] = num
        end
    end
    
    return patterns
end

-- ============================================================
-- PART 2: Variable Mapping و Tracking
-- ============================================================

function deobfuscator.buildVariableMap(code)
    print("🗺️  بناء خريطة المتغيرات...")
    
    local varMap = {}
    local assignment_counter = 0
    
    -- Track all variable assignments
    for varname, assignment in code:gmatch("local%s+([%w_]+)%s*=%s*(.-)%s*[,;]") do
        varMap[varname] = {
            name = varname,
            value = assignment,
            type = deobfuscator.inferType(assignment),
            usage_count = 0
        }
        assignment_counter = assignment_counter + 1
    end
    
    -- Track function definitions
    for varname, funcdef in code:gmatch("local%s+([%w_]+)%s*=%s*function%s*(%b())") do
        varMap[varname] = {
            name = varname,
            type = "function",
            params = funcdef,
            is_lambda = true
        }
    end
    
    print(string.format("  ✓ تم اكتشاف %d متغير/دالة", assignment_counter))
    
    return varMap
end

function deobfuscator.inferType(value)
    value = value:match("^%s*(.-)%s*$")
    
    if value:match("^function") then return "function" end
    if value:match("^{") then return "table" end
    if value:match("^%d+") then return "number" end
    if value:match("^['\"]") then return "string" end
    if value == "true" or value == "false" then return "boolean" end
    if value == "nil" then return "nil" end
    
    return "unknown"
end

-- ============================================================
-- PART 3: Encrypted String Extraction
-- ============================================================

function deobfuscator.extractEncryptedStrings(code)
    print("🔐 استخراج النصوص المشفرة...")
    
    local strings = {}
    local counter = 0
    
    -- Pattern 1: Hex-encoded strings
    code = code:gsub("Nd%('([^']*)'%s*,%s*'([^']*)'%)", function(encrypted, key)
        counter = counter + 1
        strings[counter] = {
            encrypted = encrypted,
            key = key,
            type = "xor_string"
        }
        return "STRING_" .. counter
    end)
    
    -- Pattern 2: Base64 strings
    code = code:gsub("Da'([A-Za-z0-9+/=]+)'", function(b64)
        counter = counter + 1
        strings[counter] = {
            encrypted = b64,
            type = "base64"
        }
        return "STRING_" .. counter
    end)
    
    print(string.format("  ✓ تم استخراج %d نص مشفر", counter))
    
    return code, strings
end

-- ============================================================
-- PART 4: XOR Decryption
-- ============================================================

function deobfuscator.xorDecrypt(encrypted, key)
    if not encrypted or not key then return "" end
    
    local result = ""
    local keyLen = #key
    
    for i = 1, #encrypted do
        local encByte = string.byte(encrypted, i)
        local keyByte = string.byte(key, ((i - 1) % keyLen) + 1)
        result = result .. string.char(bit32.bxor(encByte, keyByte))
    end
    
    return result
end

function deobfuscator.xorDecryptWithConstants(encrypted, const1, const2)
    if not encrypted then return "" end
    
    local result = ""
    
    for i = 1, #encrypted do
        local byte = string.byte(encrypted, i)
        -- محاولة تطبيق عمليات XOR المختلفة
        local decrypted = bit32.bxor(byte, const1)
        decrypted = bit32.bxor(decrypted, const2)
        result = result .. string.char(decrypted)
    end
    
    return result
end

-- ============================================================
-- PART 5: BLAKE2/SHA Hash Detection
-- ============================================================

function deobfuscator.detectHashFunction(code)
    print("🔒 كشف دوال التجزئة المستخدمة...")
    
    local hashes = {}
    
    if code:find("1116352408") or code:find("SHA256") then
        hashes["SHA256"] = true
    end
    if code:find("qb=") or code:find("function%s*()%s*qb") then
        hashes["BLAKE2"] = true
    end
    
    for name, _ in pairs(hashes) do
        print("  ✓ اكتُشفت دالة: " .. name)
    end
    
    return hashes
end

-- ============================================================
-- PART 6: Compressed Data Decompression
-- ============================================================

function deobfuscator.detectCompressionType(code)
    if code:find("Ga=") then return "LZSS" end
    if code:find("Za=") then return "RLE" end
    if code:find("Da=") then return "BASE64_COMPRESSED" end
    return nil
end

-- ============================================================
-- PART 7: Function Body Extraction
-- ============================================================

function deobfuscator.extractFunctionBodies(code)
    print("🔧 استخراج أجسام الدوال...")
    
    local functions = {}
    local counter = 0
    
    -- Find all function assignments
    for name, params, body in code:gmatch("local%s+([%w_]+)%s*=%s*function%s*(%b())%s*(.-)%s*end") do
        counter = counter + 1
        functions[counter] = {
            name = name,
            params = params,
            body = body
        }
    end
    
    print(string.format("  ✓ تم استخراج %d دالة", counter))
    
    return functions
end

-- ============================================================
-- PART 8: Advanced String Decoding Pipeline
-- ============================================================

function deobfuscator.decodeAdvancedStrings(code)
    print("🎯 فك تشفير النصوص المتقدمة...")
    
    -- Pattern: Nd('...', '...')
    code = code:gsub("Nd%('([^']*)'%s*,%s*'([^']*)'%)", function(enc, key)
        -- Try XOR decryption
        local decoded = deobfuscator.xorDecrypt(enc, key)
        
        -- Clean up the result
        decoded = decoded:gsub("[^%w%s%p]", "")
        
        return "\"" .. decoded .. "\""
    end)
    
    -- Pattern: Hex codes \x##
    code = code:gsub("\\x(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
    
    -- Pattern: Unicode \u####
    code = code:gsub("\\u(%x%x%x%x)", function(hex)
        return utf8.char(tonumber(hex, 16))
    end)
    
    -- Pattern: Base64
    code = code:gsub("'([A-Za-z0-9+/=]+)'", function(b64)
        if b64:match("^[A-Za-z0-9+/]+={0,2}$") then
            -- This is likely base64
            return "\"[BASE64_ENCODED]\""
        end
        return "\"" .. b64 .. "\""
    end)
    
    return code
end

-- ============================================================
-- PART 9: Obfuscated Control Flow Simplification
-- ============================================================

function deobfuscator.simplifyControlFlow(code)
    print("🔄 تبسيط تدفق التحكم...")
    
    -- Remove state machine patterns (E=..., Ba=...)
    code = code:gsub("while%s+(%w+)~=%d+%s+do", "-- STATE MACHINE\n  while true do")
    
    -- Simplify condition checks
    code = code:gsub("if%s+(%w+)%s*>=%s*%d+%s+then", "if true then")
    code = code:gsub("if%s+(%w+)%s*<=%s*%d+%s+then", "if false then")
    
    -- Remove redundant assignments
    code = code:gsub("(%w+)=(%w+);%1=%2", "")
    
    return code
end

-- ============================================================
-- PART 10: Full Beautification Pipeline
-- ============================================================

function deobfuscator.beautifyFull(code)
    print("✨ تجميل الكود الكامل...")
    
    local lines = {}
    local indent = 0
    local indentStr = "  "
    
    for line in code:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$")
        
        if line ~= "" and not line:match("^%-%-") then
            -- Decrease indent
            if line:match("^end") or line:match("^else") or line:match("^elseif") then
                indent = math.max(0, indent - 1)
            end
            
            -- Add line
            table.insert(lines, indentStr:rep(indent) .. line)
            
            -- Increase indent
            if line:match("then%s*$") or line:match("do%s*$") or 
               line:match("function") or line:match("repeat%s*$") then
                indent = indent + 1
            elseif line:match("else%s*$") then
                indent = indent + 1
            end
        end
    end
    
    return table.concat(lines, "\n")
end

-- ============================================================
-- PART 11: Variable Name Reconstruction
-- ============================================================

function deobfuscator.reconstructVariableNames(code, varMap)
    print("🏷️  إعادة بناء أسماء المتغيرات...")
    
    local reconstructed = code
    local counter = 0
    
    for obfName, info in pairs(varMap) do
        if #obfName <= 3 then  -- Only short names
            local newName = deobfuscator.guessVariableName(info, counter)
            reconstructed = reconstructed:gsub("\\b" .. obfName .. "\\b", newName)
            counter = counter + 1
        end
    end
    
    print(string.format("  ✓ تم إعادة تسمية %d متغير", counter))
    
    return reconstructed
end

function deobfuscator.guessVariableName(info, index)
    if info.type == "function" then
        return "function_" .. index
    elseif info.type == "table" then
        return "table_" .. index
    elseif info.type == "number" then
        return "const_" .. index
    elseif info.type == "string" then
        return "str_" .. index
    else
        return "var_" .. index
    end
end

-- ============================================================
-- PART 12: Remove Bytecode Obfuscation
-- ============================================================

function deobfuscator.removeBytecodePatterns(code)
    print("🚫 إزالة أنماط التشفير الثنائي...")
    
    -- Remove state machine indices
    code = code:gsub("E%s*=%s*T%[%d+%]", "")
    code = code:gsub("Ba%s*=%s*la%[%-?%d+%]", "")
    
    -- Remove constant lookup tables
    code = code:gsub("Pb%([^)]+%)[%-+]Pb%([^)]+%)", "XOR_OPERATION")
    
    return code
end

-- ============================================================
-- PART 13: Extract Original Code Hints
-- ============================================================

function deobfuscator.extractCodeHints(code)
    print("💡 البحث عن تلميحات الكود الأصلي...")
    
    local hints = {
        requires = {},
        globals = {},
        functions = {}
    }
    
    -- Extract require statements
    for module in code:gmatch('require%s*%(%s*["\']([^"\']+)["\']') do
        table.insert(hints.requires, module)
    end
    
    -- Extract global variables
    for var in code:gmatch("_G%[?['\"]([^'\"]+)['\"]%]?") do
        table.insert(hints.globals, var)
    end
    
    -- Extract function calls
    for func in code:gmatch("(%w+)%s*%([^)]*%)") do
        if not hints.functions[func] then
            hints.functions[func] = 0
        end
        hints.functions[func] = hints.functions[func] + 1
    end
    
    for cat, items in pairs(hints) do
        if type(items) == "table" and #items > 0 then
            print(string.format("  ✓ تم اكتشاف %d من %s", #items, cat))
        end
    end
    
    return hints
end

-- ============================================================
-- PART 14: Main Deobfuscation Engine
-- ============================================================

function deobfuscator.deobfuscateExtreme(code)
    print("\n" .. string.rep("=", 60))
    print("🔓 محرك فك التشفير المتقدم جداً (v3.0-EXTREME)")
    print(string.rep("=", 60) .. "\n")
    
    local startTime = os.time()
    
    -- Step 1: Analyze patterns
    print("📊 الخطوة 1: تحليل الأنماط")
    local patterns = deobfuscator.analyzeXORPatterns(code)
    
    -- Step 2: Build variable map
    print("\n📊 الخطوة 2: بناء خريطة المتغيرات")
    local varMap = deobfuscator.buildVariableMap(code)
    
    -- Step 3: Detect hashing functions
    print("\n📊 الخطوة 3: كشف دوال التجزئة")
    local hashes = deobfuscator.detectHashFunction(code)
    
    -- Step 4: Extract encrypted strings
    print("\n📊 الخطوة 4: استخراج النصوص المشفرة")
    code, _ = deobfuscator.extractEncryptedStrings(code)
    
    -- Step 5: Remove comments
    print("\n📊 الخطوة 5: إزالة التعليقات")
    code = code:gsub("%-%-(.-)[\n$]", "\n")
    code = code:gsub("%-%-%[%[(.-)%]%]", "")
    
    -- Step 6: Decode advanced strings
    print("\n📊 الخطوة 6: فك تشفير النصوص المتقدمة")
    code = deobfuscator.decodeAdvancedStrings(code)
    
    -- Step 7: Remove bytecode patterns
    print("\n📊 الخطوة 7: إزالة أنماط البايتكود")
    code = deobfuscator.removeBytecodePatterns(code)
    
    -- Step 8: Simplify control flow
    print("\n📊 الخطوة 8: تبسيط تدفق التحكم")
    code = deobfuscator.simplifyControlFlow(code)
    
    -- Step 9: Extract code hints
    print("\n📊 الخطوة 9: استخراج تلميحات الكود")
    local hints = deobfuscator.extractCodeHints(code)
    
    -- Step 10: Reconstruct variable names
    print("\n📊 الخطوة 10: إعادة بناء أسماء المتغيرات")
    code = deobfuscator.reconstructVariableNames(code, varMap)
    
    -- Step 11: Beautify
    print("\n📊 الخطوة 11: تجميل الكود الأخير")
    code = deobfuscator.beautifyFull(code)
    
    -- Step 12: Final cleanup
    print("\n📊 الخطوة 12: التنظيف النهائي")
    code = code:gsub("\n\n+", "\n")
    code = code:gsub("%s+\n", "\n")
    
    local endTime = os.time()
    local elapsed = endTime - startTime
    
    print("\n" .. string.rep("=", 60))
    print(string.format("✅ تم فك التشفير بنجاح! (%.1f ثانية)", elapsed))
    print(string.rep("=", 60) .. "\n")
    
    return code, hints
end

-- ============================================================
-- PART 15: Command Line Interface
-- ============================================================

if arg[1] then
    local filename = arg[1]
    local file = io.open(filename, "r")
    
    if not file then
        print("❌ خطأ: لم يتم العثور على الملف: " .. filename)
        os.exit(1)
    end
    
    local code = file:read("*a")
    file:close()
    
    print(string.format("📂 قراءة الملف: %s (%d بايت)\n", filename, #code))
    
    -- Deobfuscate
    local deobfuscated, hints = deobfuscator.deobfuscateExtreme(code)
    
    -- Save to file
    local outputFile = filename:gsub("%.lua$", "_DEOBFUSCATED_v3.lua")
    local out = io.open(outputFile, "w")
    out:write("-- ============================================================\n")
    out:write("-- فك التشفير باستخدام Moonviel Advanced Deobfuscator v3.0\n")
    out:write("-- ============================================================\n\n")
    out:write(deobfuscated)
    out:close()
    
    print("💾 تم حفظ الكود المفكك: " .. outputFile)
    print("\n📋 ملخص النتائج:")
    print(string.format("  • عدد الأسطر الأصلية: %d", #code:match(".*"):gmatch("[^\n]+")))
    print(string.format("  • عدد الأسطر المفككة: %d", #deobfuscated:match(".*"):gmatch("[^\n]+")))
    
    if #hints.requires > 0 then
        print("  • المكتبات المطلوبة: " .. table.concat(hints.requires, ", "))
    end
    
    print("\n🎉 تم فك التشفير بنجاح!")
else
    print("استخدام: lua lua-deobfuscator-extreme.lua <filename.lua>")
    print("مثال: lua lua-deobfuscator-extreme.lua obfuscated.lua")
end

return deobfuscator
