-- Сервер казино "Spartak" v2.0
-- Простая рабочая версия для OpenComputers

local component = require("component")
local event = require("event")
local term = require("term")

-- Проверка компонентов
if not component.isAvailable("modem") then
    print("ОШИБКА: Wireless Network Card не найдена!")
    print("Установите Wireless Network Card и перезапустите")
    return
end

local modem = component.modem
local PORT = 5555

-- Открываем порт
if not modem.isOpen(PORT) then
    modem.open(PORT)
end

-- Очистка экрана
term.clear()

-- Заголовок
print("╔═══════════════════════════════════════╗")
print("║                                       ║")
print("║    КАЗИНО 'SPARTAK' - СЕРВЕР         ║")
print("║          Версия 2.0                   ║")
print("║                                       ║")
print("╚═══════════════════════════════════════╝")
print("")
print("Статус: ЗАПУЩЕН")
print("Порт: " .. PORT)
print("Адрес: " .. modem.address:sub(1, 8) .. "...")
print("")
print("Ожидание подключений...")
print("Нажмите Ctrl+C для остановки")
print("")
print("--- ЛОГ ---")
print("")

-- База данных игроков (в памяти)
local players = {}

-- Функция логирования
local function log(message)
    local timestamp = os.date("%H:%M:%S")
    print("[" .. timestamp .. "] " .. message)
end

-- Обработка сообщений
local function handleMessage(eventType, localAddress, remoteAddress, port, distance, command, ...)
    if port ~= PORT then return end
    
    local args = {...}
    
    if command == "PING" then
        -- Ответ на пинг
        modem.send(remoteAddress, PORT, "PONG", "Spartak Casino Server v2.0")
        log("PING от " .. remoteAddress:sub(1, 8))
        
    elseif command == "GET_BALANCE" then
        -- Получить баланс игрока
        local nickname = args[1]
        local balance = players[nickname] or 0
        modem.send(remoteAddress, PORT, "BALANCE", nickname, balance)
        log("Баланс " .. nickname .. ": " .. balance)
        
    elseif command == "DEPOSIT" then
        -- Пополнение баланса
        local nickname = args[1]
        local amount = tonumber(args[2]) or 0
        
        if amount > 0 then
            players[nickname] = (players[nickname] or 0) + amount
            modem.send(remoteAddress, PORT, "DEPOSIT_OK", nickname, players[nickname])
            log("Депозит " .. nickname .. ": +" .. amount .. " (баланс: " .. players[nickname] .. ")")
        else
            modem.send(remoteAddress, PORT, "ERROR", "Неверная сумма")
        end
        
    elseif command == "WITHDRAW" then
        -- Вывод средств
        local nickname = args[1]
        local amount = tonumber(args[2]) or 0
        local currentBalance = players[nickname] or 0
        
        if amount > 0 and currentBalance >= amount then
            players[nickname] = currentBalance - amount
            modem.send(remoteAddress, PORT, "WITHDRAW_OK", nickname, players[nickname])
            log("Вывод " .. nickname .. ": -" .. amount .. " (баланс: " .. players[nickname] .. ")")
        else
            modem.send(remoteAddress, PORT, "ERROR", "Недостаточно средств")
        end
        
    elseif command == "PLAY_SLOTS" then
        -- Игра в слоты
        local nickname = args[1]
        local bet = tonumber(args[2]) or 0
        local currentBalance = players[nickname] or 0
        
        if bet < 1 or bet > 100 then
            modem.send(remoteAddress, PORT, "ERROR", "Ставка должна быть от 1 до 100")
            return
        end
        
        if currentBalance < bet then
            modem.send(remoteAddress, PORT, "ERROR", "Недостаточно средств")
            return
        end
        
        -- Снимаем ставку
        players[nickname] = currentBalance - bet
        
        -- Генерируем результат (3 символа от 1 до 7)
        local symbols = {}
        for i = 1, 3 do
            symbols[i] = math.random(1, 7)
        end
        
        -- Проверяем выигрыш
        local win = 0
        if symbols[1] == symbols[2] and symbols[2] == symbols[3] then
            -- Три одинаковых
            if symbols[1] == 7 then
                win = bet * 100  -- Джекпот!
            else
                win = bet * (symbols[1] * 2)
            end
        elseif symbols[1] == symbols[2] or symbols[2] == symbols[3] then
            -- Два одинаковых
            win = bet * 2
        end
        
        -- Начисляем выигрыш
        if win > 0 then
            players[nickname] = players[nickname] + win
        end
        
        modem.send(remoteAddress, PORT, "SLOTS_RESULT", symbols[1], symbols[2], symbols[3], win, players[nickname])
        log("Слоты " .. nickname .. ": ставка=" .. bet .. ", выигрыш=" .. win .. ", баланс=" .. players[nickname])
        
    else
        log("Неизвестная команда: " .. tostring(command))
    end
end

-- Регистрируем обработчик
event.listen("modem_message", handleMessage)

log("Сервер запущен успешно!")

-- Главный цикл
while true do
    os.sleep(1)
end

