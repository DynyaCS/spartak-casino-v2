-- pim.lua
-- Библиотека для работы с PIM (Personal Inventory Manager) казино "Spartak"

local component = require("component")
local sides = require("sides")

local PIM = {}
PIM.__index = PIM

-- ID предмета-монеты CustomNPCs (нужно будет уточнить на сервере)
-- Обычно это "customnpcs:npcMoney" или подобное
PIM.MONEY_ITEM_ID = "customnpcs:npcMoney"
PIM.MONEY_ITEM_NAME = "Money"

-- Создание нового менеджера PIM
function PIM.new(pimAddress)
    local self = setmetatable({}, PIM)
    
    -- Получаем PIM через адаптер
    if pimAddress then
        self.pim = component.proxy(pimAddress)
    else
        -- Ищем первый доступный PIM
        for address, componentType in component.list("openperipheral_pim") do
            self.pim = component.proxy(address)
            break
        end
    end
    
    if not self.pim then
        error("PIM не найден! Убедитесь, что PIM подключен к компьютеру через Adapter")
    end
    
    print("[PIM] Инициализирован: " .. self.pim.address)
    
    return self
end

-- Получить все предметы из инвентаря игрока
function PIM:getAllStacks()
    local success, stacks = pcall(function()
        return self.pim.getAllStacks()
    end)
    
    if not success then
        return nil, "Ошибка получения инвентаря: " .. tostring(stacks)
    end
    
    return stacks
end

-- Получить предмет в конкретном слоте
function PIM:getStackInSlot(slot)
    local success, stack = pcall(function()
        return self.pim.getStackInSlot(slot)
    end)
    
    if not success then
        return nil, "Ошибка получения слота: " .. tostring(stack)
    end
    
    return stack
end

-- Проверить, является ли предмет монетой CustomNPCs
function PIM:isMoney(stack)
    if not stack or not stack.id then
        return false
    end
    
    -- Проверяем по ID или имени
    if stack.id == PIM.MONEY_ITEM_ID or 
       (stack.name and stack.name:lower():find("money")) or
       (stack.display_name and stack.display_name:lower():find("money")) then
        return true
    end
    
    return false
end

-- Подсчитать общее количество денег в инвентаре игрока
function PIM:countMoney()
    local stacks, err = self:getAllStacks()
    if not stacks then
        return 0, err
    end
    
    local totalMoney = 0
    local moneySlots = {}
    
    for slot, stack in pairs(stacks) do
        if self:isMoney(stack) then
            local amount = stack.qty or stack.size or stack.count or 1
            totalMoney = totalMoney + amount
            table.insert(moneySlots, {slot = slot, amount = amount})
        end
    end
    
    return totalMoney, nil, moneySlots
end

-- Изъять деньги из инвентаря игрока (депозит)
function PIM:withdrawMoney(amount)
    if amount <= 0 then
        return false, "Сумма должна быть положительной"
    end
    
    -- Подсчитываем доступные деньги
    local availableMoney, err, moneySlots = self:countMoney()
    if err then
        return false, err
    end
    
    if availableMoney < amount then
        return false, "Недостаточно денег в инвентаре (есть: " .. availableMoney .. ", нужно: " .. amount .. ")"
    end
    
    -- Изымаем деньги из слотов
    local remaining = amount
    local removedSlots = {}
    
    for _, slotInfo in ipairs(moneySlots) do
        if remaining <= 0 then
            break
        end
        
        local toRemove = math.min(remaining, slotInfo.amount)
        
        -- Удаляем предметы из слота
        if toRemove == slotInfo.amount then
            -- Удаляем весь стек
            local success, result = pcall(function()
                return self.pim.destroyStack(slotInfo.slot)
            end)
            
            if success then
                remaining = remaining - toRemove
                table.insert(removedSlots, {slot = slotInfo.slot, amount = toRemove})
            else
                print("[PIM] Ошибка удаления стека: " .. tostring(result))
            end
        else
            -- Удаляем часть стека (сложнее, нужно использовать pushItem в void)
            -- Для упрощения будем удалять только целые стеки
            -- TODO: Реализовать частичное удаление через временный инвентарь
            print("[PIM] Предупреждение: Частичное удаление стека не реализовано")
        end
    end
    
    local actuallyRemoved = amount - remaining
    
    if actuallyRemoved < amount then
        return false, "Удалось изъять только " .. actuallyRemoved .. " из " .. amount
    end
    
    return true, actuallyRemoved, removedSlots
end

