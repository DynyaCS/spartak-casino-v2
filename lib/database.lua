-- database.lua
-- Библиотека для управления базой данных игроков казино "Spartak"

local serialization = require("serialization")
local filesystem = require("filesystem")

local Database = {}
Database.__index = Database

-- Путь к файлу базы данных
local DB_PATH = "/home/casino/data/players.db"
local BACKUP_PATH = "/home/casino/data/players.db.backup"

-- Создание нового экземпляра базы данных
function Database.new()
    local self = setmetatable({}, Database)
    self.data = {
        players = {},
        casino_stats = {
            total_players = 0,
            total_balance = 0,
            house_profit = 0,
            total_games_played = 0
        }
    }
    self:load()
    return self
end

-- Загрузка базы данных из файла
function Database:load()
    if not filesystem.exists(DB_PATH) then
        print("[DB] База данных не найдена, создаю новую...")
        self:save()
        return true
    end
    
    local file = io.open(DB_PATH, "r")
    if not file then
        print("[DB] Ошибка открытия файла базы данных!")
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    local success, loaded = pcall(serialization.unserialize, content)
    if success and loaded then
        self.data = loaded
        print("[DB] База данных загружена успешно")
        return true
    else
        print("[DB] Ошибка десериализации, используется пустая БД")
        return false
    end
end

-- Сохранение базы данных в файл
function Database:save()
    -- Создаем директорию если не существует
    local dir = filesystem.path(DB_PATH)
    if not filesystem.exists(dir) then
        filesystem.makeDirectory(dir)
    end
    
    -- Создаем резервную копию
    if filesystem.exists(DB_PATH) then
        filesystem.copy(DB_PATH, BACKUP_PATH)
    end
    
    local file = io.open(DB_PATH, "w")
    if not file then
        print("[DB] Ошибка сохранения базы данных!")
        return false
    end
    
    local serialized = serialization.serialize(self.data)
    file:write(serialized)
    file:close()
    
    return true
end

-- Проверка существования игрока
function Database:playerExists(playerName)
    return self.data.players[playerName] ~= nil
end

-- Создание нового игрока
function Database:createPlayer(playerName, initialBalance)
    if self:playerExists(playerName) then
        return false, "Игрок уже существует"
    end
    
    initialBalance = initialBalance or 0
    
    self.data.players[playerName] = {
        balance = initialBalance,
        total_deposited = initialBalance,
        total_withdrawn = 0,
        total_wagered = 0,
        total_won = 0,
        last_activity = os.time(),
        games_played = {
            slots = 0,
            roulette = 0,
            blackjack = 0
        },
        created_at = os.time()
    }
    
    self.data.casino_stats.total_players = self.data.casino_stats.total_players + 1
    self.data.casino_stats.total_balance = self.data.casino_stats.total_balance + initialBalance
    
    self:save()
    return true
end

-- Получить баланс игрока
function Database:getBalance(playerName)
    if not self:playerExists(playerName) then
        return nil, "Игрок не найден"
    end
    
    return self.data.players[playerName].balance
end

-- Добавить средства на баланс
function Database:addBalance(playerName, amount)
    if not self:playerExists(playerName) then
        return false, "Игрок не найден"
    end
    
    if amount <= 0 then
        return false, "Сумма должна быть положительной"
    end
    
    self.data.players[playerName].balance = self.data.players[playerName].balance + amount
    self.data.players[playerName].total_deposited = self.data.players[playerName].total_deposited + amount
    self.data.players[playerName].last_activity = os.time()
    
    self.data.casino_stats.total_balance = self.data.casino_stats.total_balance + amount
    
    self:save()
    return true
end

-- Снять средства с баланса
function Database:removeBalance(playerName, amount)
    if not self:playerExists(playerName) then
        return false, "Игрок не найден"
    end
    
    if amount <= 0 then
        return false, "Сумма должна быть положительной"
    end
    
    local currentBalance = self.data.players[playerName].balance
    if currentBalance < amount then
        return false, "Недостаточно средств"
    end
    
    self.data.players[playerName].balance = currentBalance - amount
    self.data.players[playerName].last_activity = os.time()
    
    self.data.casino_stats.total_balance = self.data.casino_stats.total_balance - amount
    
    self:save()
    return true
end

-- Обработка депозита
function Database:deposit(playerName, amount)
    if not self:playerExists(playerName) then
        -- Создаем нового игрока с начальным балансом
        return self:createPlayer(playerName, amount)
    else
        return self:addBalance(playerName, amount)
    end
end

-- Обработка вывода средств
function Database:withdraw(playerName, amount)
    if not self:playerExists(playerName) then
        return false, "Игрок не найден"
    end
    
    local success, err = self:removeBalance(playerName, amount)
    if success then
        self.data.players[playerName].total_withdrawn = self.data.players[playerName].total_withdrawn + amount
        self:save()
    end
    
    return success, err
end

-- Обновить статистику после игры
function Database:updateStats(playerName, game, bet, wonAmount)
    if not self:playerExists(playerName) then
        return false, "Игрок не найден"
    end
    
    local player = self.data.players[playerName]
    
    -- Обновляем статистику игрока
    player.total_wagered = player.total_wagered + bet
    player.total_won = player.total_won + wonAmount
    player.last_activity = os.time()
    
    if player.games_played[game] then
        player.games_played[game] = player.games_played[game] + 1
    end
    
    -- Обновляем статистику казино
    self.data.casino_stats.total_games_played = self.data.casino_stats.total_games_played + 1
    
    -- Прибыль казино = ставка - выигрыш
    local profit = bet - wonAmount
    self.data.casino_stats.house_profit = self.data.casino_stats.house_profit + profit
    
    self:save()
    return true
end

-- Получить информацию об игроке
function Database:getPlayerInfo(playerName)
    if not self:playerExists(playerName) then
        return nil, "Игрок не найден"
    end
    
    return self.data.players[playerName]
end

-- Получить статистику казино
function Database:getCasinoStats()
    return self.data.casino_stats
end

-- Получить топ игроков по балансу
function Database:getTopPlayers(limit)
    limit = limit or 10
    
    local players = {}
    for name, data in pairs(self.data.players) do
        table.insert(players, {name = name, balance = data.balance})
    end
    
    table.sort(players, function(a, b) return a.balance > b.balance end)
    
    local result = {}
    for i = 1, math.min(limit, #players) do
        table.insert(result, players[i])
    end
    
    return result
end

-- Очистка неактивных игроков (старше 30 дней без активности)
function Database:cleanupInactivePlayers()
    local currentTime = os.time()
    local thirtyDays = 30 * 24 * 60 * 60
    local removed = 0
    
    for playerName, data in pairs(self.data.players) do
        if currentTime - data.last_activity > thirtyDays and data.balance == 0 then
            self.data.players[playerName] = nil
            self.data.casino_stats.total_players = self.data.casino_stats.total_players - 1
            removed = removed + 1
        end
    end
    
    if removed > 0 then
        self:save()
        print("[DB] Удалено неактивных игроков: " .. removed)
    end
    
    return removed
end

return Database

