-- deposit.lua
-- Терминал депозита/вывода через PIM для казино "Spartak"

local component = require("component")
local event = require("event")
local term = require("term")
local gpu = component.gpu

-- Подключаем библиотеки
package.path = package.path .. ";/home/casino/lib/?.lua"
local PIM = require("pim")
local Network = require("network")
local UI = require("ui")

-- ============================================================================
-- КОНФИГУРАЦИЯ
-- ============================================================================

local CONFIG = {
    MIN_DEPOSIT = 1,
    MAX_DEPOSIT = 10000,
    MIN_WITHDRAW = 1,
    MAX_WITHDRAW = 10000,
    CHECK_INTERVAL = 1.0,  -- Интервал проверки игрока на PIM (секунды)
}

-- ============================================================================
-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ============================================================================

local pim = nil
local network = nil
local currentPlayer = nil
local running = true

-- Разрешение экрана
local screenWidth, screenHeight = gpu.getResolution()

-- ============================================================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================================================

local function init()
    term.clear()
    
    print("═══════════════════════════════════════")
    print("  КАЗИНО SPARTAK - ТЕРМИНАЛ ДЕПОЗИТА")
    print("═══════════════════════════════════════")
    print("")
    
    -- Инициализация PIM
    print("[1/2] Инициализация PIM...")
    local success, err = pcall(function()
        pim = PIM.new()
    end)
    
    if not success then
        print("✗ Ошибка: " .. tostring(err))
        print("")
        print("Убедитесь что:")
        print("1. PIM установлен в мире")
        print("2. Adapter подключен к компьютеру")
        print("3. PIM находится рядом с Adapter")
        os.exit(1)
    end
    print("✓ PIM инициализирован")
    
    -- Инициализация сети
    print("[2/2] Подключение к серверу казино...")
    network = Network.new()
    
    local connected = false
    for i = 1, 5 do
        if network:findServer() then
            connected = true
            break
        end
        print("  Попытка " .. i .. "/5...")
        os.sleep(1)
    end
    
    if not connected then
        print("✗ Сервер казино не найден!")
        print("Убедитесь что сервер запущен")
        os.exit(1)
    end
    print("✓ Подключено к серверу")
    
    print("")
    print("Инициализация завершена!")
    os.sleep(2)
end

-- ============================================================================
-- ИНТЕРФЕЙС
-- ============================================================================

