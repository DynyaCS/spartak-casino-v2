-- terminal/main.lua
-- Главный терминальный скрипт для игроков казино "Spartak"

local component = require("component")
local event = require("event")
local term = require("term")
local os = require("os")

-- Загрузка библиотек
package.path = package.path .. ";/home/casino/lib/?.lua;/home/casino/terminal/?.lua"
local Network = require("network")
local UI = require("ui")

-- Инициализация
local gpu = component.gpu
local net = Network.new(false)  -- Клиент

-- Состояние приложения
local state = {
    serverAddress = nil,
    playerName = nil,
    balance = 0,
    currentScreen = "login",
    selectedButton = 1,
    inputValue = ""
}

-- Конфигурация
local CONFIG = {
    MIN_BET = 1,
    MAX_BET = 100
}

-- ============================================================================
-- ЭКРАН ВХОДА
-- ============================================================================

local function drawLoginScreen()
    UI.clear()
    
    local w, h = gpu.getResolution()
    
    -- Логотип
    UI.drawLogo(5)
    
    -- Поле ввода
    UI.drawCentered(15, "Добро пожаловать!", UI.COLORS.YELLOW)
    UI.drawCentered(17, "Введите ваш ник:", UI.COLORS.WHITE)
    UI.drawInput(math.floor(w / 2) - 20, 19, 40, state.inputValue, true)
    
    -- Кнопка
    UI.drawButton(math.floor(w / 2) - 10, 22, "ВОЙТИ", 20, true)
    
    -- Подсказка
    UI.drawCentered(h - 3, "Для пополнения баланса обратитесь к NPC-банкиру", UI.COLORS.GRAY)
end

local function handleLogin()
    if state.inputValue == "" then
        UI.showError("Введите имя игрока!")
        event.pull("key_down")
        return
    end
    
    UI.showLoading("Подключение к серверу...")
    
    -- Поиск сервера
    if not state.serverAddress then
        local addr, err = net:findServer(5)
        if not addr then
            UI.showError("Сервер не найден: " .. (err or "неизвестная ошибка"))
            event.pull("key_down")
            return
        end
        state.serverAddress = addr
    end
    
    -- Отправка запроса на вход
    local response, err = net:request(state.serverAddress, Network.MSG_TYPES.LOGIN, {
        player = state.inputValue
    }, 5)
    
    if not response or not response.success then
        UI.showError("Ошибка входа: " .. (err or response.error or "неизвестная ошибка"))
        event.pull("key_down")
        return
    end
    
    -- Успешный вход
    state.playerName = response.player
    state.balance = response.balance
    state.currentScreen = "menu"
    state.selectedButton = 1
end

-- ============================================================================
-- ГЛАВНОЕ МЕНЮ
-- ============================================================================

local function drawMainMenu()
    UI.clear()
    UI.drawHeader(state.playerName, state.balance)
    
    local w, h = gpu.getResolution()
    
    UI.drawCentered(5, "Выберите игру:", UI.COLORS.YELLOW)
    
    -- Кнопки игр
    local buttonY = 8
    local buttonSpacing = 15
    
    -- Слоты
    local slotsX = math.floor(w / 2) - 45
    UI.drawBox(slotsX, buttonY, 25, 10, nil, state.selectedButton == 1 and UI.COLORS.GOLD or UI.COLORS.GRAY)
    UI.drawCentered(buttonY + 2, "🎰 СЛОТЫ", state.selectedButton == 1 and UI.COLORS.YELLOW or UI.COLORS.WHITE)
    UI.drawCentered(buttonY + 4, "Ставка: 1-100₽", UI.COLORS.WHITE)
    UI.drawButton(slotsX + 3, buttonY + 7, "ИГРАТЬ", 19, state.selectedButton == 1)
    
    -- Рулетка
    local rouletteX = math.floor(w / 2) - 12
    UI.drawBox(rouletteX, buttonY, 25, 10, nil, state.selectedButton == 2 and UI.COLORS.GOLD or UI.COLORS.GRAY)
    UI.drawCentered(buttonY + 2, "🎡 РУЛЕТКА", state.selectedButton == 2 and UI.COLORS.YELLOW or UI.COLORS.WHITE)
    UI.drawCentered(buttonY + 4, "Ставка: 1-100₽", UI.COLORS.WHITE)
    UI.drawButton(rouletteX + 3, buttonY + 7, "ИГРАТЬ", 19, state.selectedButton == 2)
    
    -- Блэкджек
    local blackjackX = math.floor(w / 2) + 20
    UI.drawBox(blackjackX, buttonY, 25, 10, nil, state.selectedButton == 3 and UI.COLORS.GOLD or UI.COLORS.GRAY)
    UI.drawCentered(buttonY + 2, "🃏 БЛЭКДЖЕК", state.selectedButton == 3 and UI.COLORS.YELLOW or UI.COLORS.WHITE)
    UI.drawCentered(buttonY + 4, "Ставка: 1-100₽", UI.COLORS.WHITE)
    UI.drawButton(blackjackX + 3, buttonY + 7, "ИГРАТЬ", 19, state.selectedButton == 3)
    
    -- Баланс
    local balanceY = 20
    UI.drawBox(math.floor(w / 2) - 20, balanceY, 40, 8, " 💰 МОЙ БАЛАНС ", UI.COLORS.GOLD)
    UI.drawCentered(balanceY + 2, "Баланс: " .. state.balance .. "₽", UI.COLORS.YELLOW)
    UI.drawCentered(balanceY + 4, "Для пополнения/вывода", UI.COLORS.WHITE)
    UI.drawCentered(balanceY + 5, "обратитесь к NPC-банкиру", UI.COLORS.WHITE)
    
    -- Управление
    UI.drawCentered(h - 3, "[←/→] Выбор  [Enter] Подтвердить  [Q] Выход", UI.COLORS.GRAY)
