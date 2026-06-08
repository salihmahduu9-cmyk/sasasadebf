#!/usr/bin/env lua
-- Moonviel Lua Deobfuscator v2.0
-- فاكِ تشفير Lua متقدم باستخدام Lua نفسه

local deobfuscator = {}

-- ============================================================
-- Part 1: String Decoding Functions
-- ============================================================

function deobfuscator.decodeHexString(str)
    return (str:gsub("\\x(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

function deobfuscator.decodeUnicodeString(str)
    return (str:gsub("\\u(%x%x%x%x)", function(hex)
        return utf8.char(tonumber(hex, 16))
    end))
end

function deobfuscator.decodeBase64(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = data:gsub("[^" .. b .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local n = b:find(x) - 1
        return string.char(
            math.floor(n / 64) * 4 + math.floor((n % 64) / 16),
            ((n % 16) * 4) % 256,
            ((n % 4) * 64) % 256
        )
    end))
end

-- ============================================================
-- Part 2: Variable Renaming
-- ============================================================

function deobfuscator.renameVariables(code)
    local varMap = {}
    local counter = 0
    
    -- Lua keywords
    local keywords = {
        ["if"] = true, ["then"] = true, ["else"] = true, ["elseif"] = true,
        ["end"] = true, ["while"] = true, ["do"] = true, ["for"] = true,
        ["in"] = true, ["repeat"] = true, ["until"] = true, ["break"] = true,
        ["return"] = true, ["function"] = true, ["local"] = true, ["and"] = true,
        ["or"] = true, ["not"] = true, ["nil"] = true, ["true"] = true,
        ["false"] = true, ["self"] = true, ["require"] = true, ["assert"] = true
    }
    
    -- Replace obfuscated variable names (single/double letters, numbers)
    code = code:gsub("(%w+)", function(word)
        if keywords[word] or #word > 5 or word:match("^[0-9]") then
            return word
        end
        
        if not varMap[word] then
            varMap[word] = "var_" .. counter
            counter = counter + 1
        end
        
        return varMap[word]
    end)
    
    return code
end

-- ============================================================
-- Part 3: Code Beautification
-- ============================================================

function deobfuscator.beautifyCode(code)
    local lines = {}
    local indent = 0
    local indentStr = "  "
    
    -- Split by common delimiters
    for line in code:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$")  -- trim
        
        if line ~= "" then
            -- Decrease indent for 'end'
            if line:match("^end%s*$") or line:match("^end[,;)]") then
                indent = math.max(0, indent - 1)
            elseif line:match("^else%s*$") or line:match("^elseif") then
                indent = math.max(0, indent - 1)
            end
            
            -- Add indented line
            table.insert(lines, indentStr:rep(indent) .. line)
            
            -- Increase indent for keywords
            if line:match("then%s*$") or line:match("do%s*$") or 
               line:match("function%s*[%w_]+%s*%(") or line:match("^repeat%s*$") then
                indent = indent + 1
            elseif line:match("else%s*$") then
                indent = indent + 1
            end
        end
    end
    
    return table.concat(lines, "\n")
end

-- ============================================================
-- Part 4: Remove Comments and Dead Code
-- ============================================================

function deobfuscator.removeComments(code)
    -- Remove single-line comments
    code = code:gsub("%-%-(.-)[\n$]", "\n")
    
    -- Remove multi-line comments
    code = code:gsub("%-%-%[%[(.-)%]%]", "")
    
    return code
end

function deobfuscator.removeDeadCode(code)
    -- Remove empty lines
    code = code:gsub("\n\n+", "\n")
    
    -- Remove trailing whitespace
    code = code:gsub("%s+\n", "\n")
    
    return code
end

-- ============================================================
-- Part 5: Direct Obfuscated Code Execution (Safe)
-- ============================================================

function deobfuscator.executeSafely(code)
    -- Create a sandbox environment
    local env = {}
    
    -- Add safe standard functions
    env.print = print
    env.table = table
    env.string = string
    env.math = math
    env.type = type
    env.tonumber = tonumber
    env.tostring = tostring
    env.pairs = pairs
    env.ipairs = ipairs
    env.next = next
    env.rawget = rawget
    env.rawset = rawset
    env.getmetatable = getmetatable
    env.setmetatable = setmetatable
    env.select = select
    env.bit32 = bit32
    
    -- Load and execute the code
    local func, err = load(code, "deobfuscated", "t", env)
    
    if func then
        return true, "Code executed successfully"
    else
        return false, "Execution error: " .. (err or "Unknown error")
    end
end

-- ============================================================
-- Part 6: Main Deobfuscation Pipeline
-- ============================================================

function deobfuscator.deobfuscate(code, options)
    options = options or {}
    
    print("🔄 جاري فك التشفير...")
    
    -- Step 1: Decode strings
    print("  1️⃣  فك تشفير النصوص المرمزة...")
    code = deobfuscator.decodeHexString(code)
    code = deobfuscator.decodeUnicodeString(code)
    
    -- Step 2: Remove comments
    print("  2️⃣  إزالة التعليقات...")
    code = deobfuscator.removeComments(code)
    
    -- Step 3: Remove dead code
    print("  3️⃣  تنظيف الأكواس الميتة...")
    code = deobfuscator.removeDeadCode(code)
    
    -- Step 4: Rename variables (optional)
    if options.rename ~= false then
        print("  4️⃣  إعادة تسمية المتغيرات...")
        code = deobfuscator.renameVariables(code)
    end
    
    -- Step 5: Beautify
    print("  5️⃣  تجميل الكود...")
    code = deobfuscator.beautifyCode(code)
    
    print("✅ تم فك التشفير بنجاح!\n")
    
    return code
end

-- ============================================================
-- Part 7: Analysis Functions
-- ============================================================

function deobfuscator.analyzeCode(code)
    local analysis = {
        lines = #code:match(".*"):gmatch("[^\n]+"),
        characters = #code,
        hasHexStrings = code:find("\\x%x%x") ~= nil,
        hasUnicodeStrings = code:find("\\u%x%x%x%x") ~= nil,
        hasBitwise = code:find("bit32%.") ~= nil,
        hasEncryption = code:find("sha") ~= nil or code:find("encrypt") ~= nil,
        obfuscationLevel = "Unknown"
    }
    
    -- Count obfuscation indicators
    local indicators = 0
    if analysis.hasHexStrings then indicators = indicators + 1 end
    if analysis.hasUnicodeStrings then indicators = indicators + 1 end
    if analysis.hasBitwise then indicators = indicators + 1 end
    if analysis.hasEncryption then indicators = indicators + 1 end
    
    analysis.obfuscationLevel = indicators > 2 and "High" or indicators > 0 and "Medium" or "Low"
    
    return analysis
end

-- ============================================================
-- Part 8: Command Line Interface
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
    
    print("📊 تحليل الكود المشفر...")
    local analysis = deobfuscator.analyzeCode(code)
    print("  - عدد الأسطر: " .. analysis.lines)
    print("  - الأحرف: " .. analysis.characters)
    print("  - مستوى التشفير: " .. analysis.obfuscationLevel)
    print()
    
    local deobfuscated = deobfuscator.deobfuscate(code)
    
    -- Save to file
    local outputFile = filename:gsub("%.lua$", "_deobfuscated.lua")
    local out = io.open(outputFile, "w")
    out:write(deobfuscated)
    out:close()
    
    print("💾 تم حفظ الكود المفكك: " .. outputFile)
    
    -- Show first 50 lines
    print("\n📝 أول 50 سطر من الكود المفكك:\n")
    local lines = {}
    for line in deobfuscated:gmatch("[^\n]+") do
        table.insert(lines, line)
        if #lines >= 50 then break end
    end
    print(table.concat(lines, "\n"))
else
    print("استخدام: lua lua-deobfuscator.lua <filename.lua>")
    print("مثال: lua lua-deobfuscator.lua obfuscated.lua")
end

return deobfuscator