local function drawHeader()
    gpu.setBackground(0x8B0000)  -- Темно-красный
    gpu.setForeground(0xFFD700)  -- Золотой
    gpu.fill(1, 1, screenWidth, 3, " ")
    
    local title = "═══ КАЗИНО SPARTAK - ДЕПОЗИТ/ВЫВОД ═══"
    local x = math.floor((screenWidth - #title) / 2)
    gpu.set(x, 2, title)
    
    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
end

local function drawInstructions()
    local y = 5
    
    gpu.setForeground(0xFFFF00)  -- Желтый
    gpu.set(2, y, "ИНСТРУКЦИЯ:")
    y = y + 2
    
    gpu.setForeground(0xFFFFFF)
    gpu.set(2, y, "1. Встаньте на блок PIM (Personal Inventory Manager)")
    y = y + 1
    gpu.set(2, y, "2. Деньги из вашего инвентаря будут обнаружены автоматически")
    y = y + 1
    gpu.set(2, y, "3. Выберите действие: Депозит или Вывод")
    y = y + 1
    gpu.set(2, y, "4. Введите сумму и подтвердите")
    y = y + 2
    
    gpu.setForeground(0x00FF00)  -- Зеленый
    gpu.set(2, y, "► Ожидание игрока...")
    
    gpu.setForeground(0xFFFFFF)
end

local function drawPlayerInfo(info)
    local y = 5
    
    gpu.fill(1, y, screenWidth, screenHeight - y, " ")
    
    gpu.setForeground(0x00FF00)
    gpu.set(2, y, "✓ Игрок обнаружен!")
    y = y + 2
    
    gpu.setForeground(0xFFFFFF)
    gpu.set(2, y, "Инвентарь:")
    y = y + 1
    gpu.set(4, y, "Всего слотов: " .. info.totalSlots)
    y = y + 1
    gpu.set(4, y, "Занято: " .. info.usedSlots)
    y = y + 1
    gpu.set(4, y, "Свободно: " .. info.freeSlots)
    y = y + 2
    
    gpu.setForeground(0xFFD700)
    gpu.set(2, y, "Денег в инвентаре: " .. info.money .. " ₽")
    y = y + 2
    
    return y
end

local function drawMenu(y)
    gpu.setForeground(0xFFFFFF)
    gpu.set(2, y, "Выберите действие:")
    y = y + 2
    
    gpu.setForeground(0x00FF00)
    gpu.set(4, y, "[1] Пополнить баланс (Депозит)")
    y = y + 1
    
    gpu.setForeground(0xFF0000)
    gpu.set(4, y, "[2] Вывести средства")
    y = y + 1
    
    gpu.setForeground(0xFFFF00)
    gpu.set(4, y, "[3] Проверить баланс в казино")
    y = y + 1
    
    gpu.setForeground(0x808080)
    gpu.set(4, y, "[Q] Выход")
    y = y + 2
    
    gpu.setForeground(0xFFFFFF)
    return y
end

local function inputAmount(prompt, min, max)
    term.clearLine()
    gpu.setForeground(0xFFFF00)
    io.write(prompt)
    gpu.setForeground(0xFFFFFF)
    
    local input = io.read()
    if not input then
        return nil
    end
    
    local amount = tonumber(input)
    if not amount then
        return nil, "Неверный формат числа"
    end
    
    if amount < min or amount > max then
        return nil, "Сумма должна быть от " .. min .. " до " .. max
    end
    
    return amount
end

-- ============================================================================
-- ОПЕРАЦИИ
-- ============================================================================

local function doDeposit(playerName, availableMoney)
    term.clear()
    drawHeader()
    
    local y = 5
    gpu.setForeground(0x00FF00)
    gpu.set(2, y, "═══ ПОПОЛНЕНИЕ БАЛАНСА ═══")
    y = y + 2
    
    gpu.setForeground(0xFFFFFF)
    gpu.set(2, y, "Доступно в инвентаре: " .. availableMoney .. " ₽")
    y = y + 1
    gpu.set(2, y, "Лимиты: " .. CONFIG.MIN_DEPOSIT .. " - " .. CONFIG.MAX_DEPOSIT .. " ₽")
    y = y + 2
    
    gpu.set(2, y, "")
    
    local amount, err = inputAmount("Введите сумму для пополнения: ", CONFIG.MIN_DEPOSIT, math.min(CONFIG.MAX_DEPOSIT, availableMoney))
    
    if not amount then
        gpu.setForeground(0xFF0000)
        print("✗ Ошибка: " .. (err or "Отменено"))
        os.sleep(2)
        return false
    end
    
    -- Подтверждение
    gpu.setForeground(0xFFFF00)
    print("")
    print("Пополнить баланс на " .. amount .. " ₽?")
    print("[Y] Да  [N] Нет")
    
    local confirm = io.read()
    if not confirm or confirm:lower() ~= "y" then
        print("Отменено")
        os.sleep(1)
        return false
    end
    
    -- Изымаем деньги из инвентаря
    print("")
    gpu.setForeground(0xFFFFFF)
    print("Изъятие денег из инвентаря...")
    
    local success, result, slots = pim:withdrawMoney(amount)
    if not success then
        gpu.setForeground(0xFF0000)
        print("✗ Ошибка: " .. result)
        os.sleep(3)
        return false
    end
    
    print("✓ Изъято " .. result .. " ₽")
    
    -- Отправляем запрос на сервер
    print("Отправка запроса на сервер...")
    
    local response = network:sendRequest({
        action = "deposit",
        player = playerName,
        amount = result
    })
    
    if not response or not response.success then
        gpu.setForeground(0xFF0000)
        print("✗ Ошибка сервера: " .. (response and response.error or "Нет ответа"))
        print("")
        print("ВНИМАНИЕ: Деньги были изъяты из инвентаря!")
        print("Обратитесь к администрации для возврата средств")
        os.sleep(5)
        return false
    end
    
    -- Успех!
    gpu.setForeground(0x00FF00)
    print("")
    print("═══════════════════════════════════════")
    print("  ✓ БАЛАНС УСПЕШНО ПОПОЛНЕН!")
    print("═══════════════════════════════════════")
    print("")
    gpu.setForeground(0xFFFFFF)
    print("Пополнено: " .. result .. " ₽")
    print("Новый баланс: " .. response.balance .. " ₽")
    print("")
    
    os.sleep(3)
    return true
end

local function doWithdraw(playerName)
    term.clear()
    drawHeader()
    
    local y = 5
    gpu.setForeground(0xFF0000)
    gpu.set(2, y, "═══ ВЫВОД СРЕДСТВ ═══")
    y = y + 2
    
    -- Запрашиваем баланс с сервера
    gpu.setForeground(0xFFFFFF)
    gpu.set(2, y, "Запрос баланса...")
    
    local response = network:sendRequest({
        action = "get_balance",
        player = playerName
    })
    
    if not response or not response.success then
        gpu.setForeground(0xFF0000)
        print("")
        print("✗ Ошибка получения баланса")
        os.sleep(2)
        return false
    end
    
    local balance = response.balance
    
    term.clear()
    drawHeader()
    y = 5
    
    gpu.setForeground(0xFF0000)
    gpu.set(2, y, "═══ ВЫВОД СРЕДСТВ ═══")
    y = y + 2
    
    gpu.setForeground(0xFFFFFF)
    gpu.set(2, y, "Ваш баланс в казино: " .. balance .. " ₽")
    y = y + 1
    gpu.set(2, y, "Лимиты: " .. CONFIG.MIN_WITHDRAW .. " - " .. CONFIG.MAX_WITHDRAW .. " ₽")
    y = y + 2
    
    gpu.set(2, y, "")
    
    local amount, err = inputAmount("Введите сумму для вывода: ", CONFIG.MIN_WITHDRAW, math.min(CONFIG.MAX_WITHDRAW, balance))
    
    if not amount then
        gpu.setForeground(0xFF0000)
        print("✗ Ошибка: " .. (err or "Отменено"))
        os.sleep(2)
        return false
    end
    
    -- Подтверждение
    gpu.setForeground(0xFFFF00)
    print("")
    print("Вывести " .. amount .. " ₽?")
    print("[Y] Да  [N] Нет")
    
    local confirm = io.read()
    if not confirm or confirm:lower() ~= "y" then
        print("Отменено")
        os.sleep(1)
        return false
    end
    
    -- Отправляем запрос на вывод
    print("")
    gpu.setForeground(0xFFFFFF)
    print("Отправка запроса на сервер...")
    
    response = network:sendRequest({
        action = "withdraw",
        player = playerName,
        amount = amount
    })
    
    if not response or not response.success then
        gpu.setForeground(0xFF0000)
        print("✗ Ошибка: " .. (response and response.error or "Нет ответа"))
        os.sleep(3)
        return false
    end
    
    -- Выдаем деньги игроку
    print("Выдача денег в инвентарь...")
    
    -- ВАЖНО: Здесь нужна интеграция с банковским сундуком
    -- Пока просто уведомляем
    gpu.setForeground(0xFFFF00)
    print("")
    print("═══════════════════════════════════════")
    print("  ⚠ ВНИМАНИЕ!")
    print("═══════════════════════════════════════")
    print("")
    gpu.setForeground(0xFFFFFF)
    print("Средства списаны с баланса казино")
    print("Сумма: " .. amount .. " ₽")
    print("")
    print("Для получения денег обратитесь к")
    print("администратору или используйте")
    print("банковский сундук рядом с PIM")
    print("")
    print("Новый баланс: " .. response.balance .. " ₽")
    print("")
    
    os.sleep(5)
    return true
end

local function checkBalance(playerName)
    term.clear()
    drawHeader()
    
    local y = 5
    gpu.setForeground(0xFFFF00)
    gpu.set(2, y, "═══ ПРОВЕРКА БАЛАНСА ═══")
    y = y + 2
    
    gpu.setForeground(0xFFFFFF)
    gpu.set(2, y, "Запрос баланса...")
    
    local response = network:sendRequest({
        action = "get_balance",
        player = playerName
    })
    
    term.clear()
    drawHeader()
    y = 5
    
    if not response or not response.success then
        gpu.setForeground(0xFF0000)
        gpu.set(2, y, "✗ Ошибка получения баланса")
        os.sleep(2)
        return
    end
    
    gpu.setForeground(0xFFFF00)
    gpu.set(2, y, "═══ ВАШ БАЛАНС ═══")
    y = y + 2
    
    gpu.setForeground(0x00FF00)
    local balanceText = tostring(response.balance) .. " ₽"
    local x = math.floor((screenWidth - #balanceText) / 2)
    gpu.set(x, y, balanceText)
    y = y + 3
    
    gpu.setForeground(0xFFFFFF)
    gpu.set(2, y, "Нажмите любую клавишу для продолжения...")
    
    event.pull("key_down")
end

-- ============================================================================
-- ГЛАВНЫЙ ЦИКЛ
-- ============================================================================

local function mainLoop()
    while running do
        term.clear()
        drawHeader()
        
        -- Проверяем наличие игрока на PIM
        if not pim:isPlayerPresent() then
            drawInstructions()
            os.sleep(CONFIG.CHECK_INTERVAL)
            
            -- Проверка на выход
            local e, _, char = event.pull(0.1, "key_down")
            if e and (char == string.byte("q") or char == string.byte("Q")) then
                running = false
            end
            
            goto continue
        end
        
        -- Получаем информацию об инвентаре
        local info, err = pim:getInventoryInfo()
        if not info then
            gpu.setForeground(0xFF0000)
            gpu.set(2, 5, "✗ Ошибка: " .. err)
            os.sleep(2)
            goto continue
        end
        
        -- Отображаем информацию
        local y = drawPlayerInfo(info)
        y = drawMenu(y)
        
        -- Ждем ввода
        gpu.set(2, y, "Ваш выбор: ")
        local choice = io.read()
        
        if not choice then
            goto continue
        end
        
        choice = choice:lower()
        
        if choice == "1" then
            -- Депозит
            if info.money == 0 then
                gpu.setForeground(0xFF0000)
                print("✗ В инвентаре нет денег!")
                os.sleep(2)
            else
                -- Запрашиваем имя игрока
                print("")
                gpu.setForeground(0xFFFF00)
                io.write("Введите ваш ник: ")
                gpu.setForeground(0xFFFFFF)
                local playerName = io.read()
                
                if playerName and playerName ~= "" then
                    doDeposit(playerName, info.money)
                end
            end
        elseif choice == "2" then
            -- Вывод
            print("")
            gpu.setForeground(0xFFFF00)
            io.write("Введите ваш ник: ")
            gpu.setForeground(0xFFFFFF)
            local playerName = io.read()
            
            if playerName and playerName ~= "" then
                doWithdraw(playerName)
            end
        elseif choice == "3" then
            -- Проверка баланса
            print("")
            gpu.setForeground(0xFFFF00)
            io.write("Введите ваш ник: ")
            gpu.setForeground(0xFFFFFF)
            local playerName = io.read()
            
            if playerName and playerName ~= "" then
                checkBalance(playerName)
            end
        elseif choice == "q" then
            running = false
        end
        
        ::continue::
    end
end

-- ============================================================================
-- ЗАПУСК
-- ============================================================================

local function main()
    -- Инициализация
    init()
    
    -- Главный цикл
    mainLoop()
    
    -- Завершение
    term.clear()
    print("Терминал депозита завершен")
end

-- Запуск с обработкой ошибок
local success, err = xpcall(main, debug.traceback)
if not success then
    term.clear()
    gpu.setForeground(0xFF0000)
    print("КРИТИЧЕСКАЯ ОШИБКА:")
    print(err)
    gpu.setForeground(0xFFFFFF)
end

