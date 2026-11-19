#!/usr/bin/env bash
# Ejecuta todos los scripts en orden. Uso: ./instalar.sh [usuario]
# (pedira la contrasena del usuario de MySQL)
set -e
USUARIO="${1:-root}"
cd "$(dirname "$0")"
cat 0*.sql > la_mundial_completo.sql
mysql -u "$USUARIO" -p --table < la_mundial_completo.sql
echo "Base de datos la_mundial instalada."
