# 🎰 Казино "Spartak" v2.0

Казино для OpenComputers на Minecraft 1.7.10 (сервер McSkill)

## 🚀 Установка (одна команда!)

```lua
pastebin run ВАШТУТ_КОД
```

Или через wget:

```bash
wget -f https://raw.githubusercontent.com/DynyaCS/spartak-casino-v2/master/installer.lua && lua installer.lua
```

## 🎮 Игры

- 🎰 **Слоты** - выплаты до x100
- 🎡 **Рулетка** - европейская 0-36  
- 🃏 **Блэкджек** - против дилера

**Ставки:** от 1 до 100 денег

## 💰 Депозит/Вывод

Через **PIM** (Personal Inventory Manager):
- Игрок встает на PIM
- Монеты CustomNPCs изымаются автоматически
- Баланс пополняется

## 📋 Требования

- OpenComputers 1.7.5+
- OpenPeripheralAddons (для PIM)
- CustomNPCs (для валюты)
- Internet Card
- Wireless Network Card

## 🎯 Запуск

**Сервер:**
```bash
cd /home/casino/server
lua main.lua
```

**Терминал игр:**
```bash
cd /home/casino/terminal
lua main.lua
```

**Терминал депозита:**
```bash
cd /home/casino/terminal
lua deposit.lua
```

## 📊 Структура

```
/home/casino/
├── server/
│   └── main.lua
├── terminal/
│   ├── main.lua
│   ├── deposit.lua
│   └── ui.lua
├── lib/
│   ├── database.lua
│   ├── games.lua
│   ├── network.lua
│   └── pim.lua
├── data/
├── logs/
└── config.lua
```

## 📝 Лицензия

MIT License

## 👨‍💻 Автор

DynyaCS - https://github.com/DynyaCS

