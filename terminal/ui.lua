-- terminal/ui.lua
-- Библиотека пользовательского интерфейса для терминалов казино "Spartak"

local component = require("component")
local term = require("term")
local unicode = require("unicode")

local UI = {}

-- Получение GPU
local gpu = component.gpu

-- Цвета
UI.COLORS = {
    BLACK = 0x000000,
    WHITE = 0xFFFFFF,
    RED = 0xFF0000,
    DARK_RED = 0x8B0000,
    GREEN = 0x00FF00,
    DARK_GREEN = 0x006400,
    BLUE = 0x0000FF,
    YELLOW = 0xFFFF00,
    GOLD = 0xFFD700,
    ORANGE = 0xFFA500,
    GRAY = 0x808080,
    LIGHT_GRAY = 0xD3D3D3,
    PURPLE = 0x800080
}

-- Символы для рисования
UI.CHARS = {
    -- Рамки
    H_LINE = "═",
    V_LINE = "║",
    TL_CORNER = "╔",
    TR_CORNER = "╗",
    BL_CORNER = "╚",
    BR_CORNER = "╝",
    T_DOWN = "╦",
    T_UP = "╩",
    T_RIGHT = "╠",
    T_LEFT = "╣",
    CROSS = "╬",
    
    -- Простые рамки
    H_LINE_S = "─",
    V_LINE_S = "│",
    TL_CORNER_S = "┌",
    TR_CORNER_S = "┐",
    BL_CORNER_S = "└",
    BR_CORNER_S = "┘",
    
    -- Символы казино
    CHERRY = "🍒",
    LEMON = "🍋",
    ORANGE = "🍊",
    GRAPE = "🍇",
    DIAMOND = "💎",
    SEVEN = "7️⃣",
    STAR = "⭐",
    COIN = "💰",
    CARDS = "🃏",
    DICE = "🎲",
    SLOT = "🎰",
    ROULETTE = "🎡"
}

-- Очистка экрана
function UI.clear()
    term.clear()
    gpu.setBackground(UI.COLORS.BLACK)
    gpu.setForeground(UI.COLORS.WHITE)
end

-- Рисование рамки
function UI.drawBox(x, y, width, height, title, color)
    color = color or UI.COLORS.GOLD
    gpu.setForeground(color)
    
    -- Верхняя линия
    gpu.set(x, y, UI.CHARS.TL_CORNER .. string.rep(UI.CHARS.H_LINE, width - 2) .. UI.CHARS.TR_CORNER)
    
    -- Боковые линии
    for i = 1, height - 2 do
        gpu.set(x, y + i, UI.CHARS.V_LINE)
        gpu.set(x + width - 1, y + i, UI.CHARS.V_LINE)
    end
    
    -- Нижняя линия
    gpu.set(x, y + height - 1, UI.CHARS.BL_CORNER .. string.rep(UI.CHARS.H_LINE, width - 2) .. UI.CHARS.BR_CORNER)
    
    -- Заголовок
    if title then
        local titleX = x + math.floor((width - unicode.len(title)) / 2)
        gpu.set(titleX, y, title)
    end
    
    gpu.setForeground(UI.COLORS.WHITE)
end

-- Рисование кнопки
function UI.drawButton(x, y, text, width, selected)
    width = width or (unicode.len(text) + 4)
    
    if selected then
        gpu.setBackground(UI.COLORS.GOLD)
        gpu.setForeground(UI.COLORS.BLACK)
    else
        gpu.setBackground(UI.COLORS.GRAY)
        gpu.setForeground(UI.COLORS.WHITE)
    end
    
    local padding = math.floor((width - unicode.len(text)) / 2)
    local buttonText = string.rep(" ", padding) .. text .. string.rep(" ", width - unicode.len(text) - padding)
    
    gpu.set(x, y, buttonText)
    
    gpu.setBackground(UI.COLORS.BLACK)
    gpu.setForeground(UI.COLORS.WHITE)
end

-- Рисование текста по центру
function UI.drawCentered(y, text, color)
    local w, _ = gpu.getResolution()
    local x = math.floor((w - unicode.len(text)) / 2)
    
    if color then
        gpu.setForeground(color)
    end
    
    gpu.set(x, y, text)
    
    if color then
        gpu.setForeground(UI.COLORS.WHITE)
    end
end

-- Рисование поля ввода
function UI.drawInput(x, y, width, value, focused)
    if focused then
        gpu.setBackground(UI.COLORS.DARK_GREEN)
    else
        gpu.setBackground(UI.COLORS.GRAY)
    end
    
    gpu.setForeground(UI.COLORS.WHITE)
    
    local displayValue = value or ""
    if unicode.len(displayValue) > width - 2 then
        displayValue = unicode.sub(displayValue, 1, width - 2)
    end
    
    local padding = width - unicode.len(displayValue) - 2
    local inputText = " " .. displayValue .. string.rep(" ", padding) .. " "
    
    gpu.set(x, y, inputText)
    
    gpu.setBackground(UI.COLORS.BLACK)
end

