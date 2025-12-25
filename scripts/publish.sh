#!/bin/bash

# Скрипт для публикации @suro4ek/appmetrica-push-sdk в npm
# Использование: ./scripts/publish.sh [patch|minor|major]

set -e  # Остановить выполнение при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка аргументов
VERSION_TYPE=${1:-patch}

if [[ ! "$VERSION_TYPE" =~ ^(patch|minor|major)$ ]]; then
    error "Неверный тип версии. Используйте: patch, minor или major"
    echo "Использование: $0 [patch|minor|major]"
    exit 1
fi

log "🚀 Начинаем публикацию @suro4ek/appmetrica-push-sdk"
log "Тип обновления версии: $VERSION_TYPE"

# Проверка, что мы в правильной директории
if [[ ! -f "package.json" ]]; then
    error "package.json не найден. Запустите скрипт из корневой директории проекта."
    exit 1
fi

# Проверка, что git репозиторий чистый
if [[ -n $(git status --porcelain) ]]; then
    warning "Git репозиторий содержит несохраненные изменения."
    read -p "Продолжить? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Публикация отменена."
        exit 1
    fi
fi

# Проверка авторизации в npm
log "🔐 Проверка авторизации в npm..."
if ! npm whoami > /dev/null 2>&1; then
    error "Вы не авторизованы в npm. Выполните: npm login"
    exit 1
fi

NPM_USER=$(npm whoami)
success "Авторизован как: $NPM_USER"

# Установка зависимостей
log "📦 Установка зависимостей..."
yarn install

# Проверка линтера
log "🔍 Проверка кода линтером..."
if ! npm run lint; then
    warning "Линтер обнаружил предупреждения или ошибки."
    read -p "Продолжить публикацию? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Публикация отменена. Исправьте ошибки линтера."
        exit 1
    fi
    warning "Продолжаем публикацию несмотря на предупреждения линтера..."
else
    success "Код прошел проверку линтера"
fi

# Запуск тестов (если есть)
if npm run test > /dev/null 2>&1; then
    log "🧪 Запуск тестов..."
    npm run test
    success "Все тесты прошли успешно"
else
    warning "Тесты не найдены или не настроены"
fi

# Проверка содержимого пакета
log "📋 Проверка содержимого пакета..."
npm pack --dry-run

# Обновление версии
log "📈 Обновление версии ($VERSION_TYPE)..."
OLD_VERSION=$(node -p "require('./package.json').version")
npm version $VERSION_TYPE --no-git-tag-version
NEW_VERSION=$(node -p "require('./package.json').version")
success "Версия обновлена: $OLD_VERSION → $NEW_VERSION"

# Создание архива для финальной проверки
log "📦 Создание архива пакета..."
PACKAGE_FILE=$(npm pack)
success "Архив создан: $PACKAGE_FILE"

# Показ содержимого архива
log "📋 Содержимое архива:"
tar -tzf "$PACKAGE_FILE" | head -20
if [[ $(tar -tzf "$PACKAGE_FILE" | wc -l) -gt 20 ]]; then
    echo "... и еще $(( $(tar -tzf "$PACKAGE_FILE" | wc -l) - 20 )) файлов"
fi

# Подтверждение публикации
echo
warning "Готов к публикации:"
echo "  Пакет: @suro4ek/appmetrica-push-sdk"
echo "  Версия: $NEW_VERSION"
echo "  Пользователь: $NPM_USER"
echo
read -p "Опубликовать пакет? (y/N): " -r

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Публикация отменена."
    # Откат версии
    npm version $OLD_VERSION --no-git-tag-version
    rm -f "$PACKAGE_FILE"
    exit 0
fi

# Публикация
log "🚀 Публикация пакета в npm..."
if npm publish --access public; then
    success "✅ Пакет успешно опубликован!"
    success "📦 @suro4ek/appmetrica-push-sdk@$NEW_VERSION"
    
    # Очистка временного файла
    rm -f "$PACKAGE_FILE"
    
    # Создание git тега и коммита
    log "🏷️  Создание git тега..."
    git add package.json
    git commit -m "chore: bump version to $NEW_VERSION"
    git tag "v$NEW_VERSION"
    success "Git тег v$NEW_VERSION создан"
    
    # Отправка в GitHub
    log "📤 Отправка изменений в GitHub..."
    git push origin main
    git push origin "v$NEW_VERSION"
    success "Изменения отправлены в GitHub"
    
    # Информация для пользователей
    echo
    success "🎉 Публикация завершена!"
    echo
    log "Пользователи могут установить пакет:"
    echo "  npm install @suro4ek/appmetrica-push-sdk@$NEW_VERSION"
    echo "  yarn add @suro4ek/appmetrica-push-sdk@$NEW_VERSION"
    echo
    log "Проверить пакет:"
    echo "  npm view @suro4ek/appmetrica-push-sdk"
    echo
    log "GitHub Release:"
    echo "  https://github.com/suro4ek/appmetrica-push-sdk/releases/tag/v$NEW_VERSION"
    
else
    error "❌ Ошибка при публикации пакета"
    # Откат версии
    npm version $OLD_VERSION --no-git-tag-version
    rm -f "$PACKAGE_FILE"
    exit 1
fi
