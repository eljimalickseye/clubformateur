# Script de démarrage rapide Docker — Club des Formateurs (Backend Laravel 13)
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  Club des Formateurs — Démarrage Docker Backend API  " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

docker info > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Docker Desktop n'est pas encore démarré. Veuillez lancer Docker Desktop puis réessayer." -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/2] Construction et lancement des conteneurs (API, MySQL 8, phpMyAdmin, Redis)..." -ForegroundColor Green
docker compose up -d --build

Write-Host ""
Write-Host "[2/2] Services démarrés avec succès !" -ForegroundColor Green
Write-Host " -> API Laravel 13 : http://localhost:8000/api/v1/health" -ForegroundColor White
Write-Host " -> phpMyAdmin     : http://localhost:8080 (Utilisateur: club_user / MDP: club_password)" -ForegroundColor White
Write-Host " -> MySQL 8.0      : localhost:3307 (Base: club_des_formateurs)" -ForegroundColor White
Write-Host " -> Redis 7        : localhost:6379" -ForegroundColor White
