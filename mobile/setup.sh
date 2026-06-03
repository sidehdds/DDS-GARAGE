#!/bin/bash
set -e

ARCH=$(uname -m)
FLUTTER="$HOME/development/flutter/bin/flutter"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== AI GARAGE — Setup Flutter ==="

# 1. Xcode CLT
if ! xcode-select -p &>/dev/null; then
  echo "→ Installation des Xcode Command Line Tools..."
  sudo xcode-select --install 2>/dev/null || true
  echo "   Clique sur 'Installer' dans la fenêtre qui s'ouvre, puis relance ce script."
  exit 1
fi
echo "✓ Xcode CLT OK"

# 2. Flutter path
if ! command -v flutter &>/dev/null; then
  if [ -f "$FLUTTER" ]; then
    export PATH="$HOME/development/flutter/bin:$PATH"
    echo "export PATH=\"\$HOME/development/flutter/bin:\$PATH\"" >> ~/.zshrc
    echo "✓ Flutter ajouté au PATH (redémarre le terminal après)"
  else
    echo "✗ Flutter introuvable. Lance d'abord le téléchargement."
    exit 1
  fi
fi
FLUTTER=$(which flutter)
echo "✓ Flutter : $($FLUTTER --version 2>&1 | head -1)"

# 3. Créer le projet Flutter
APP_DIR="$HOME/ai_garage_app"
if [ ! -d "$APP_DIR" ]; then
  echo "→ Création du projet Flutter..."
  $FLUTTER create --org com.aigarage --project-name ai_garage --no-pub "$APP_DIR"
fi
echo "✓ Projet créé : $APP_DIR"

# 4. Copier nos fichiers
echo "→ Copie des fichiers source..."
cp "$SCRIPT_DIR/pubspec.yaml" "$APP_DIR/pubspec.yaml"
cp -r "$SCRIPT_DIR/lib/"*  "$APP_DIR/lib/"
echo "✓ Fichiers copiés"

# 5. flutter pub get
echo "→ Installation des dépendances..."
cd "$APP_DIR" && $FLUTTER pub get
echo "✓ Dépendances installées"

echo ""
echo "══════════════════════════════════════════"
echo "  L'app est prête ! Pour la lancer :"
echo ""
echo "  cd ~/ai_garage_app"
echo "  flutter run          # simulateur iOS"
echo "  flutter run -d chrome  # navigateur web"
echo "══════════════════════════════════════════"
echo ""
echo "⚠️  N'oublie pas de démarrer le serveur Flask :"
echo "  cd /Users/dds/AI-GARAGE && python3 app.py"
echo ""
echo "Sur un vrai iPhone/Android, change l'URL dans :"
echo "  mobile/lib/services/api_service.dart → kBaseUrl"
echo "  (remplace 127.0.0.1 par l'IP de ton Mac sur le réseau)"