end

local function handleMainMenu()
    local _, _, char, code = event.pull("key_down")
    
    -- Стрелки влево/вправо
    if code == 203 then  -- Влево
        state.selectedButton = state.selectedButton - 1
        if state.selectedButton < 1 then
            state.selectedButton = 3
        end
    elseif code == 205 then  -- Вправо
        state.selectedButton = state.selectedButton + 1
        if state.selectedButton > 3 then
            state.selectedButton = 1
        end
    elseif code == 28 then  -- Enter
        if state.selectedButton == 1 then
            state.currentScreen = "slots"
        elseif state.selectedButton == 2 then
            state.currentScreen = "roulette"
        elseif state.selectedButton == 3 then
            state.currentScreen = "blackjack"
        end
        state.inputValue = ""
    elseif char == string.byte("q") or char == string.byte("Q") then
        return false  -- Выход
    end
    
    return true
end

-- ============================================================================
-- ИГРА: СЛОТЫ
-- ============================================================================

local function drawSlotsScreen()
    UI.clear()
    UI.drawHeader(state.playerName, state.balance)
    
    local w, h = gpu.getResolution()
    
    -- Слоты
    local reels = state.slotsReels or {"🍒", "🍋", "🍊"}
    UI.drawSlots(reels, state.slotsSpinning or false)
    
    -- Ввод ставки
    UI.drawCentered(h / 2 + 8, "Ставка: (1-100₽)", UI.COLORS.WHITE)
    UI.drawInput(math.floor(w / 2) - 10, h / 2 + 10, 20, state.inputValue, true)
    
    -- Кнопка
    UI.drawButton(math.floor(w / 2) - 15, h / 2 + 13, "КРУТИТЬ", 30, true)
    
    -- Таблица выплат
    UI.drawPayoutTable(5, h / 2 - 5)
    
    -- Управление
    UI.drawCentered(h - 3, "[Enter] Крутить  [Backspace] Назад", UI.COLORS.GRAY)
end

local function handleSlots()
    local _, _, char, code = event.pull("key_down")
    
    if code == 28 then  -- Enter
        local bet = tonumber(state.inputValue)
        if not bet or bet < CONFIG.MIN_BET or bet > CONFIG.MAX_BET then
            UI.showError("Ставка должна быть от " .. CONFIG.MIN_BET .. " до " .. CONFIG.MAX_BET)
            event.pull("key_down")
            return true
        end
        
        if bet > state.balance then
            UI.showError("Недостаточно средств!")
            event.pull("key_down")
            return true
        end
        
        -- Анимация вращения
        state.slotsSpinning = true
        drawSlotsScreen()
        
        for i = 1, 10 do
            state.slotsReels = {
                ({"🍒", "🍋", "🍊", "🍇", "💎", "7️⃣", "⭐"})[math.random(1, 7)],
                ({"🍒", "🍋", "🍊", "🍇", "💎", "7️⃣", "⭐"})[math.random(1, 7)],
                ({"🍒", "🍋", "🍊", "🍇", "💎", "7️⃣", "⭐"})[math.random(1, 7)]
            }
            drawSlotsScreen()
            os.sleep(0.1)
        end
        
        state.slotsSpinning = false
        
        -- Отправка запроса на сервер
        UI.showLoading("Обработка...")
        local response, err = net:request(state.serverAddress, Network.MSG_TYPES.PLAY, {
            player = state.playerName,
            game = "slots",
            bet = bet
        }, 5)
        
        if not response or not response.success then
            UI.showError("Ошибка: " .. (err or response.error or "неизвестная ошибка"))
            event.pull("key_down")
            return true
        end
        
        -- Показываем результат
        state.slotsReels = response.reels
        state.balance = response.balance
        drawSlotsScreen()
        os.sleep(1)
        
        -- Показываем окно результата
        UI.drawResult(response, bet)
        event.pull("key_down")
        
        state.currentScreen = "menu"
        state.inputValue = ""
        
    elseif code == 14 then  -- Backspace
        if #state.inputValue > 0 then
            state.inputValue = string.sub(state.inputValue, 1, -2)
        else
            state.currentScreen = "menu"
            state.inputValue = ""
        end
    elseif char >= 48 and char <= 57 then  -- Цифры
        state.inputValue = state.inputValue .. string.char(char)
    end
    
    return true