-- Рисование логотипа ASCII
function UI.drawLogo(y)
    local logo = {
        "   _____ _____        _____ _______       _  __",
        "  / ____|  __ \\ /\\   |  __ \\__   __|/\\   | |/ /",
        " | (___ | |__) /  \\  | |__) | | |  /  \\  | ' / ",
        "  \\___ \\|  ___/ /\\ \\ |  _  /  | | / /\\ \\ |  <  ",
        "  ____) | |  / ____ \\| | \\ \\  | |/ ____ \\| . \\ ",
        " |_____/|_| /_/    \\_\\_|  \\_\\ |_/_/    \\_\\_|\\_\\",
        "                                                ",
        "        К А З И Н О   С П А Р Т А К"
    }
    
    gpu.setForeground(UI.COLORS.GOLD)
    
    for i, line in ipairs(logo) do
        UI.drawCentered(y + i - 1, line, UI.COLORS.GOLD)
    end
    
    gpu.setForeground(UI.COLORS.WHITE)
end

-- Рисование заголовка с балансом
function UI.drawHeader(playerName, balance)
    local w, _ = gpu.getResolution()
    
    gpu.setForeground(UI.COLORS.GOLD)
    gpu.set(2, 1, "КАЗИНО SPARTAK")
    
    gpu.setForeground(UI.COLORS.WHITE)
    local info = "Игрок: " .. playerName .. "  Баланс: " .. balance .. "₽"
    gpu.set(w - unicode.len(info) - 1, 1, info)
    
    -- Линия разделитель
    gpu.setForeground(UI.COLORS.GRAY)
    gpu.set(1, 2, string.rep("═", w))
    gpu.setForeground(UI.COLORS.WHITE)
end

-- Рисование результата игры
function UI.drawResult(result, bet)
    local w, h = gpu.getResolution()
    local boxWidth = 60
    local boxHeight = 15
    local x = math.floor((w - boxWidth) / 2)
    local y = math.floor((h - boxHeight) / 2)
    
    -- Рамка
    UI.drawBox(x, y, boxWidth, boxHeight, nil, UI.COLORS.GOLD)
    
    -- Заголовок
    if result.profit > 0 then
        UI.drawCentered(y + 2, "✨ ПОЗДРАВЛЯЕМ! ✨", UI.COLORS.YELLOW)
        UI.drawCentered(y + 4, "ВЫ ВЫИГРАЛИ: " .. result.winAmount .. "₽", UI.COLORS.GREEN)
    elseif result.profit == 0 then
        UI.drawCentered(y + 2, "НИЧЬЯ", UI.COLORS.YELLOW)
        UI.drawCentered(y + 4, "Ставка возвращена: " .. bet .. "₽", UI.COLORS.WHITE)
    else
        UI.drawCentered(y + 2, "ПРОИГРЫШ", UI.COLORS.RED)
        UI.drawCentered(y + 4, "Вы проиграли: " .. bet .. "₽", UI.COLORS.RED)
    end
    
    -- Детали
    if result.multiplier and result.multiplier > 0 then
        UI.drawCentered(y + 6, "Множитель: x" .. result.multiplier, UI.COLORS.WHITE)
    end
    
    UI.drawCentered(y + 8, "Ваш баланс: " .. result.balance .. "₽", UI.COLORS.WHITE)
    
    -- Кнопки
    UI.drawButton(x + 5, y + 11, "ИГРАТЬ ЕЩЕ", 20, false)
    UI.drawButton(x + 30, y + 11, "В ГЛАВНОЕ МЕНЮ", 20, false)
end

-- Рисование слотов
function UI.drawSlots(reels, spinning)
    local w, h = gpu.getResolution()
    local boxWidth = 50
    local boxHeight = 10
    local x = math.floor((w - boxWidth) / 2)
    local y = math.floor((h - boxHeight) / 2) - 5
    
    -- Рамка
    UI.drawBox(x, y, boxWidth, boxHeight, " 🎰 СЛОТЫ ", UI.COLORS.GOLD)
    
    -- Барабаны
    local reelX = x + 10
    local reelY = y + 4
    
    gpu.setForeground(UI.COLORS.WHITE)
    gpu.setBackground(UI.COLORS.DARK_RED)
    
    for i, symbol in ipairs(reels) do
        local symbolX = reelX + (i - 1) * 12
        gpu.set(symbolX, reelY, "        ")
        gpu.set(symbolX, reelY + 1, "   " .. symbol .. "   ")
        gpu.set(symbolX, reelY + 2, "        ")
    end
    
    gpu.setBackground(UI.COLORS.BLACK)
    
    if spinning then
        UI.drawCentered(y + 8, "Вращение...", UI.COLORS.YELLOW)
    end
end

