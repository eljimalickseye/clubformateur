# Club des Formateurs — Monorepo

Dépôt unique regroupant le backend API **Laravel 13** et l'application multiplateforme **Flutter**.

---

## 📁 Architecture du projet

```text
clubformateur/
├── backend-laravel/          # API REST Laravel 13 (PHP 8.3-FPM + Nginx)
│   ├── app/                  # Contrôleurs API, Modèles Eloquent, Middleware
│   ├── config/               # Configurations Laravel (Cache Redis, Auth, DB)
│   ├── database/             # Migrations et Seeders
│   ├── docker/               # Nginx, PHP-FPM, Supervisor & Entrypoint
│   ├── docs/                 # Rapport d'audit de sécurité et conformité RGPD
│   ├── routes/api.php        # 59 routes de l'API /api/v1
│   ├── tests/                # Suite de tests automatisés PHPUnit
│   ├── Dockerfile            # Image de production Nginx + PHP 8.3
│   └── docker-compose.yml    # Services API, MySQL 8.0, Redis 7 & phpMyAdmin
│
├── flutter/                  # Application multiplateforme (Web, Android, iOS, Desktop)
│   ├── lib/                  # Code source Dart (Écrans, Services API, Modèles)
│   ├── assets/               # Médias, logos et polices
│   ├── web/                  # Configuration Web & PWA
│   └── pubspec.yaml          # Dépendances Flutter & packages
│
├── docker-compose.yml        # Compose root incluant le backend
├── .gitignore                # Règles d'exclusion unifiées (PHP & Flutter)
└── README.md
```

---

## 🚀 Démarrage rapide

### 1. Démarrer le Backend (API Laravel + MySQL + Redis)

Depuis la racine du projet :
```bash
cd backend-laravel
docker compose --env-file .env.docker up -d
```
Ou directement depuis la racine :
```bash
docker compose -p clubformateur --env-file backend-laravel/.env.docker up -d
```

- **API URL** : `http://localhost:8095/api/v1`
- **Santé de l'API** : `http://localhost:8095/api/v1/health`
- **phpMyAdmin** *(optionnel)* : `http://localhost:8096`

### 2. Démarrer le Frontend Flutter (Web)

Dans un autre terminal :
```bash
cd flutter
flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0 --dart-define=LARAVEL_API_URL=http://localhost:8095/api/v1
```
Ou avec Google Chrome :
```bash
cd flutter
flutter run -d chrome --dart-define=LARAVEL_API_URL=http://localhost:8095/api/v1
```

- **Application Web** : `http://localhost:3000`

---

## 🔒 Sécurité & Audit Réalisé
- **Authentification** : Jetons API hashés en SHA-256 avec date d'expiration, élimination des mocks et validation stricte côté serveur.
- **Protection des paiements & visio** : Clés privées Intech et LiveKit isolées sur le backend Laravel.
- **Conformité RGPD** : Export des données personnelles (`GET /api/v1/user/export-data`) et droit à l'oubli (`POST /api/v1/user/delete-account`).
- **Cache & Performance** : Cache Redis sur le catalogue de formations avec revalidation HTTP `304 Not Modified` via headers `ETag` / `If-None-Match`.
- **Interface Réactive** : Grilles de cours, profils et modales adaptatives garantissant l'absence de débordement graphique sur smartphone et desktop.