end

-- ============================================================================
-- ИГРА: РУЛЕТКА
-- ============================================================================

local function drawRouletteScreen()
    UI.clear()
    UI.drawHeader(state.playerName, state.balance)
    
    local w, h = gpu.getResolution()
    
    -- Рулетка
    UI.drawRoulette(state.rouletteNumber, state.rouletteColor, state.rouletteSpinning or false)
    
    -- Ввод ставки
    UI.drawCentered(h / 2 + 10, "Ставка: (1-100₽)", UI.COLORS.WHITE)
    UI.drawInput(math.floor(w / 2) - 10, h / 2 + 12, 20, state.inputValue, state.rouletteStep == 1)
    
    -- Выбор типа ставки
    if state.rouletteStep and state.rouletteStep >= 2 then
        UI.drawCentered(h / 2 + 15, "Тип ставки:", UI.COLORS.WHITE)
        
        local types = {
            {key = "1", name = "Число (x35)"},
            {key = "2", name = "Красное (x2)"},
            {key = "3", name = "Черное (x2)"},
            {key = "4", name = "Четное (x2)"},
            {key = "5", name = "Нечетное (x2)"}
        }
        
        for i, t in ipairs(types) do
            local text = "[" .. t.key .. "] " .. t.name
            UI.drawCentered(h / 2 + 16 + i, text, UI.COLORS.WHITE)
        end
    end
    
    -- Управление
    UI.drawCentered(h - 3, "[Enter] Далее  [Backspace] Назад", UI.COLORS.GRAY)
end

local function handleRoulette()
    state.rouletteStep = state.rouletteStep or 1
    
    local _, _, char, code = event.pull("key_down")
    
    if code == 28 then  -- Enter
        if state.rouletteStep == 1 then
            -- Проверка ставки
            local bet = tonumber(state.inputValue)
            if not bet or bet < CONFIG.MIN_BET or bet > CONFIG.MAX_BET then
                UI.showError("Ставка должна быть от " .. CONFIG.MIN_BET .. " до " .. CONFIG.MAX_BET)
                event.pull("key_down")
                return true
            end
            
            if bet > state.balance then
                UI.showError("Недостаточно средств!")
                event.pull("key_down")
                return true
            end
            
            state.rouletteBet = bet
            state.rouletteStep = 2
            
        elseif state.rouletteStep == 2 then
            -- Ожидание выбора типа ставки
            return true
        end
        
    elseif code == 14 then  -- Backspace
        if state.rouletteStep == 2 then
            state.rouletteStep = 1
            state.inputValue = tostring(state.rouletteBet or "")
        elseif #state.inputValue > 0 then
            state.inputValue = string.sub(state.inputValue, 1, -2)
        else
            state.currentScreen = "menu"
            state.inputValue = ""
            state.rouletteStep = nil
        end
        
    elseif state.rouletteStep == 1 and char >= 48 and char <= 57 then  -- Цифры на шаге 1
        state.inputValue = state.inputValue .. string.char(char)
        
    elseif state.rouletteStep == 2 then  -- Выбор типа ставки
        local betType, betValue
        
        if char == string.byte("1") then
            betType = "number"
            -- Запросить число
            UI.showMessage("Введите число", "Введите число от 0 до 36", UI.COLORS.GOLD)
            event.pull("key_down")
            -- TODO: Реализовать ввод числа
            betValue = "0"
        elseif char == string.byte("2") then
            betType = "red"
            betValue = nil
        elseif char == string.byte("3") then
            betType = "black"
            betValue = nil
        elseif char == string.byte("4") then
            betType = "even"
            betValue = nil
        elseif char == string.byte("5") then
            betType = "odd"
            betValue = nil
        else
            return true
        end
        
        -- Анимация вращения
        state.rouletteSpinning = true
        drawRouletteScreen()
        os.sleep(2)
        state.rouletteSpinning = false
        
        -- Отправка запроса
        UI.showLoading("Обработка...")
        local response, err = net:request(state.serverAddress, Network.MSG_TYPES.PLAY, {
            player = state.playerName,
            game = "roulette",
            bet = state.rouletteBet,
            betType = betType,
            betValue = betValue
        }, 5)
        
        if not response or not response.success then
            UI.showError("Ошибка: " .. (err or response.error or "неизвестная ошибка"))
            event.pull("key_down")
            state.currentScreen = "menu"
            return true
        end
        
        -- Показываем результат
        state.rouletteNumber = response.number
        state.rouletteColor = response.color
        state.balance = response.balance
        drawRouletteScreen()
        os.sleep(2)
        
        UI.drawResult(response, state.rouletteBet)
        event.pull("key_down")
        
        state.currentScreen = "menu"
        state.inputValue = ""
        state.rouletteStep = nil
    end
    
    return true
