#!/bin/bash
# ================================
# 🚀 Manejo de Control de Versiones
# Proyecto: MiniMarket JABYD
# Repo: https://github.com/absel-crypto/MiniMarket-JABYD.git
# ================================

# 1. Configuración inicial de Git
git config --global user.name "Absel Ditta"
git config --global user.email "tucorreo@example.com"

# 2. Clonar el repositorio
git clone https://github.com/absel-crypto/MiniMarket-JABYD.git
cd MiniMarket-JABYD

# 3. Crear rama principal (main)
git checkout -b main
git push origin main

# 4. Crear rama para el módulo Registro
git checkout -b feature/registro
git add .
git commit -m "Implementación del módulo de registro con validaciones y conexión a BD"
git push origin feature/registro

# 5. Crear rama para el módulo Inicio de Sesión
git checkout -b feature/login
git add .
git commit -m "Implementación del módulo de inicio de sesión con validaciones"
git push origin feature/login

# 6. Crear rama para la Página Principal (Inventario)
git checkout -b feature/inventario
git add .
git commit -m "Diseño y funcionalidad de la página principal de inventario con listado de productos"
git push origin feature/inventario

# 7. Crear rama para la API REST
git checkout -b feature/api
git add .
git commit -m "Creación de API REST con Slim para gestión de productos y usuarios"
git push origin feature/api

# 8. Regresar a main e integrar (ideal hacerlo con PRs en GitHub, aquí se simula el merge)
git checkout main
git merge feature/registro
git merge feature/login
git merge feature/inventario
git merge feature/api
git push origin main

# ================================
# ✅ Proyecto versionado en GitHub con flujo profesional
# ================================
