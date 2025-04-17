#!/bin/bash

# Конфигурация
LOG_FILE="/var/log/gtnh_update.log"
MIN_SPACE_GB=10  # Минимальный свободный объем в GB
SERVER_PACKS_DIR="/data/nextcloud/Public/files/Minecraft/GTNH/ServerPacks"
SERVER_PACKS_URL="http://downloads.gtnewhorizons.com/ServerPacks/?aria2"
MULTI_MC_DIR="/data/nextcloud/Public/files/Minecraft/GTNH/Multi_mc_downloads"
MULTI_MC_URL="http://downloads.gtnewhorizons.com/Multi_mc_downloads/?aria2"

# Функция для логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Функция проверки свободного места
check_disk_space() {
    local dir=$1
    local required_space=$2  # в GB

    # Получаем свободное место в GB
    local free_space=$(df -BG "$dir" | awk 'NR==2 {print $4}' | tr -d 'G')

    if [ "$free_space" -lt "$required_space" ]; then
        log "ОШИБКА: Недостаточно места в $dir. Свободно: ${free_space}G, требуется: ${required_space}G"
        return 1
    fi

    log "Достаточно места в $dir. Свободно: ${free_space}G"
    return 0
}

# Функция для выполнения загрузки
download_files() {
    local dir=$1
    local url=$2

    log "Начало обработки директории: $dir"

    # Проверяем существование директории
    if [ ! -d "$dir" ]; then
        log "ОШИБКА: Директория $dir не существует"
        return 1
    fi

    # Переходим в директорию
    cd "$dir" || {
        log "ОШИБКА: Не удалось перейти в директорию $dir"
        return 1
    }

    log "Запуск загрузки из $url"

    # Выполняем загрузку с таймаутом 30 минут
    timeout 1800 bash -c "curl -sSf '$url' | aria2c -c -i -" >> "$LOG_FILE" 2>&1

    local status=$?

    if [ $status -eq 0 ]; then
        log "Успешно завершена загрузка в $dir"
    elif [ $status -eq 124 ]; then
        log "ОШИБКА: Таймаут при загрузке в $dir"
    else
        log "ОШИБКА: Загрузка в $dir завершилась с кодом $status"
    fi

    return $status
}

# Основной код
log "=== Начало выполнения скрипта ==="

# Проверяем доступность утилит
for cmd in curl aria2c df; do
    if ! command -v "$cmd" &> /dev/null; then
        log "ОШИБКА: Утилита $cmd не установлена"
        exit 1
    fi
done

# Проверяем свободное место и загружаем файлы
check_disk_space "$SERVER_PACKS_DIR" "$MIN_SPACE_GB" || exit 1
download_files "$SERVER_PACKS_DIR" "$SERVER_PACKS_URL"

check_disk_space "$MULTI_MC_DIR" "$MIN_SPACE_GB" || exit 1
download_files "$MULTI_MC_DIR" "$MULTI_MC_URL"

log "=== Завершение выполнения скрипта ==="
exit 0