-- Рисование рулетки
function UI.drawRoulette(number, color, spinning)
    local w, h = gpu.getResolution()
    local boxWidth = 60
    local boxHeight = 12
    local x = math.floor((w - boxWidth) / 2)
    local y = math.floor((h - boxHeight) / 2) - 5
    
    -- Рамка
    UI.drawBox(x, y, boxWidth, boxHeight, " 🎡 РУЛЕТКА ", UI.COLORS.GOLD)
    
    if spinning then
        UI.drawCentered(y + 5, "Вращение колеса...", UI.COLORS.YELLOW)
    elseif number then
        -- Результат
        local colorText = ""
        local colorCode = UI.COLORS.WHITE
        
        if color == "red" then
            colorText = "🔴"
            colorCode = UI.COLORS.RED
        elseif color == "black" then
            colorText = "⚫"
            colorCode = UI.COLORS.WHITE
        else
            colorText = "🟢"
            colorCode = UI.COLORS.GREEN
        end
        
        UI.drawCentered(y + 5, "Выпало число: " .. number .. " " .. colorText, colorCode)
    else
        UI.drawCentered(y + 5, "Сделайте ставку", UI.COLORS.WHITE)
    end
end

-- Рисование карт блэкджека
function UI.drawCard(x, y, card, hidden)
    local cardWidth = 8
    local cardHeight = 5
    
    gpu.setBackground(UI.COLORS.WHITE)
    
    if hidden then
        gpu.setForeground(UI.COLORS.BLUE)
        gpu.fill(x, y, cardWidth, cardHeight, " ")
        gpu.set(x + 3, y + 2, "??")
    else
        gpu.setForeground(UI.COLORS.BLACK)
        if card.suit == "♥" or card.suit == "♦" then
            gpu.setForeground(UI.COLORS.RED)
        end
        
        gpu.fill(x, y, cardWidth, cardHeight, " ")
        gpu.set(x + 1, y + 1, card.rank .. card.suit)
        gpu.set(x + cardWidth - 3, y + cardHeight - 2, card.rank .. card.suit)
    end
    
    gpu.setBackground(UI.COLORS.BLACK)
    gpu.setForeground(UI.COLORS.WHITE)
end

-- Рисование руки блэкджека
function UI.drawBlackjackHand(x, y, hand, label, value, hideSecond)
    gpu.setForeground(UI.COLORS.YELLOW)
    gpu.set(x, y, label .. ":")
    
    gpu.setForeground(UI.COLORS.WHITE)
    gpu.set(x + 40, y, "Сумма: " .. value)
    
    for i, card in ipairs(hand) do
        local cardX = x + (i - 1) * 10
        local hidden = hideSecond and i == 2
        UI.drawCard(cardX, y + 1, card, hidden)
    end
end

-- Рисование таблицы выплат слотов
function UI.drawPayoutTable(x, y)
    local payouts = {
        {"⭐⭐⭐", "x100"},
        {"7️⃣7️⃣7️⃣", "x50"},
        {"💎💎💎", "x25"},
        {"🍇🍇🍇", "x10"},
        {"🍊🍊🍊", "x5"},
        {"🍋🍋🍋", "x3"},
        {"🍒🍒🍒", "x2"},
        {"Любые 2", "x1"}
    }
    
    UI.drawBox(x, y, 30, #payouts + 3, " ТАБЛИЦА ВЫПЛАТ ", UI.COLORS.GOLD)
    
    for i, payout in ipairs(payouts) do
        gpu.setForeground(UI.COLORS.WHITE)
        gpu.set(x + 2, y + i + 1, payout[1])
        gpu.setForeground(UI.COLORS.YELLOW)
        gpu.set(x + 20, y + i + 1, payout[2])
    end
    
    gpu.setForeground(UI.COLORS.WHITE)
end

-- Анимация загрузки
function UI.showLoading(message)
    local w, h = gpu.getResolution()
    local y = math.floor(h / 2)
    
    UI.drawCentered(y, message or "Загрузка...", UI.COLORS.YELLOW)
    
    local dots = {".", "..", "..."}
    for i = 1, 3 do
        os.sleep(0.3)
        UI.drawCentered(y + 1, dots[i], UI.COLORS.WHITE)
    end
end

-- Показать сообщение об ошибке
function UI.showError(message)
    local w, h = gpu.getResolution()
    local boxWidth = math.min(60, unicode.len(message) + 10)
    local boxHeight = 7
    local x = math.floor((w - boxWidth) / 2)
    local y = math.floor((h - boxHeight) / 2)
    
    UI.drawBox(x, y, boxWidth, boxHeight, " ОШИБКА ", UI.COLORS.RED)
    
    UI.drawCentered(y + 3, message, UI.COLORS.RED)
    UI.drawCentered(y + 5, "[Нажмите любую клавишу]", UI.COLORS.GRAY)
end

-- Показать сообщение
function UI.showMessage(title, message, color)
    local w, h = gpu.getResolution()
    local boxWidth = math.min(60, unicode.len(message) + 10)
    local boxHeight = 7
    local x = math.floor((w - boxWidth) / 2)
    local y = math.floor((h - boxHeight) / 2)
    
    UI.drawBox(x, y, boxWidth, boxHeight, " " .. title .. " ", color or UI.COLORS.GOLD)
    
    UI.drawCentered(y + 3, message, UI.COLORS.WHITE)
    UI.drawCentered(y + 5, "[Нажмите любую клавишу]", UI.COLORS.GRAY)
end

return UI

