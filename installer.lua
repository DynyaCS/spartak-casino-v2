-- Установщик казино "Spartak" v2.0
-- По образцу MineOS - использует component.proxy для надежной работы

local component = require("component")
local computer = require("computer")

-- Получение адреса компонента
local function getComponentAddress(name)
    return component.list(name)() or error("Требуется компонент: " .. name)
end

-- Получаем адреса компонентов
local internetAddress = getComponentAddress("internet")
local filesystemAddress

-- Находим самый большой filesystem (HDD)
local maxSpace = 0
for address in component.list("filesystem") do
    local proxy = component.proxy(address)
    local space = proxy.spaceTotal()
    if space > maxSpace then
        maxSpace = space
        filesystemAddress = address
    end
end

if not filesystemAddress then
    error("Filesystem не найден!")
end

local fs = component.proxy(filesystemAddress)
local internet = component.proxy(internetAddress)

-- Конфигурация
local REPO = "DynyaCS/spartak-casino-v2"
local BRANCH = "master"
local BASE = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/"
local DIR = "/home/casino"

-- Список файлов
local files = {
    {url = "server/main.lua", path = "/home/casino/server/main.lua"},
    {url = "terminal/main.lua", path = "/home/casino/terminal/main.lua"},
}

-- Функция извлечения пути к директории
local function getDir(path)
    return path:match("^(.+%/).") or ""
end

-- Функция загрузки файла (как в MineOS)
local function download(url, path)
    -- Создаем директорию
    local dir = getDir(path)
    if dir ~= "" then
        fs.makeDirectory(dir)
    end
    
    -- Открываем файл для записи
    local fileHandle, reason = fs.open(path, "wb")
    if not fileHandle then
        error("Не удалось открыть файл " .. path .. ": " .. tostring(reason))
    end
    
    -- Делаем HTTP запрос
    local handle, reason = internet.request(url)
    if not handle then
        fs.close(fileHandle)
        error("Ошибка запроса " .. url .. ": " .. tostring(reason))
    end
    
    -- Ждем подключения
    local deadline = computer.uptime() + 10
    while computer.uptime() < deadline do
        local success, message = handle.finishConnect()
        if success then
            break
        elseif message then
            handle.close()
            fs.close(fileHandle)
            error("Ошибка подключения: " .. tostring(message))
        end
        os.sleep(0.1)
    end
    
    -- Читаем и записываем данные
    local total = 0
    while true do
        local chunk, reason = handle.read(math.huge)
        if chunk then
            fs.write(fileHandle, chunk)
            total = total + #chunk
        else
            if reason then
                handle.close()
                fs.close(fileHandle)
                error("Ошибка чтения: " .. tostring(reason))
            end
            break
        end
    end
    
    handle.close()
    fs.close(fileHandle)
    
    return total
end

-- Заголовок
print("╔═══════════════════════════════════════╗")
print("║   КАЗИНО 'SPARTAK' - УСТАНОВЩИК      ║")
print("║         Версия 2.0                    ║")
print("╚═══════════════════════════════════════╝")
print("")

-- Создаем базовые директории
print("[1/3] Создание директорий...")
local dirs = {
    "/home",
    "/home/casino",
    "/home/casino/server",
    "/home/casino/terminal",
    "/home/casino/data",
    "/home/casino/logs",
}

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
    io.write(string.format("  [%d/%d] %s ", i, #files, file.url))
    io.flush()
    
    local url = BASE .. file.url
    local success, result = pcall(download, url, file.path)
    
    if success then
        print("✓ (" .. result .. " байт)")
        ok = ok + 1
    else
        print("✗")
        print("    Ошибка: " .. tostring(result))
        fail = fail + 1
    end
end

print("")

-- Создаем config.lua
print("[3/3] Создание конфигурации...")
local cfg = "/home/casino/config.lua"
if not fs.exists(cfg) then
    local fh = fs.open(cfg, "wb")
    if fh then
        fs.write(fh, [[return {
    version = "2.0",
    network = {port = 5555, timeout = 5},
    games = {minBet = 1, maxBet = 100},
}
]])
        fs.close(fh)
        print("  ✓ Готово")
    end
else
    print("  ✓ Уже существует")
end
print("")

-- Результат
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
    print("Удачи в казино! 🎰")
else
    print("╔═══════════════════════════════════════╗")
    print("║    ✗ ОШИБКА УСТАНОВКИ                ║")
    print("╚═══════════════════════════════════════╝")
    print("")
    print("Загружено: " .. ok .. "/" .. #files)
    print("Ошибок: " .. fail)
    print("")
    print("Проверьте подключение к интернету")
    print("и попробуйте снова")
end