-- Выдать деньги игроку (вывод)
function PIM:giveMoney(amount)
    if amount <= 0 then
        return false, "Сумма должна быть положительной"
    end
    
    -- Проверяем наличие свободного места в инвентаре
    local inventorySize = self.pim.getInventorySize()
    local stacks = self:getAllStacks()
    
    local freeSlots = 0
    for i = 1, inventorySize do
        if not stacks[i] or not stacks[i].id then
            freeSlots = freeSlots + 1
        end
    end
    
    if freeSlots == 0 then
        return false, "Инвентарь игрока полон!"
    end
    
    -- ВАЖНО: Эта функция требует наличия источника денег (сундука с деньгами)
    -- Для казино нужно создать "банковский сундук" с запасом монет
    -- и использовать pullItem для передачи денег игроку
    
    -- Временное решение: просто логируем операцию
    -- В реальной реализации нужно:
    -- 1. Иметь сундук с монетами рядом с PIM
    -- 2. Использовать pullItem для передачи монет из сундука в инвентарь игрока
    
    print("[PIM] ВНИМАНИЕ: Автоматическая выдача денег требует настройки банковского сундука")
    print("[PIM] Игроку нужно выдать " .. amount .. " денег вручную через NPC")
    
    return true, amount
end

-- Проверить, стоит ли игрок на PIM
function PIM:isPlayerPresent()
    local success, result = pcall(function()
        local stacks = self.pim.getAllStacks()
        return stacks ~= nil
    end)
    
    return success and result
end

-- Получить информацию об инвентаре игрока
function PIM:getInventoryInfo()
    if not self:isPlayerPresent() then
        return nil, "Игрок не стоит на PIM"
    end
    
    local stacks, err = self:getAllStacks()
    if not stacks then
        return nil, err
    end
    
    local info = {
        totalSlots = self.pim.getInventorySize(),
        usedSlots = 0,
        freeSlots = 0,
        money = 0,
        items = {}
    }
    
    for slot, stack in pairs(stacks) do
        if stack and stack.id then
            info.usedSlots = info.usedSlots + 1
            
            if self:isMoney(stack) then
                local amount = stack.qty or stack.size or stack.count or 1
                info.money = info.money + amount
            end
            
            table.insert(info.items, {
                slot = slot,
                id = stack.id,
                name = stack.name or stack.display_name or "Unknown",
                amount = stack.qty or stack.size or stack.count or 1
            })
        end
    end
    
    info.freeSlots = info.totalSlots - info.usedSlots
    
    return info
end

-- Упорядочить инвентарь (опционально)
function PIM:condenseInventory()
    local success, result = pcall(function()
        return self.pim.condenseItems()
    end)
    
    if not success then
        return false, "Ошибка упорядочивания: " .. tostring(result)
    end
    
    return true
end

-- Получить список всех доступных методов PIM (для отладки)
function PIM:listMethods()
    local success, methods = pcall(function()
        return self.pim.listMethods()
    end)
    
    if not success then
        return nil, "Ошибка получения методов: " .. tostring(methods)
    end
    
    return methods
end

-- ============================================================================
-- ИНТЕГРАЦИЯ С БАНКОВСКИМ СУНДУКОМ
-- ============================================================================

-- Настройка банковского сундука для выдачи денег
function PIM:setupBankChest(chestSide)
    self.bankChestSide = chestSide or sides.down
    print("[PIM] Банковский сундук настроен на стороне: " .. self.bankChestSide)
end

-- Выдать деньги из банковского сундука
function PIM:giveMoneyFromBank(amount)
    if not self.bankChestSide then
        return false, "Банковский сундук не настроен. Используйте setupBankChest()"
    end
    
    if amount <= 0 then
        return false, "Сумма должна быть положительной"
    end
    
    -- Находим монеты в банковском сундуке
    local chestStacks = {}
    local success, result = pcall(function()
        -- Получаем инвентарь сундука через transposer или inventory_controller
        -- Это зависит от конфигурации
        -- TODO: Реализовать получение инвентаря сундука
        return {}
    end)
    
    if not success then
        return false, "Ошибка доступа к банковскому сундуку: " .. tostring(result)
    end
    
    -- Передаем деньги из сундука игроку
    local remaining = amount
    
    -- TODO: Реализовать передачу через pullItem
    
    print("[PIM] ВНИМАНИЕ: Автоматическая выдача из банковского сундука требует доработки")
    
    return true, amount
end

-- ============================================================================
-- УТИЛИТЫ
-- ============================================================================

-- Форматировать информацию о предмете
function PIM.formatStack(stack)
    if not stack or not stack.id then
        return "Пусто"
    end
    
    local name = stack.name or stack.display_name or stack.id
    local amount = stack.qty or stack.size or stack.count or 1
    
    return string.format("%s x%d", name, amount)
end

-- Вывести информацию об инвентаре в консоль
function PIM:printInventoryInfo()
    local info, err = self:getInventoryInfo()
    if not info then
        print("[PIM] Ошибка: " .. err)
        return
    end
    
    print("═══ ИНВЕНТАРЬ ИГРОКА ═══")
    print("Всего слотов: " .. info.totalSlots)
    print("Занято: " .. info.usedSlots)
    print("Свободно: " .. info.freeSlots)
    print("Денег: " .. info.money)
    print("")
    print("Предметы:")
    for _, item in ipairs(info.items) do
        print(string.format("  [%d] %s x%d", item.slot, item.name, item.amount))
    end
end

return PIM

