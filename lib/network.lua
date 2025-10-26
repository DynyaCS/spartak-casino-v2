-- network.lua
-- Библиотека для сетевого взаимодействия в казино "Spartak"

local component = require("component")
local event = require("event")
local serialization = require("serialization")

local Network = {}
Network.__index = Network

-- Порт для связи
Network.PORT = 5555

-- Типы сообщений
Network.MSG_TYPES = {
    LOGIN = "login",
    DEPOSIT = "deposit",
    WITHDRAW = "withdraw",
    BALANCE = "balance",
    PLAY = "play",
    PLAYER_INFO = "player_info",
    CASINO_STATS = "casino_stats",
    PING = "ping",
    ERROR = "error"
}

-- Создание нового сетевого менеджера
function Network.new(isServer)
    local self = setmetatable({}, Network)
    self.isServer = isServer or false
    self.modem = component.modem
    
    if not self.modem then
        error("Сетевая карта не найдена!")
    end
    
    -- Открываем порт
    self.modem.open(Network.PORT)
    print("[NET] Порт " .. Network.PORT .. " открыт")
    
    -- Обработчики сообщений
    self.handlers = {}
    
    return self
end

-- Регистрация обработчика сообщений
function Network:registerHandler(msgType, handler)
    self.handlers[msgType] = handler
    print("[NET] Зарегистрирован обработчик для: " .. msgType)
end

-- Отправка сообщения
function Network:send(address, msgType, data)
    local message = {
        type = msgType,
        data = data,
        timestamp = os.time()
    }
    
    local serialized = serialization.serialize(message)
    self.modem.send(address, Network.PORT, serialized)
end

-- Широковещательная отправка
function Network:broadcast(msgType, data)
    local message = {
        type = msgType,
        data = data,
        timestamp = os.time()
    }
    
    local serialized = serialization.serialize(message)
    self.modem.broadcast(Network.PORT, serialized)
end

-- Обработка входящего сообщения
function Network:handleMessage(_, _, senderAddress, port, _, serializedMessage)
    if port ~= Network.PORT then
        return
    end
    
    local success, message = pcall(serialization.unserialize, serializedMessage)
    if not success or not message then
        print("[NET] Ошибка десериализации сообщения")
        return
    end
    
    local msgType = message.type
    local data = message.data
    
    -- Вызываем соответствующий обработчик
    if self.handlers[msgType] then
        local response = self.handlers[msgType](data, senderAddress)
        
        -- Отправляем ответ если есть
        if response then
            self:send(senderAddress, msgType .. "_response", response)
        end
    else
        print("[NET] Неизвестный тип сообщения: " .. msgType)
        self:send(senderAddress, Network.MSG_TYPES.ERROR, {
            error = "Неизвестный тип сообщения"
        })
    end
end

-- Запуск прослушивания сообщений
function Network:listen()
    event.listen("modem_message", function(...)
        self:handleMessage(...)
    end)
    print("[NET] Прослушивание запущено")
end

-- Остановка прослушивания
function Network:stop()
    event.ignore("modem_message", function(...) self:handleMessage(...) end)
    self.modem.close(Network.PORT)
    print("[NET] Прослушивание остановлено")
end

-- Ожидание ответа от сервера
function Network:waitForResponse(msgType, timeout)
    timeout = timeout or 5
    local responseType = msgType .. "_response"
    
    local timer = event.timer(timeout, function()
        return nil, "Timeout"
    end)
    
    local _, _, senderAddress, port, _, serializedMessage = event.pull(timeout, "modem_message")
    
    event.cancel(timer)
    
    if not serializedMessage then
        return nil, "Нет ответа от сервера"
    end
    
    local success, message = pcall(serialization.unserialize, serializedMessage)
    if not success or not message then
        return nil, "Ошибка десериализации ответа"
    end
    
    if message.type == responseType then
        return message.data
    elseif message.type == Network.MSG_TYPES.ERROR then
        return nil, message.data.error
    end
    
    return nil, "Неожиданный тип ответа"
end

-- Отправка запроса и ожидание ответа
function Network:request(serverAddress, msgType, data, timeout)
    self:send(serverAddress, msgType, data)
    return self:waitForResponse(msgType, timeout)
end

-- Поиск сервера в сети
function Network:findServer(timeout)
    timeout = timeout or 3
    
    print("[NET] Поиск сервера...")
    self:broadcast(Network.MSG_TYPES.PING, {client = true})
    
    local timer = event.timer(timeout, function() end)
    local _, _, senderAddress, port, _, serializedMessage = event.pull(timeout, "modem_message")
    
    event.cancel(timer)
    
    if not serializedMessage then
        return nil, "Сервер не найден"
    end
    
    local success, message = pcall(serialization.unserialize, serializedMessage)
    if success and message and message.type == Network.MSG_TYPES.PING .. "_response" then
        print("[NET] Сервер найден: " .. senderAddress)
        return senderAddress
    end
    
    return nil, "Сервер не найден"
end

return Network

