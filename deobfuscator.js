class Deobfuscator {
    constructor() {
        this.inputEl = document.getElementById('input');
        this.outputEl = document.getElementById('output');
        this.languageEl = document.getElementById('language');
        this.deobfuscateBtn = document.getElementById('deobfuscateBtn');
        this.clearBtn = document.getElementById('clearBtn');
        this.copyBtn = document.getElementById('copyBtn');
        this.pasteBtn = document.getElementById('pasteBtn');
        this.swapBtn = document.getElementById('swapBtn');

        this.initEventListeners();
    }

    initEventListeners() {
        this.deobfuscateBtn.addEventListener('click', () => this.deobfuscate());
        this.clearBtn.addEventListener('click', () => this.clear());
        this.copyBtn.addEventListener('click', () => this.copy());
        this.pasteBtn.addEventListener('click', () => this.paste());
        this.swapBtn.addEventListener('click', () => this.swap());
    }

    async deobfuscate() {
        const code = this.inputEl.value.trim();
        const language = this.languageEl.value;

        if (!code) {
            this.showNotification('الرجاء إدخال كود أولاً', 'error');
            return;
        }

        try {
            this.deobfuscateBtn.disabled = true;
            this.deobfuscateBtn.textContent = '⏳ جاري المعالجة...';

            let result;
            switch (language) {
                case 'lua':
                    result = await this.deobfuscateLua(code);
                    break;
                case 'javascript':
                    result = await this.deobfuscateJavaScript(code);
                    break;
                case 'python':
                    result = await this.deobfuscatePython(code);
                    break;
                default:
                    result = code;
            }

            this.outputEl.value = result;
            this.showNotification('✓ تم فك التشفير بنجاح!');
        } catch (error) {
            this.showNotification(`خطأ: ${error.message}`, 'error');
        } finally {
            this.deobfuscateBtn.disabled = false;
            this.deobfuscateBtn.textContent = '🔄 فك التشفير';
        }
    }

    async deobfuscateLua(code) {
        // Remove comments
        code = code.replace(/--\[\[.*?\]\]/gs, '');
        code = code.replace(/--.*$/gm, '');

        // Beautify and format
        code = this.beautifyLua(code);

        // Decode strings if encoded
        code = this.decodeLuaStrings(code);

        // Rename variables
        code = this.renameVariables(code, 'lua');

        return code;
    }

    beautifyLua(code) {
        let indent = 0;
        const indentStr = '  ';
        let result = [];
        const lines = code.split('\n');

        const decreaseIndent = ['end', 'else', 'elseif', 'until'];
        const increaseIndent = ['then', 'do', 'function', 'repeat'];

        for (let line of lines) {
            line = line.trim();
            if (!line) continue;

            // Check if we need to decrease indent
            for (let keyword of decreaseIndent) {
                if (line.startsWith(keyword)) {
                    indent = Math.max(0, indent - 1);
                    break;
                }
            }

            // Add the line with proper indentation
            result.push(indentStr.repeat(indent) + line);

            // Check if we need to increase indent
            for (let keyword of increaseIndent) {
                if (line.includes(keyword)) {
                    indent++;
                    break;
                }
            }
        }

        return result.join('\n');
    }

    decodeLuaStrings(code) {
        // Handle hex encoded strings
        code = code.replace(/\\x([0-9a-f]{2})/gi, (match, hex) => {
            return String.fromCharCode(parseInt(hex, 16));
        });

        // Handle unicode
        code = code.replace(/\\u([0-9a-f]{4})/gi, (match, hex) => {
            return String.fromCharCode(parseInt(hex, 16));
        });

        return code;
    }

    async deobfuscateJavaScript(code) {
        // Remove comments
        code = code.replace(/\/\/.*$/gm, '');
        code = code.replace(/\/\*[\s\S]*?\*\//g, '');

        // Beautify
        code = this.beautifyJavaScript(code);

        // Decode strings
        code = this.decodeJavaScriptStrings(code);

        // Rename variables
        code = this.renameVariables(code, 'javascript');

        return code;
    }

    beautifyJavaScript(code) {
        let indent = 0;
        const indentStr = '  ';
        let result = [];
        let i = 0;

        while (i < code.length) {
            const char = code[i];

            if (char === '{') {
                result.push(char + '\n');
                indent++;
                i++;
                while (i < code.length && /\s/.test(code[i])) i++;
                if (i < code.length) {
                    result.push(indentStr.repeat(indent));
                }
                continue;
            } else if (char === '}') {
                indent = Math.max(0, indent - 1);
                result.push('\n' + indentStr.repeat(indent) + char);
                result.push(';\n');
                i++;
                continue;
            } else if (char === ';') {
                result.push(char + '\n');
                i++;
                if (i < code.length) {
                    result.push(indentStr.repeat(indent));
                }
                continue;
            } else if (/\s/.test(char)) {
                result.push(' ');
                while (i < code.length && /\s/.test(code[i])) i++;
                continue;
            }

            result.push(char);
            i++;
        }

        return result.join('').trim();
    }

    decodeJavaScriptStrings(code) {
        code = code.replace(/\\x([0-9a-f]{2})/gi, (match, hex) => {
            return String.fromCharCode(parseInt(hex, 16));
        });

        code = code.replace(/\\u([0-9a-f]{4})/gi, (match, hex) => {
            return String.fromCharCode(parseInt(hex, 16));
        });

        code = code.replace(/(['"])([^'"]*?)\1\s*\+\s*(['"])([^'"]*?)\3/g, '$1$2$4$1');

        return code;
    }

    async deobfuscatePython(code) {
        code = code.replace(/#.*$/gm, '');
        code = this.beautifyPython(code);
        code = this.renameVariables(code, 'python');
        return code;
    }

    beautifyPython(code) {
        const lines = code.split('\n');
        let result = [];
        let indent = 0;
        const indentStr = '    ';

        for (let line of lines) {
            const trimmed = line.trim();
            if (!trimmed) continue;

            const leadingSpaces = line.length - line.trimStart().length;
            indent = Math.floor(leadingSpaces / 4);

            result.push(indentStr.repeat(indent) + trimmed);
        }

        return result.join('\n');
    }

    renameVariables(code, language) {
        const variableMap = new Map();
        let counter = 0;
        const prefixes = {
            lua: 'var_',
            javascript: 'var_',
            python: 'var_'
        };

        const prefix = prefixes[language] || 'var_';

        const patterns = {
            lua: /\b([a-z]{1,3}[a-z0-9_]*)\b/g,
            javascript: /\b([a-z]{1,3}[a-z0-9_$]*)\b/g,
            python: /\b([a-z]{1,3}[a-z0-9_]*)\b/g
        };

        const pattern = patterns[language] || patterns.lua;

        return code.replace(pattern, (match) => {
            const keywords = ['if', 'then', 'end', 'do', 'for', 'while', 'function', 'local', 'return', 
                            'and', 'or', 'not', 'nil', 'true', 'false', 'else', 'elseif', 'in',
                            'var', 'const', 'let', 'function', 'class', 'extends', 'static',
                            'async', 'await', 'def', 'class', 'import', 'from', 'as', 'pass'];

            if (keywords.includes(match)) return match;

            if (!variableMap.has(match)) {
                variableMap.set(match, prefix + counter++);
            }
            return variableMap.get(match);
        });
    }

    clear() {
        this.inputEl.value = '';
        this.outputEl.value = '';
        this.inputEl.focus();
    }

    copy() {
        if (!this.outputEl.value) {
            this.showNotification('لا يوجد محتوى للنسخ', 'error');
            return;
        }

        navigator.clipboard.writeText(this.outputEl.value).then(() => {
            this.showNotification('✓ تم النسخ إلى الحافظة!');
        }).catch(() => {
            this.showNotification('فشل النسخ', 'error');
        });
    }

    async paste() {
        try {
            const text = await navigator.clipboard.readText();
            this.inputEl.value = text;
            this.showNotification('✓ تم الاستخراج من الحافظة!');
        } catch (err) {
            this.showNotification('لا يمكن الوصول للحافظة', 'error');
        }
    }

    swap() {
        const temp = this.inputEl.value;
        this.inputEl.value = this.outputEl.value;
        this.outputEl.value = temp;
    }

    showNotification(message, type = 'success') {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        document.body.appendChild(notification);

        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }
}

document.addEventListener('DOMContentLoaded', () => {
    new Deobfuscator();
});