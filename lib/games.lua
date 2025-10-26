-- games.lua
-- Библиотека игровой логики для казино "Spartak"

local Games = {}

-- ============================================================================
-- СЛОТЫ (Slot Machine)
-- ============================================================================

Games.Slots = {}

-- Символы слотов
Games.Slots.SYMBOLS = {"🍒", "🍋", "🍊", "🍇", "💎", "7️⃣", "⭐"}

-- Веса символов (для настройки вероятности)
Games.Slots.WEIGHTS = {
    ["🍒"] = 30,  -- 30% вероятность
    ["🍋"] = 25,  -- 25%
    ["🍊"] = 20,  -- 20%
    ["🍇"] = 15,  -- 15%
    ["💎"] = 7,   -- 7%
    ["7️⃣"] = 2,   -- 2%
    ["⭐"] = 1    -- 1%
}

-- Таблица выплат (множители)
Games.Slots.PAYOUTS = {
    ["⭐⭐⭐"] = 100,
    ["7️⃣7️⃣7️⃣"] = 50,
    ["💎💎💎"] = 25,
    ["🍇🍇🍇"] = 10,
    ["🍊🍊🍊"] = 5,
    ["🍋🍋🍋"] = 3,
    ["🍒🍒🍒"] = 2
}

-- Генерация случайного символа с учетом весов
function Games.Slots.generateSymbol()
    local totalWeight = 0
    for _, weight in pairs(Games.Slots.WEIGHTS) do
        totalWeight = totalWeight + weight
    end
    
    local random = math.random(1, totalWeight)
    local currentWeight = 0
    
    for symbol, weight in pairs(Games.Slots.WEIGHTS) do
        currentWeight = currentWeight + weight
        if random <= currentWeight then
            return symbol
        end
    end
    
    return Games.Slots.SYMBOLS[1]  -- Fallback
end

-- Расчет множителя выигрыша
function Games.Slots.calculateMultiplier(reel1, reel2, reel3)
    local combination = reel1 .. reel2 .. reel3
    
    -- Проверяем точное совпадение трех символов
    if Games.Slots.PAYOUTS[combination] then
        return Games.Slots.PAYOUTS[combination]
    end
    
    -- Проверяем два одинаковых символа
    if reel1 == reel2 or reel2 == reel3 or reel1 == reel3 then
        return 1  -- Возврат ставки
    end
    
    return 0  -- Проигрыш
end

-- Основная функция игры в слоты
function Games.Slots.play(bet)
    if bet < 1 or bet > 100 then
        return {success = false, error = "Ставка должна быть от 1 до 100"}
    end
    
    -- Генерируем результат
    local reel1 = Games.Slots.generateSymbol()
    local reel2 = Games.Slots.generateSymbol()
    local reel3 = Games.Slots.generateSymbol()
    
    -- Рассчитываем выигрыш
    local multiplier = Games.Slots.calculateMultiplier(reel1, reel2, reel3)
    local winAmount = bet * multiplier
    
    return {
        success = true,
        reels = {reel1, reel2, reel3},
        multiplier = multiplier,
        winAmount = winAmount,
        profit = winAmount - bet
    }
end

-- ============================================================================
-- РУЛЕТКА (Roulette)
-- ============================================================================

Games.Roulette = {}

-- Цвета чисел на рулетке
Games.Roulette.RED_NUMBERS = {1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36}
Games.Roulette.BLACK_NUMBERS = {2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35}

-- Типы ставок
Games.Roulette.BET_TYPES = {
    NUMBER = "number",       -- x35
    RED = "red",            -- x2
    BLACK = "black",        -- x2
    EVEN = "even",          -- x2
    ODD = "odd",            -- x2
    LOW = "low",            -- x2 (1-18)
    HIGH = "high",          -- x2 (19-36)
    DOZEN1 = "dozen1",      -- x3 (1-12)
    DOZEN2 = "dozen2",      -- x3 (13-24)
    DOZEN3 = "dozen3"       -- x3 (25-36)
}

-- Получить цвет числа
function Games.Roulette.getColor(number)
    if number == 0 then
        return "green"
    end
    
    for _, n in ipairs(Games.Roulette.RED_NUMBERS) do
        if n == number then
            return "red"
        end
    end
    
    return "black"
end

-- Проверка выигрыша
function Games.Roulette.checkBet(number, betType, betValue)
    if betType == Games.Roulette.BET_TYPES.NUMBER then
        return number == tonumber(betValue)
    elseif betType == Games.Roulette.BET_TYPES.RED then
        return Games.Roulette.getColor(number) == "red"
    elseif betType == Games.Roulette.BET_TYPES.BLACK then
        return Games.Roulette.getColor(number) == "black"
    elseif betType == Games.Roulette.BET_TYPES.EVEN then
        return number ~= 0 and number % 2 == 0
    elseif betType == Games.Roulette.BET_TYPES.ODD then
        return number ~= 0 and number % 2 == 1
    elseif betType == Games.Roulette.BET_TYPES.LOW then
        return number >= 1 and number <= 18
    elseif betType == Games.Roulette.BET_TYPES.HIGH then
        return number >= 19 and number <= 36
    elseif betType == Games.Roulette.BET_TYPES.DOZEN1 then
        return number >= 1 and number <= 12
    elseif betType == Games.Roulette.BET_TYPES.DOZEN2 then
        return number >= 13 and number <= 24
    elseif betType == Games.Roulette.BET_TYPES.DOZEN3 then
        return number >= 25 and number <= 36
    end
    
    return false
