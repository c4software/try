#!/usr/bin/env bash
# Laravel project plugin for try.sh
# Usage: try make laravel [project-name]
#
# Creates a new Laravel project using Composer

echo "🚀 Creating Laravel project in: $PWD"

# Check if composer is installed
if ! command -v composer &> /dev/null; then
    echo "❌ Composer is not installed. Please install Composer first."
    echo "   Visit: https://getcomposer.org/download/"
    return 1
fi

echo "📦 Running: composer create-project --prefer-dist laravel/laravel ."
composer create-project --prefer-dist laravel/laravel .

# Check if the installation was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Laravel project created successfully!"
    echo ""
    echo "📁 Project structure:"
    echo "   - app/         (Application code)"
    echo "   - routes/      (Route definitions)"
    echo "   - resources/   (Views, assets)"
    echo "   - database/    (Migrations, seeders)"
    echo ""
    echo "💡 Next steps:"
    echo "   - Configure .env file"
    echo "   - php artisan serve (start development server)"
    echo "   - php artisan migrate (run migrations)"
else
    echo ""
    echo "❌ Laravel installation failed. Please check the error messages above."
    return 1
fi