end

-- ============================================================================
-- ИГРА: БЛЭКДЖЕК
-- ============================================================================

local function drawBlackjackScreen()
    UI.clear()
    UI.drawHeader(state.playerName, state.balance)
    
    local w, h = gpu.getResolution()
    
    if not state.blackjackGameState or state.blackjackGameState.stage == "bet" then
        -- Экран ввода ставки
        UI.drawCentered(h / 2 - 2, "🃏 БЛЭКДЖЕК", UI.COLORS.GOLD)
        UI.drawCentered(h / 2, "Ставка: (1-100₽)", UI.COLORS.WHITE)
        UI.drawInput(math.floor(w / 2) - 10, h / 2 + 2, 20, state.inputValue, true)
        UI.drawButton(math.floor(w / 2) - 10, h / 2 + 5, "НАЧАТЬ ИГРУ", 20, true)
    else
        -- Игровой экран
        local gameState = state.blackjackGameState
        
        -- Рука дилера
        local dealerValue = "?"
        local hideSecond = gameState.stage ~= "finished"
        
        if gameState.stage == "finished" then
            local sum = 0
            for _, card in ipairs(gameState.dealerHand) do
                local val = card.rank == "A" and 11 or (card.rank == "J" or card.rank == "Q" or card.rank == "K") and 10 or tonumber(card.rank)
                sum = sum + val
            end
            dealerValue = tostring(sum)
        end
        
        UI.drawBlackjackHand(10, 5, gameState.dealerHand, "ДИЛЕР", dealerValue, hideSecond)
        
        -- Рука игрока
        if gameState.playerHand then
            local playerValue = gameState.playerValue or 0
            UI.drawBlackjackHand(10, 12, gameState.playerHand, "ВЫ", playerValue, false)
        end
        
        -- Кнопки действий
        if gameState.stage == "player_turn" then
            UI.drawButton(20, h - 8, "HIT (Взять)", 20, state.selectedButton == 1)
            UI.drawButton(45, h - 8, "STAND (Стоп)", 20, state.selectedButton == 2)
            UI.drawButton(70, h - 8, "DOUBLE (x2)", 20, state.selectedButton == 3)
        end
    end
    
    -- Управление
    UI.drawCentered(h - 3, "[←/→] Выбор  [Enter] Подтвердить  [Backspace] Назад", UI.COLORS.GRAY)
end

local function handleBlackjack()
    -- Продолжение в следующей части...
    state.currentScreen = "menu"
    UI.showMessage("В разработке", "Игра Блэкджек скоро будет доступна!", UI.COLORS.YELLOW)
    event.pull("key_down")
    return true
end

-- ============================================================================
-- ГЛАВНЫЙ ЦИКЛ
-- ============================================================================

local function main()
    math.randomseed(os.time())
    
    -- Проверка разрешения экрана
    local w, h = gpu.getResolution()
    if w < 80 or h < 25 then
        print("Ошибка: Требуется экран Tier 2 или выше (минимум 80x25)")
        return
    end
    
    -- Главный цикл
    while true do
        if state.currentScreen == "login" then
            drawLoginScreen()
            local _, _, char, code = event.pull("key_down")
            
            if code == 28 then  -- Enter
                handleLogin()
            elseif code == 14 and #state.inputValue > 0 then  -- Backspace
                state.inputValue = string.sub(state.inputValue, 1, -2)
            elseif char and char >= 32 and char < 127 then
                state.inputValue = state.inputValue .. string.char(char)
            end
            
        elseif state.currentScreen == "menu" then
            drawMainMenu()
            if not handleMainMenu() then
                break
            end
            
        elseif state.currentScreen == "slots" then
            drawSlotsScreen()
            if not handleSlots() then
                break
            end
            
        elseif state.currentScreen == "roulette" then
            drawRouletteScreen()
            if not handleRoulette() then
                break
            end
            
        elseif state.currentScreen == "blackjack" then
            drawBlackjackScreen()
            if not handleBlackjack() then
                break
            end
        end
    end
    
    -- Выход
    UI.clear()
    print("Спасибо за игру в казино Spartak!")
end

-- Запуск с обработкой ошибок
local success, err = pcall(main)
if not success then
    print("Критическая ошибка: " .. tostring(err))
end

