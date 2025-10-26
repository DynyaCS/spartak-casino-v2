-- server/main.lua
-- Главный серверный скрипт казино "Spartak"

local component = require("component")
local term = require("term")
local event = require("event")
local os = require("os")

-- Загрузка библиотек
package.path = package.path .. ";/home/casino/lib/?.lua"
local Database = require("database")
local Games = require("games")
local Network = require("network")

-- Инициализация
local gpu = component.gpu
local db = Database.new()
local net = Network.new(true)  -- Сервер

-- Конфигурация
local CONFIG = {
    MIN_BET = 1,
    MAX_BET = 100,
    BACKUP_INTERVAL = 1800,  -- 30 минут
    LOG_FILE = "/home/casino/logs/transactions.log"
}

-- Цвета
local COLORS = {
    WHITE = 0xFFFFFF,
    YELLOW = 0xFFFF00,
    GREEN = 0x00FF00,
    RED = 0xFF0000,
    GOLD = 0xFFD700,
    GRAY = 0x808080
}

-- Логирование
local function log(message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logMessage = "[" .. timestamp .. "] " .. message
    
    print(logMessage)
    
    -- Записываем в файл
    local file = io.open(CONFIG.LOG_FILE, "a")
    if file then
        file:write(logMessage .. "\n")
        file:close()
    end
end

-- Отрисовка интерфейса сервера
local function drawServerUI()
    term.clear()
    gpu.setBackground(0x000000)
    gpu.setForeground(COLORS.GOLD)
    
    local w, h = gpu.getResolution()
    
    -- Заголовок
    local title = "═══ КАЗИНО SPARTAK - СЕРВЕР ═══"
    gpu.set(math.floor((w - #title) / 2), 2, title)
    
    gpu.setForeground(COLORS.WHITE)
    gpu.set(2, 4, "Статус: РАБОТАЕТ")
    gpu.set(2, 5, "Порт: " .. Network.PORT)
    
    -- Статистика казино
    local stats = db:getCasinoStats()
    gpu.setForeground(COLORS.YELLOW)
    gpu.set(2, 7, "═══ СТАТИСТИКА ═══")
    gpu.setForeground(COLORS.WHITE)
    gpu.set(2, 8, "Всего игроков: " .. stats.total_players)
    gpu.set(2, 9, "Общий баланс: " .. stats.total_balance .. "₽")
    gpu.set(2, 10, "Прибыль казино: " .. stats.house_profit .. "₽")
    gpu.set(2, 11, "Игр сыграно: " .. stats.total_games_played)
    
    -- Топ игроков
    gpu.setForeground(COLORS.YELLOW)
    gpu.set(2, 13, "═══ ТОП-5 ИГРОКОВ ═══")
    gpu.setForeground(COLORS.WHITE)
    
    local topPlayers = db:getTopPlayers(5)
    for i, player in ipairs(topPlayers) do
        gpu.set(2, 13 + i, i .. ". " .. player.name .. " - " .. player.balance .. "₽")
    end
    
    -- Логи
    gpu.setForeground(COLORS.YELLOW)
    gpu.set(2, 20, "═══ ПОСЛЕДНИЕ СОБЫТИЯ ═══")
    gpu.setForeground(COLORS.GRAY)
    gpu.set(2, 21, "(Логи записываются в " .. CONFIG.LOG_FILE .. ")")
    
    -- Управление
    gpu.setForeground(COLORS.RED)
    gpu.set(2, h - 2, "[Q] - Остановить сервер")
end

-- Обработчик входа игрока
local function handleLogin(data, senderAddress)
    local playerName = data.player
    
    if not playerName or playerName == "" then
        return {success = false, error = "Имя игрока не указано"}
    end
    
    local balance = 0
    if db:playerExists(playerName) then
        balance = db:getBalance(playerName)
    else
        db:createPlayer(playerName, 0)
    end
    
    log("LOGIN: " .. playerName .. " подключился (Баланс: " .. balance .. "₽)")
    
    return {
        success = true,
        player = playerName,
        balance = balance
    }
end

-- Обработчик депозита
local function handleDeposit(data, senderAddress)
    local playerName = data.player
    local amount = tonumber(data.amount)
    
    if not amount or amount <= 0 then
        return {success = false, error = "Неверная сумма"}
    end
    
    local success, err = db:deposit(playerName, amount)
    if not success then
        return {success = false, error = err}
    end
    
    local newBalance = db:getBalance(playerName)
    log("DEPOSIT: " .. playerName .. " пополнил " .. amount .. "₽ (Баланс: " .. newBalance .. "₽)")
    
    return {
        success = true,
        balance = newBalance
    }
end

-- Обработчик вывода средств
local function handleWithdraw(data, senderAddress)
    local playerName = data.player
    local amount = tonumber(data.amount)
    
    if not amount or amount <= 0 then
        return {success = false, error = "Неверная сумма"}
    end
    
    local success, err = db:withdraw(playerName, amount)
    if not success then
        return {success = false, error = err}
    end
    
    local newBalance = db:getBalance(playerName)
    log("WITHDRAW: " .. playerName .. " вывел " .. amount .. "₽ (Баланс: " .. newBalance .. "₽)")
    
    return {
        success = true,
        balance = newBalance,
        message = "Обратитесь к NPC-банкиру для получения средств"
    }
end

-- Обработчик запроса баланса
local function handleBalance(data, senderAddress)
    local playerName = data.player
    
    if not db:playerExists(playerName) then
        return {success = false, error = "Игрок не найден"}
    end
    
    local balance = db:getBalance(playerName)
    
    return {
        success = true,
        balance = balance
    }
end

-- Обработчик игры
local function handlePlay(data, senderAddress)
    local playerName = data.player
    local game = data.game
    local bet = tonumber(data.bet)
    
    -- Проверка ставки
    if not bet or bet < CONFIG.MIN_BET or bet > CONFIG.MAX_BET then
        return {success = false, error = "Ставка должна быть от " .. CONFIG.MIN_BET .. " до " .. CONFIG.MAX_BET}
    end
    
    -- Проверка баланса
    local balance = db:getBalance(playerName)
    if not balance or balance < bet then
        return {success = false, error = "Недостаточно средств"}
    end
    
    -- Снимаем ставку
    local success, err = db:removeBalance(playerName, bet)
    if not success then
        return {success = false, error = err}
    end
    
    -- Играем
    local result
    if game == "slots" then
        result = Games.Slots.play(bet)
    elseif game == "roulette" then
        result = Games.Roulette.play(bet, data.betType, data.betValue)
    elseif game == "blackjack" then
        if data.action == "start" then
            result = Games.Blackjack.start(bet)
        else
            result = Games.Blackjack.action(data.gameState, data.action, bet)
        end
    else
        -- Возвращаем ставку
        db:addBalance(playerName, bet)
        return {success = false, error = "Неизвестная игра"}
    end
    
    if not result.success then
        -- Возвращаем ставку при ошибке
        db:addBalance(playerName, bet)
        return result
    end
    
    -- Обрабатываем выигрыш
    local winAmount = result.winAmount or 0
    if winAmount > 0 then
        db:addBalance(playerName, winAmount)
    end
    
    -- Обновляем статистику
    db:updateStats(playerName, game, bet, winAmount)
    
    local newBalance = db:getBalance(playerName)
    result.balance = newBalance
    
    -- Логируем
    local profit = winAmount - bet
    if profit > 0 then
        log("PLAY: " .. playerName .. " играл в " .. game .. ", ставка " .. bet .. "₽, выиграл " .. winAmount .. "₽ (+" .. profit .. "₽)")
    else
        log("PLAY: " .. playerName .. " играл в " .. game .. ", ставка " .. bet .. "₽, проиграл (" .. profit .. "₽)")
    end
    
    return result
end

-- Обработчик информации об игроке
local function handlePlayerInfo(data, senderAddress)
    local playerName = data.player
    
    local info, err = db:getPlayerInfo(playerName)
    if not info then
        return {success = false, error = err}
    end
    
    return {
        success = true,
        info = info
    }
end

-- Обработчик статистики казино
local function handleCasinoStats(data, senderAddress)
    local stats = db:getCasinoStats()
    local topPlayers = db:getTopPlayers(10)
    
    return {
        success = true,
        stats = stats,
        topPlayers = topPlayers
    }
end

-- Обработчик пинга
local function handlePing(data, senderAddress)
    return {
        success = true,
        server = "Spartak Casino Server",
        version = "1.0"
    }
end

-- Регистрация обработчиков
net:registerHandler(Network.MSG_TYPES.LOGIN, handleLogin)
net:registerHandler(Network.MSG_TYPES.DEPOSIT, handleDeposit)
net:registerHandler(Network.MSG_TYPES.WITHDRAW, handleWithdraw)
net:registerHandler(Network.MSG_TYPES.BALANCE, handleBalance)
net:registerHandler(Network.MSG_TYPES.PLAY, handlePlay)
net:registerHandler(Network.MSG_TYPES.PLAYER_INFO, handlePlayerInfo)
net:registerHandler(Network.MSG_TYPES.CASINO_STATS, handleCasinoStats)
net:registerHandler(Network.MSG_TYPES.PING, handlePing)

-- Автоматическое резервное копирование
local function startBackupTimer()
    event.timer(CONFIG.BACKUP_INTERVAL, function()
        db:save()
        log("AUTO-BACKUP: База данных сохранена")
    end, math.huge)  -- Бесконечное повторение
end

-- Обработчик нажатия клавиш
local function handleKeyPress(_, _, char, code)
    if char == string.byte("q") or char == string.byte("Q") then
        return false  -- Остановить сервер
    end
    return true
end

-- Главная функция
local function main()
    log("═══════════════════════════════════════")
    log("СЕРВЕР КАЗИНО SPARTAK ЗАПУЩЕН")
    log("═══════════════════════════════════════")
    
    -- Инициализация
    math.randomseed(os.time())
    
    -- Отрисовка интерфейса
    drawServerUI()
    
    -- Запуск сетевого прослушивания
    net:listen()
    
    -- Запуск автосохранения
    startBackupTimer()
    
    -- Основной цикл
    log("Сервер готов к работе")
    
    event.listen("key_down", handleKeyPress)
    
    -- Ожидание завершения
    while true do
        local eventType = event.pull(1)
        if eventType == "key_down" then
            local _, _, char = event.pull(0, "key_down")
            if char == string.byte("q") or char == string.byte("Q") then
                break
            end
        end
        
        -- Обновляем интерфейс каждую секунду
        drawServerUI()
    end
    
    -- Завершение работы
    log("Остановка сервера...")
    net:stop()
    db:save()
    log("Сервер остановлен")
    
    term.clear()
    print("Сервер казино Spartak остановлен")
end

-- Запуск с обработкой ошибок
local success, err = pcall(main)
if not success then
    log("КРИТИЧЕСКАЯ ОШИБКА: " .. tostring(err))
    print("Ошибка: " .. tostring(err))
    db:save()
end

