# clubformateur

Backend API **Laravel 13 (PHP 8.3)** Dockerisé pour la plateforme **Club des Formateurs** (`https://club-des-formateurs.web.app`).

---

## 🚀 Déploiement rapide sur un VPS (Ubuntu / Debian) avec Docker

### 1. Cloner le dépôt sur le VPS
```bash
git clone https://github.com/eljimalickseye/clubformateur.git
cd clubformateur
```

### 2. Lancer les conteneurs (API Laravel 13 + MySQL 8.0 + phpMyAdmin + Redis 7)
```bash
docker compose up -d --build
```
Au démarrage, le conteneur exécute automatiquement ([docker/entrypoint.sh](docker/entrypoint.sh)) :
- La création du fichier `.env` à partir de `.env.docker`
- L'attente de disponibilité de MySQL 8.0
- Les migrations des **14 tables** (`php artisan migrate --force`)
- Le pré-remplissage initial (`php artisan db:seed --force`) si la base est vide
- L'ouverture du serveur **Nginx + PHP 8.3-FPM** sur le port `8000`

### 3. Vérifier que l'API répond
```bash
curl http://localhost:8000/api/v1/health
```

---

## 📦 Services inclus dans `docker-compose.yml`

| Service | Conteneur | Port Hôte | Description |
| :--- | :--- | :--- | :--- |
| **API Laravel 13** | `club_formateurs_api` | `8000` | API REST `/api/v1/...` (Nginx + PHP 8.3-FPM + Supervisor) |
| **MySQL 8.0** | `club_formateurs_db` | `3307` | Base `club_des_formateurs` (`club_user` / `club_password`) |
| **phpMyAdmin** | `club_formateurs_pma` | `8080` | Interface Web MySQL (`http://IP_DU_VPS:8080`) |
| **Redis 7** | `club_formateurs_redis` | `6379` | Cache, sessions & files d'attente |

---

## 🔌 Intégrations préconfigurées
- **LiveKit Cloud (Studio Direct & JWT HS256)** : `LIVEKIT_URL=wss://anour-rv83fs3g.livekit.cloud`
- **API Intech (Wave & Orange Money Sénégal)** :
  - `WAVE_SERVICE_CODE=WAVE_SN_API_CASH_OUT`
  - `OM_SERVICE_CODE=ORANGE_SN_API_CASH_OUT`

---

## 🛣️ Aperçu des 59 Routes API (`/api/v1`)
- `GET /api/v1/health` — Statut de santé de l'API
- `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `POST /api/v1/auth/demo-login`, `GET /api/v1/auth/me`
- `GET|POST /api/v1/courses`, `PUT|DELETE /api/v1/courses/{id}`, `PATCH /api/v1/courses/{id}/toggle-publish`, `POST /api/v1/courses/upload-media`
- `GET|POST /api/v1/courses/{id}/lessons`, `GET|POST /api/v1/courses/{id}/replays`
- `GET|POST /api/v1/live-sessions`, `POST /api/v1/live-sessions/{id}/start`, `POST /api/v1/live-sessions/{id}/switch-phase`, `POST /api/v1/live-sessions/{id}/end`, `POST /api/v1/live-sessions/{id}/token`
- `GET /api/v1/payments/wallet`, `POST /api/v1/payments/withdraw`, `POST /api/v1/payments/checkout`, `POST /api/v1/payments/status`
- `GET|POST /api/v1/chat/conversations`, `GET|POST /api/v1/chat/conversations/{id}/messages`
- `GET|POST /api/v1/homeworks`, `POST /api/v1/homeworks/{id}/grade`
- `GET|POST /api/v1/study-groups`, `POST /api/v1/study-groups/{id}/join`
- `GET /api/v1/admin/overview`, `GET /api/v1/admin/users`, `PATCH /api/v1/admin/users/{id}/role`