end

-- Получить множитель выплаты
function Games.Roulette.getPayout(betType)
    if betType == Games.Roulette.BET_TYPES.NUMBER then
        return 35
    elseif betType == Games.Roulette.BET_TYPES.DOZEN1 or 
           betType == Games.Roulette.BET_TYPES.DOZEN2 or 
           betType == Games.Roulette.BET_TYPES.DOZEN3 then
        return 3
    else
        return 2
    end
end

-- Основная функция игры в рулетку
function Games.Roulette.play(bet, betType, betValue)
    if bet < 1 or bet > 100 then
        return {success = false, error = "Ставка должна быть от 1 до 100"}
    end
    
    -- Вращаем колесо
    local number = math.random(0, 36)
    local color = Games.Roulette.getColor(number)
    
    -- Проверяем выигрыш
    local won = Games.Roulette.checkBet(number, betType, betValue)
    local multiplier = won and Games.Roulette.getPayout(betType) or 0
    local winAmount = won and (bet * multiplier) or 0
    
    return {
        success = true,
        number = number,
        color = color,
        won = won,
        multiplier = multiplier,
        winAmount = winAmount,
        profit = winAmount - bet
    }
end

-- ============================================================================
-- БЛЭКДЖЕК (Blackjack)
-- ============================================================================

Games.Blackjack = {}

-- Масти и ранги карт
Games.Blackjack.SUITS = {"♠", "♥", "♦", "♣"}
Games.Blackjack.RANKS = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"}

-- Создание колоды
function Games.Blackjack.createDeck()
    local deck = {}
    for _, suit in ipairs(Games.Blackjack.SUITS) do
        for _, rank in ipairs(Games.Blackjack.RANKS) do
            table.insert(deck, {rank = rank, suit = suit})
        end
    end
    return deck
end

-- Перемешивание колоды
function Games.Blackjack.shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

-- Взять карту из колоды
function Games.Blackjack.drawCard(deck)
    if #deck == 0 then
        return nil
    end
    return table.remove(deck, 1)
end

-- Получить значение карты
function Games.Blackjack.getCardValue(card)
    if card.rank == "A" then
        return 11  -- Туз может быть 1 или 11
    elseif card.rank == "J" or card.rank == "Q" or card.rank == "K" then
        return 10
    else
        return tonumber(card.rank)
    end
end

-- Рассчитать сумму руки
function Games.Blackjack.calculateHandValue(hand)
    local value = 0
    local aces = 0
    
    for _, card in ipairs(hand) do
        local cardValue = Games.Blackjack.getCardValue(card)
        value = value + cardValue
        if card.rank == "A" then
            aces = aces + 1
        end
    end
    
    -- Корректируем значение тузов если перебор
    while value > 21 and aces > 0 do
        value = value - 10
        aces = aces - 1
    end
    
    return value
end

-- Проверка на блэкджек
function Games.Blackjack.isBlackjack(hand)
    return #hand == 2 and Games.Blackjack.calculateHandValue(hand) == 21
end

-- Определить победителя
function Games.Blackjack.determineWinner(playerHand, dealerHand)
    local playerValue = Games.Blackjack.calculateHandValue(playerHand)
    local dealerValue = Games.Blackjack.calculateHandValue(dealerHand)
    
    local playerBlackjack = Games.Blackjack.isBlackjack(playerHand)
    local dealerBlackjack = Games.Blackjack.isBlackjack(dealerHand)
    
    -- Перебор у игрока
    if playerValue > 21 then
        return "dealer_win", 0
    end
    
    -- Перебор у дилера
    if dealerValue > 21 then
        return "player_win", 1
    end
    
    -- Блэкджек у игрока
    if playerBlackjack and not dealerBlackjack then
        return "blackjack", 1.5  -- Блэкджек платит 3:2
    end
    
    -- Блэкджек у дилера
    if dealerBlackjack and not playerBlackjack then
        return "dealer_win", 0
    end
    
    -- Оба блэкджека
    if playerBlackjack and dealerBlackjack then
        return "push", 0
    end
    
    -- Сравнение значений
    if playerValue > dealerValue then
        return "player_win", 1
    elseif playerValue < dealerValue then
        return "dealer_win", 0
    else
        return "push", 0  -- Ничья
    end
end

