#!/usr/bin/env lua
-- ============================================================
-- Moonviel Advanced Deobfuscator v3.0 (EXTREME)
-- المطور والمالك: Harbawi (@j_w_j_m)
-- ============================================================

local deobfuscator = {}
deobfuscator.version = "3.0-EXTREME"

function deobfuscator.analyzeXORPatterns(code)
    local patterns = { xor_ops = {}, bit_ops = {}, constants = {} }
    for match in code:gmatch("Pb%(([^,]+),([^)]+)%)") do table.insert(patterns.xor_ops, {match, match}) end
    for match in code:gmatch("bit32%.(%w+)") do patterns.bit_ops[match] = true end
    for match in code:gmatch("%d+") do
        local num = tonumber(match)
        if num and num > 1000 then patterns.constants[match] = num end
    end
    return patterns
end

function deobfuscator.buildVariableMap(code)
    local varMap = {}
    for varname, assignment in code:gmatch("local%s+([%w_]+)%s*=%s*(.-)%s*[,;]") do
        varMap[varname] = { name = varname, value = assignment, type = deobfuscator.inferType(assignment) }
    end
    for varname, funcdef in code:gmatch("local%s+([%w_]+)%s*=%s*function%s*(%b())") do
        varMap[varname] = { name = varname, type = "function", params = funcdef }
    end
    return varMap
end

function deobfuscator.inferType(value)
    value = value:match("^%s*(.-)%s*$")
    if value:match("^function") then return "function" end
    if value:match("^{") then return "table" end
    if value:match("^%d+") then return "number" end
    if value:match("^['\"]") then return "string" end
    if value == "true" or value == "false" then return "boolean" end
    return "unknown"
end

function deobfuscator.extractEncryptedStrings(code)
    local strings = {}
    local counter = 0
    code = code:gsub("Nd%('([^']*)'%s*,%s*'([^']*)'%)", function(encrypted, key)
        counter = counter + 1
        strings[counter] = { encrypted = encrypted, key = key, type = "xor_string" }
        return "STRING_" .. counter
    end)
    return code, strings
end

function deobfuscator.xorDecrypt(encrypted, key)
    if not encrypted or not key then return "" end
    local result = ""
    local keyLen = #key
    for i = 1, #encrypted do
        local encByte = string.byte(encrypted, i)
        local keyByte = string.byte(key, ((i - 1) % keyLen) + 1)
        if bit32 then
            result = result .. string.char(bit32.bxor(encByte, keyByte))
        else
            -- fallback if bit32 is not loaded in environment
            result = result .. string.char(encByte) 
        end
    end
    return result
end

function deobfuscator.decodeAdvancedStrings(code)
    code = code:gsub("Nd%('([^']*)'%s*,%s*'([^']*)'%)", function(enc, key)
        local decoded = deobfuscator.xorDecrypt(enc, key)
        return "\"" .. decoded:gsub("[^%w%s%p]", "") .. "\""
    end)
    code = code:gsub("\\x(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
    return code
end

function deobfuscator.simplifyControlFlow(code)
    code = code:gsub("while%s+(%w+)~=%d+%s+do", "while true do")
    code = code:gsub("if%s+(%w+)%s*>=%s*%d+%s+then", "if true then")
    return code
end

function deobfuscator.beautifyFull(code)
    local lines = {}
    local indent = 0
    for line in code:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^%-%-") then
            if line:match("^end") or line:match("^else") then indent = math.max(0, indent - 1) end
            table.insert(lines, string.rep("  ", indent) .. line)
            if line:match("then%s*$") or line:match("do%s*$") or line:match("function") then indent = indent + 1 end
        end
    end
    return table.concat(lines, "\n")
end

function deobfuscator.deobfuscateExtreme(code)
    local varMap = deobfuscator.buildVariableMap(code)
    code, _ = deobfuscator.extractEncryptedStrings(code)
    code = code:gsub("%-%-(.-)[\n$]", "\n")
    code = deobfuscator.decodeAdvancedStrings(code)
    code = deobfuscator.simplifyControlFlow(code)
    code = deobfuscator.beautifyFull(code)
    return code
end

-- ============================================================
-- WEB & CLI API GATEWAY
-- ============================================================
function deobfuscator.webInterface(rawCode)
    local status, result = pcall(deobfuscator.deobfuscateExtreme, rawCode)
    if status then return result else return "❌ Error during deobfuscation: " .. tostring(result) end
end

if arg and arg[1] then
    local f = io.open(arg[1], "r")
    if f then
        local src = f:read("*a")
        f:close()
        print(deobfuscator.deobfuscateExtreme(src))
    end
end

return deobfuscator
