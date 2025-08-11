#!/bin/bash

# --- НАСТРОЙКИ ---
# Внутреннее имя для вашего виртуального устройства.
SINK_NAME="Virtual-Mic"
# Отображаемое имя по умолчанию.
DEFAULT_DESCRIPTION="Виртуальный микрофон"

# --- ФУНКЦИИ ---

## 1. Функция создания виртуального кабеля
function setup_virtual_mic() {
    if pactl list short modules | grep -q "sink_name=$SINK_NAME"; then
        echo "⚠️  Виртуальный кабель '$SINK_NAME' уже существует."
        return
    fi

    echo "🎙️  Создание виртуального аудиокабеля..."
    pactl load-module module-null-sink \
        sink_name="$SINK_NAME" \
        sink_properties=device.description="$DEFAULT_DESCRIPTION"
    echo "✅ Виртуальный кабель '$DEFAULT_DESCRIPTION' успешно создан."
}

## 2. Функция удаления кабеля по имени (SINK_NAME)
function remove_virtual_mic() {
    echo "🗑️  Поиск виртуального кабеля с внутренним именем '$SINK_NAME'..."
    MODULE_INDEX=$(pactl list short modules | grep "sink_name=$SINK_NAME" | awk '{print $1}')

    if [[ -z "$MODULE_INDEX" ]]; then
        echo "❌ Не найден активный модуль для '$SINK_NAME'."
    else
        echo "   -> Найден модуль с ID: $MODULE_INDEX. Удаляю..."
        pactl unload-module "$MODULE_INDEX"
        echo "✅ Виртуальный кабель '$SINK_NAME' успешно удален."
    fi
}

## 3. НОВАЯ ФУНКЦИЯ: Удаление ВСЕХ виртуальных кабелей
function remove_all_virtual_mics() {
    echo "💣 Поиск и удаление ВСЕХ виртуальных кабелей (созданных module-null-sink)..."

    # Находим ВСЕ индексы модулей типа module-null-sink, а не по конкретному имени
    MODULE_INDICES=$(pactl list short modules | grep "module-null-sink" | awk '{print $1}')

    if [[ -z "$MODULE_INDICES" ]]; then
        echo "✅ Виртуальные кабели не найдены. Удалять нечего."
        return
    fi

    echo "   -> Найдены следующие ID модулей для удаления:"
    # Выводим ID в столбик для наглядности
    echo "$MODULE_INDICES" | while read -r id; do echo "      - $id"; done

    # Перебираем и удаляем каждый найденный модуль
    for INDEX in $MODULE_INDICES; do
        echo "   -> Удаляю модуль с ID: $INDEX..."
        pactl unload-module "$INDEX"
    done

    echo "✅ Все найденные виртуальные кабели были успешно удалены."
}


## 4. Функция переименования
function rename_virtual_mic() {
    echo "✏️  Переименование виртуального кабеля..."
    if ! pactl list short sinks | grep -q "$SINK_NAME"; then
        echo "❌ Невозможно переименовать. Сначала создайте кабель (пункт 1)."
        return
    fi
    read -p "   Введите новое отображаемое имя для устройства: " NEW_NAME
    if [[ -z "$NEW_NAME" ]]; then
        echo "❌ Имя не может быть пустым. Операция отменена."
        return
    fi
    pactl update-sink-proplist "$SINK_NAME" device.description="$NEW_NAME"
    pactl update-source-proplist "$SINK_NAME.monitor" device.description="$NEW_NAME"
    echo "✅ Устройство успешно переименовано в '$NEW_NAME'."
}

# --- ГЛАВНОЕ МЕНЮ ---
function main_menu() {
    while true; do
        echo
        echo "--- Управление виртуальным микрофоном ---"
        echo "1. Создать кабель (с именем '$SINK_NAME')"
        echo "2. Удалить кабель (с именем '$SINK_NAME')"
        echo "3. 💣 Удалить ВООБЩЕ ВСЕ виртуальные кабели"
        echo "4. Переименовать кабель (с именем '$SINK_NAME')"
        echo "5. Выйти"
        echo "----------------------------------------"
        read -p "Выберите действие [1-5]: " choice

        case $choice in
            1) setup_virtual_mic ;;
            2) remove_virtual_mic ;;
            3) remove_all_virtual_mics ;;
            4) rename_virtual_mic ;;
            5) echo "👋 Выход."; break ;;
            *) echo "❗️ Неверный выбор. Пожалуйста, введите число от 1 до 5." ;;
        esac
    done
}

main_menu
