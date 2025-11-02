#!/bin/bash

# Script de verificación para Voley App
# Este script verifica que todo esté configurado correctamente

echo "🏐 Verificando configuración de Voley App..."
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador de errores
ERRORS=0

# Función para verificar comandos
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 está instalado"
        return 0
    else
        echo -e "${RED}✗${NC} $1 NO está instalado"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Función para verificar archivos
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 existe"
        return 0
    else
        echo -e "${RED}✗${NC} $1 NO existe"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Función para verificar directorios
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 existe"
        return 0
    else
        echo -e "${RED}✗${NC} $1 NO existe"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

echo "📋 Verificando herramientas necesarias..."
echo ""

check_command "node"
if [ $? -eq 0 ]; then
    NODE_VERSION=$(node --version)
    echo "   Versión: $NODE_VERSION"
fi

check_command "npm"
if [ $? -eq 0 ]; then
    NPM_VERSION=$(npm --version)
    echo "   Versión: $NPM_VERSION"
fi

check_command "firebase"
if [ $? -eq 0 ]; then
    FIREBASE_VERSION=$(firebase --version)
    echo "   Versión: $FIREBASE_VERSION"
fi

check_command "flutter"
if [ $? -eq 0 ]; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo "   Versión: $FLUTTER_VERSION"
fi

echo ""
echo "📁 Verificando estructura del proyecto..."
echo ""

check_dir "functions"
check_dir "functions/src"
check_dir "lib"
check_dir "lib/src"

echo ""
echo "📄 Verificando archivos importantes..."
echo ""

check_file "functions/src/index.ts"
check_file "functions/package.json"
check_file "functions/tsconfig.json"
check_file "pubspec.yaml"
check_file "firebase.json"
check_file ".firebaserc"

echo ""
echo "🔧 Verificando dependencias de Cloud Functions..."
echo ""

if [ -d "functions/node_modules" ]; then
    echo -e "${GREEN}✓${NC} node_modules existe"
else
    echo -e "${YELLOW}⚠${NC} node_modules NO existe. Ejecuta: cd functions && npm install"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "🏗️  Verificando compilación de Cloud Functions..."
echo ""

if [ -f "functions/lib/index.js" ]; then
    echo -e "${GREEN}✓${NC} Cloud Functions compiladas (lib/index.js existe)"
else
    echo -e "${YELLOW}⚠${NC} Cloud Functions NO compiladas. Ejecuta: cd functions && npm run build"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "🔐 Verificando autenticación de Firebase..."
echo ""

if firebase projects:list &> /dev/null; then
    echo -e "${GREEN}✓${NC} Autenticado en Firebase"
    CURRENT_PROJECT=$(firebase use)
    echo "   Proyecto actual: $CURRENT_PROJECT"
else
    echo -e "${RED}✗${NC} NO autenticado en Firebase. Ejecuta: firebase login"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "📊 Resumen"
echo "=========="

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Todo está configurado correctamente!${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "1. Compilar las funciones: cd functions && npm run build"
    echo "2. Desplegar: firebase deploy --only functions"
    echo "3. Ver la guía completa: cat CLOUD_FUNCTIONS_GUIDE.md"
    exit 0
else
    echo -e "${RED}✗ Se encontraron $ERRORS problema(s)${NC}"
    echo ""
    echo "Por favor, corrige los problemas antes de continuar."
    echo "Consulta DEPLOYMENT.md para más información."
    exit 1
fi
