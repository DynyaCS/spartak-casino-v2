-- Терминал казино "Spartak" v2.0
-- Простая рабочая версия для OpenComputers

local component = require("component")
local event = require("event")
local term = require("term")
local computer = require("computer")

-- Проверка компонентов
if not component.isAvailable("modem") then
    print("ОШИБКА: Wireless Network Card не найдена!")
    print("Установите Wireless Network Card и перезапустите")
    return
end

local modem = component.modem
local gpu = component.gpu
local PORT = 5555

-- Открываем порт
if not modem.isOpen(PORT) then
    modem.open(PORT)
end

-- Цвета
local COLORS = {
    WHITE = 0xFFFFFF,
    BLACK = 0x000000,
    RED = 0xFF0000,
    GREEN = 0x00FF00,
    YELLOW = 0xFFFF00,
    GOLD = 0xFFD700,
    GRAY = 0x808080,
}

-- Глобальные переменные
local serverAddress = nil
local nickname = nil
local balance = 0

-- Функция очистки экрана
local function clear()
    term.clear()
    gpu.setBackground(COLORS.BLACK)
    gpu.setForeground(COLORS.WHITE)
end

-- Функция рисования заголовка
local function drawHeader()
    gpu.setBackground(COLORS.RED)
    gpu.setForeground(COLORS.GOLD)
    local w = gpu.getResolution()
    gpu.fill(1, 1, w, 3, " ")
    
    local title = "КАЗИНО 'SPARTAK'"
    gpu.set(math.floor(w / 2 - #title / 2), 2, title)
    
    gpu.setBackground(COLORS.BLACK)
    gpu.setForeground(COLORS.WHITE)
end

-- Функция ввода текста
local function input(prompt)
    io.write(prompt)
    return io.read()
end

-- Функция отправки сообщения серверу
local function sendToServer(command, ...)
    if not serverAddress then
        print("Ошибка: не подключен к серверу")
        return nil
    end
    
    modem.broadcast(PORT, command, ...)
    
    -- Ждем ответ (таймаут 5 секунд)
    local deadline = computer.uptime() + 5
    while computer.uptime() < deadline do
        local eventType, localAddress, remoteAddress, port, distance, responseCommand, arg1, arg2, arg3, arg4, arg5 = event.pull(0.1, "modem_message")
        
        if eventType and port == PORT and remoteAddress == serverAddress then
            return responseCommand, arg1, arg2, arg3, arg4, arg5
        end
    end
    
    return nil
end

-- Поиск сервера
local function findServer()
    clear()
    drawHeader()
    print("")
    print("Поиск сервера...")
    print("")
    
    modem.broadcast(PORT, "PING")
    
    local deadline = computer.uptime() + 3
    while computer.uptime() < deadline do
        local eventType, localAddress, remoteAddress, port, distance, command, serverInfo = event.pull(0.1, "modem_message")
        
        if eventType and port == PORT and command == "PONG" then
            serverAddress = remoteAddress
            print("✓ Сервер найден!")
            print("  Адрес: " .. remoteAddress:sub(1, 8) .. "...")
            print("  Инфо: " .. tostring(serverInfo))
            os.sleep(1)
            return true
        end
    end
    
    print("✗ Сервер не найден")
    print("")
    print("Убедитесь что:")
    print("  1. Сервер запущен")
    print("  2. Wireless Network Card установлена")
    print("  3. Вы в зоне действия сети")
    print("")
    print("Нажмите Enter для повтора...")
    io.read()
    return false
end

-- Получение баланса
local function getBalance()
    local response, nick, bal = sendToServer("GET_BALANCE", nickname)
    if response == "BALANCE" then
        balance = tonumber(bal) or 0
        return true
    end
    return false
end

-- Главное меню
local function mainMenu()
    while true do
        clear()
        drawHeader()
        
        print("")
        print("Игрок: " .. nickname)
        print("Баланс: " .. balance .. " ₽")
        print("")
        print("╔═══════════════════════════════════════╗")
        print("║                                       ║")
        print("║  [1] 🎰 Слоты                         ║")
        print("║  [2] 🎡 Рулетка (скоро)               ║")
        print("║  [3] 🃏 Блэкджек (скоро)              ║")
        print("║                                       ║")
        print("║  [4] 💰 Пополнить баланс              ║")
        print("║  [5] 💸 Вывести средства              ║")
        print("║                                       ║")
        print("║  [0] Выход                            ║")
        print("║                                       ║")
        print("╚═══════════════════════════════════════╝")
        print("")
        
        local choice = input("Ваш выбор: ")
        
        if choice == "1" then
            playSlots()
        elseif choice == "4" then
            deposit()
        elseif choice == "5" then
            withdraw()
        elseif choice == "0" then
            clear()
            print("До встречи в казино 'Spartak'! 🎰")
            return
        else
            print("Неверный выбор!")
            os.sleep(1)
        end
        
        getBalance()
    end
end

-- Игра в слоты
function playSlots()
    clear()
    drawHeader()
    
    print("")
    print("🎰 СЛОТЫ")
    print("")
    print("Ваш баланс: " .. balance .. " ₽")
    print("Ставка: от 1 до 100 ₽")
    print("")
    
    local bet = tonumber(input("Введите ставку (0 - отмена): "))
    
    if not bet or bet == 0 then
        return
    end
    
    if bet < 1 or bet > 100 then
        print("Ставка должна быть от 1 до 100!")
        os.sleep(2)
        return
    end
    
    if bet > balance then
        print("Недостаточно средств!")
        os.sleep(2)
        return
    end
    
    print("")
    print("Крутим барабаны...")
    os.sleep(1)
    
    local response, s1, s2, s3, win, newBalance = sendToServer("PLAY_SLOTS", nickname, bet)
    
    if response == "SLOTS_RESULT" then
        print("")
        print("╔═══════════════╗")
        print("║  " .. s1 .. " │ " .. s2 .. " │ " .. s3 .. "  ║")
        print("╚═══════════════╝")
        print("")
        
        if win > 0 then
            gpu.setForeground(COLORS.GREEN)
            print("🎉 ВЫИГРЫШ: " .. win .. " ₽!")
            gpu.setForeground(COLORS.WHITE)
        else
            gpu.setForeground(COLORS.RED)
            print("Не повезло...")
            gpu.setForeground(COLORS.WHITE)
        end
        
        balance = tonumber(newBalance) or balance
        print("Ваш баланс: " .. balance .. " ₽")
        
    elseif response == "ERROR" then
        print("Ошибка: " .. tostring(s1))
    else
        print("Ошибка связи с сервером")
    end
    
    print("")
    print("Нажмите Enter...")
    io.read()
end

-- Пополнение баланса
function deposit()
    clear()
    drawHeader()
    
    print("")
    print("💰 ПОПОЛНЕНИЕ БАЛАНСА")
    print("")
    print("Текущий баланс: " .. balance .. " ₽")
    print("")
    
    local amount = tonumber(input("Сумма пополнения (0 - отмена): "))
    
    if not amount or amount == 0 then
        return
    end
    
    if amount < 1 then
        print("Минимальная сумма: 1 ₽")
        os.sleep(2)
        return
    end
    
    local response, nick, newBalance = sendToServer("DEPOSIT", nickname, amount)
    
    if response == "DEPOSIT_OK" then
        balance = tonumber(newBalance) or balance
        print("")
        print("✓ Баланс пополнен!")
        print("Новый баланс: " .. balance .. " ₽")
    else
        print("")
        print("✗ Ошибка пополнения")
    end
    
    print("")
    print("Нажмите Enter...")
    io.read()
end

-- Вывод средств
function withdraw()
    clear()
    drawHeader()
    
    print("")
    print("💸 ВЫВОД СРЕДСТВ")
    print("")
    print("Текущий баланс: " .. balance .. " ₽")
    print("")
    
    local amount = tonumber(input("Сумма вывода (0 - отмена): "))
    
    if not amount or amount == 0 then
        return
    end
    
    if amount < 1 then
        print("Минимальная сумма: 1 ₽")
        os.sleep(2)
        return
    end
    
    if amount > balance then
        print("Недостаточно средств!")
        os.sleep(2)
        return
    end
    
    local response, nick, newBalance = sendToServer("WITHDRAW", nickname, amount)
    
    if response == "WITHDRAW_OK" then
        balance = tonumber(newBalance) or balance
        print("")
        print("✓ Средства выведены!")
        print("Новый баланс: " .. balance .. " ₽")
    else
        print("")
        print("✗ Ошибка вывода")
    end
    
    print("")
    print("Нажмите Enter...")
    io.read()
end

-- Главная функция
local function main()
    -- Поиск сервера
    while not findServer() do
    end
    
    -- Ввод ника
    clear()
    drawHeader()
    print("")
    nickname = input("Введите ваш ник: ")
    
    if not nickname or nickname == "" then
        print("Ник не может быть пустым!")
        return
    end
    
    -- Получаем баланс
    getBalance()
    
    -- Главное меню
    mainMenu()
end

-- Запуск
main()

