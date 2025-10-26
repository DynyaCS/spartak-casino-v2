-- Установщик казино "Spartak" v2.0
-- Использует wget для надежной загрузки файлов

local shell = require("shell")
local fs = require("filesystem")

-- Конфигурация
local REPO = "DynyaCS/spartak-casino-v2"
local BRANCH = "master"
local BASE = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/"
local DIR = "/home/casino"

-- Список файлов
local files = {
    "server/main.lua",
    "terminal/main.lua",
    "terminal/deposit.lua",
    "terminal/ui.lua",
    "lib/database.lua",
    "lib/games.lua",
    "lib/network.lua",
    "lib/pim.lua",
}

-- Заголовок
print("╔═══════════════════════════════════════╗")
print("║   КАЗИНО 'SPARTAK' - УСТАНОВЩИК      ║")
print("║         Версия 2.0                    ║")
print("╚═══════════════════════════════════════╝")
print("")

-- Создаем директории
print("[1/3] Создание директорий...")
local dirs = {DIR, DIR.."/server", DIR.."/terminal", DIR.."/lib", DIR.."/data", DIR.."/logs"}
for _, dir in ipairs(dirs) do
    if not fs.exists(dir) then
        fs.makeDirectory(dir)
    end
end
print("  ✓ Готово")
print("")

-- Загружаем файлы
print("[2/3] Загрузка файлов...")
local ok = 0
local fail = 0

for i, file in ipairs(files) do
    io.write(string.format("  [%d/%d] %s ... ", i, #files, file))
    io.flush()
    
    local url = BASE .. file
    local path = DIR .. "/" .. file
    local cmd = string.format("wget -fq '%s' '%s'", url, path)
    local result = shell.execute(cmd)
    
    if result then
        print("✓")
        ok = ok + 1
    else
        print("✗")
        fail = fail + 1
    end
end

print("")

-- Создаем config.lua
local cfg = DIR .. "/config.lua"
if not fs.exists(cfg) then
    local f = io.open(cfg, "w")
    if f then
        f:write([[return {
    version = "2.0",
    network = {port = 5555, timeout = 5},
    games = {minBet = 1, maxBet = 100},
    deposit = {minAmount = 1, maxAmount = 10000},
}
]])
        f:close()
    end
end

-- Результат
print("[3/3] Завершение...")
print("")

if fail == 0 then
    print("╔═══════════════════════════════════════╗")
    print("║    ✓ УСТАНОВКА ЗАВЕРШЕНА!            ║")
    print("╚═══════════════════════════════════════╝")
    print("")
    print("Загружено: " .. ok .. "/" .. #files)
    print("")
    print("ЗАПУСК СЕРВЕРА:")
    print("  cd /home/casino/server")
    print("  lua main.lua")
    print("")
    print("ЗАПУСК ТЕРМИНАЛА:")
    print("  cd /home/casino/terminal")
    print("  lua main.lua")
    print("")
else
    print("╔═══════════════════════════════════════╗")
    print("║    ✗ ОШИБКА УСТАНОВКИ                ║")
    print("╚═══════════════════════════════════════╝")
    print("")
    print("Загружено: " .. ok .. "/" .. #files)
    print("Ошибок: " .. fail)
    print("")
    print("Проверьте подключение к интернету")
end