-- Рассчитать выплату
function Games.Blackjack.calculatePayout(bet, result, multiplier)
    if result == "push" then
        return bet  -- Возврат ставки
    elseif result == "player_win" or result == "blackjack" then
        return bet + (bet * multiplier)
    else
        return 0
    end
end

-- Начать игру в блэкджек
function Games.Blackjack.start(bet)
    if bet < 1 or bet > 100 then
        return {success = false, error = "Ставка должна быть от 1 до 100"}
    end
    
    -- Создаем и перемешиваем колоду
    local deck = Games.Blackjack.createDeck()
    Games.Blackjack.shuffleDeck(deck)
    
    -- Раздаем карты
    local playerHand = {
        Games.Blackjack.drawCard(deck),
        Games.Blackjack.drawCard(deck)
    }
    
    local dealerHand = {
        Games.Blackjack.drawCard(deck),
        Games.Blackjack.drawCard(deck)
    }
    
    local playerValue = Games.Blackjack.calculateHandValue(playerHand)
    local dealerVisible = Games.Blackjack.getCardValue(dealerHand[1])
    
    -- Проверяем на немедленный блэкджек
    if Games.Blackjack.isBlackjack(playerHand) then
        if Games.Blackjack.isBlackjack(dealerHand) then
            -- Оба блэкджека - ничья
            return {
                success = true,
                stage = "finished",
                playerHand = playerHand,
                dealerHand = dealerHand,
                result = "push",
                winAmount = bet,
                profit = 0
            }
        else
            -- Блэкджек игрока
            return {
                success = true,
                stage = "finished",
                playerHand = playerHand,
                dealerHand = dealerHand,
                result = "blackjack",
                winAmount = bet + (bet * 1.5),
                profit = bet * 1.5
            }
        end
    end
    
    return {
        success = true,
        stage = "player_turn",
        playerHand = playerHand,
        dealerVisible = dealerHand[1],
        playerValue = playerValue,
        deck = deck,
        dealerHand = dealerHand
    }
end

-- Действие игрока (hit/stand)
function Games.Blackjack.action(gameState, action, bet)
    if action == "hit" then
        -- Взять карту
        table.insert(gameState.playerHand, Games.Blackjack.drawCard(gameState.deck))
        local playerValue = Games.Blackjack.calculateHandValue(gameState.playerHand)
        
        if playerValue > 21 then
            -- Перебор
            return {
                success = true,
                stage = "finished",
                playerHand = gameState.playerHand,
                dealerHand = gameState.dealerHand,
                result = "dealer_win",
                winAmount = 0,
                profit = -bet
            }
        end
        
        gameState.playerValue = playerValue
        return {
            success = true,
            stage = "player_turn",
            playerHand = gameState.playerHand,
            playerValue = playerValue,
            dealerVisible = gameState.dealerVisible
        }
        
    elseif action == "stand" then
        -- Ход дилера
        while Games.Blackjack.calculateHandValue(gameState.dealerHand) < 17 do
            table.insert(gameState.dealerHand, Games.Blackjack.drawCard(gameState.deck))
        end
        
        -- Определяем победителя
        local result, multiplier = Games.Blackjack.determineWinner(gameState.playerHand, gameState.dealerHand)
        local winAmount = Games.Blackjack.calculatePayout(bet, result, multiplier)
        
        return {
            success = true,
            stage = "finished",
            playerHand = gameState.playerHand,
            dealerHand = gameState.dealerHand,
            result = result,
            winAmount = winAmount,
            profit = winAmount - bet
        }
        
    elseif action == "double" then
        -- Удвоить ставку (только если 2 карты)
        if #gameState.playerHand ~= 2 then
            return {success = false, error = "Удвоить можно только с двумя картами"}
        end
        
        -- Берем одну карту и автоматически останавливаемся
        table.insert(gameState.playerHand, Games.Blackjack.drawCard(gameState.deck))
        local playerValue = Games.Blackjack.calculateHandValue(gameState.playerHand)
        
        if playerValue > 21 then
            return {
                success = true,
                stage = "finished",
                playerHand = gameState.playerHand,
                dealerHand = gameState.dealerHand,
                result = "dealer_win",
                winAmount = 0,
                profit = -(bet * 2),
                doubled = true
            }
        end
        
        -- Ход дилера
        while Games.Blackjack.calculateHandValue(gameState.dealerHand) < 17 do
            table.insert(gameState.dealerHand, Games.Blackjack.drawCard(gameState.deck))
        end
        
        local result, multiplier = Games.Blackjack.determineWinner(gameState.playerHand, gameState.dealerHand)
        local winAmount = Games.Blackjack.calculatePayout(bet * 2, result, multiplier)
        
        return {
            success = true,
            stage = "finished",
            playerHand = gameState.playerHand,
            dealerHand = gameState.dealerHand,
            result = result,
            winAmount = winAmount,
            profit = winAmount - (bet * 2),
            doubled = true
        }
    end
    
    return {success = false, error = "Неизвестное действие"}
end

return Games

