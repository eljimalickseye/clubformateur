# Rapport d'audit : Club des Formateurs (API Laravel)

Date : 2026-10-14
Perimetre : depot `clubformateur` (backend Laravel 13, Docker, 10 controleurs, 59 routes).
Methode : lecture integrale du code, des routes, de la configuration Docker et de l'historique git.
Limite : PHP n'est pas installe sur le poste d'audit, aucun test dynamique n'a ete execute. Les constats viennent de l'analyse statique.

## 1. Resume executif

L'API n'a aucune authentification effective. Aucune route n'est protegee par un middleware, et l'identite de l'appelant est lue dans le corps de la requete (`userId`, `studentId`, `uid`). N'importe quel visiteur anonyme peut donc lire toutes les donnees, se promouvoir administrateur, retirer de l'argent d'un compte tiers et consulter la liste de tous les utilisateurs. Des secrets de production (LiveKit, Intech Paiement, cle applicative) sont versionnes dans git et doivent etre consideres comme compromis.

Bilan : 6 failles critiques, 8 elevees, 7 moyennes, 4 faibles.

## 2. Failles critiques

### C1. Aucune authentification ni autorisation sur les routes
- Fichiers : `routes/api.php` (aucun `middleware`), `bootstrap/app.php` (aucun alias de middleware).
- Toutes les routes sont publiques, y compris `/admin/*`, `/payments/withdraw`, `/trainers`.
- Impact : acces total en lecture et ecriture a toutes les donnees, sans compte.
- Correction : middleware `auth.token` sur toutes les routes sauf `/health`, `/auth/register`, `/auth/login`, `/auth/google`, `/courses` (GET) ; middleware `role:` sur `/admin/*` ; ne plus jamais lire l'identite dans le corps.

### C2. Elevation de privileges a l'inscription et au profil
- `AuthController.php:register` accepte `role` = `admin` ou `super_admin` fourni par l'appelant.
- `AuthController.php:updateProfile` modifie le `role` de n'importe quel `uid` fourni, et, si aucun utilisateur n'est trouve, modifie `User::first()` (le premier compte, donc probablement un administrateur). Le dernier commit du depot (`3483b47 Allow role update in updateProfile endpoint`) a introduit cette faille.
- `AuthController.php:googleLogin` cree un compte avec le role demande, sans verifier le jeton Google.
- Correction : role force a `student` a l'inscription, `role` retire de `updateProfile`, modification de role reservee a l'administrateur.

### C3. Contournement de connexion et connexion sans mot de passe
- `AuthController.php:login` ne verifie jamais le mot de passe. Un email inconnu contenant `admin`, `formateur`, `cheikh`, `moussa`, `fatou`... est rattache au premier compte du role correspondant, et le jeton est retourne. `POST /auth/login` avec `{"email":"admin@x"}` donne un jeton `super_admin`.
- Meme pour un email existant, le mot de passe n'est pas compare a `Hash::check`.
- Correction : verification `Hash::check`, suppression du bloc de comptes de demonstration, reponse generique en cas d'echec.

### C4. Connexion Google sans verification du jeton
- `AuthController.php:googleLogin` fait confiance a l'email envoye par le client. Connaitre l'email d'un utilisateur suffit pour obtenir son jeton d'API.
- Correction : recevoir un `idToken` et le verifier aupres de Google (`https://oauth2.googleapis.com/tokeninfo`, controle de `aud` et `email_verified`).

### C5. Secrets versionnes dans git
- `.env.example` (suivi par git) contient la cle et le secret LiveKit (`LIVEKIT_API_SECRET`) et la cle Intech (`INTECH_API_KEY`) en clair.
- `.env.docker` (suivi par git) contient `APP_KEY`, les identifiants LiveKit et Intech, le mot de passe MySQL.
- `LiveSessionController.php` et `PaymentController.php` reprennent ces valeurs comme repli de `env()` dans le code source.
- `docker-compose.yml` contient les mots de passe MySQL (`club_password`, `root_password`) et les expose a phpMyAdmin.
- Presents depuis le premier commit (`58dc34d`) : la suppression ne suffit pas, ils sont dans l'historique.
- Action obligatoire hors code : rotation immediate de la cle LiveKit, de la cle Intech, de `APP_KEY` et des mots de passe MySQL.
- Correction code : suppression des valeurs par defaut, `.env.example` avec valeurs vides, `.env.docker` sorti de git.

### C6. Retrait d'argent sans controle (fraude financiere)
- `PaymentController.php:withdraw` : `userId`, `amount` et `phone` viennent du corps. Un anonyme peut declencher un cash-out vers son propre numero depuis le solde d'un autre formateur.
- Le statut est force a `SUCCESS` quand l'API Intech est injoignable (`catch` qui avale l'erreur) : la transaction est enregistree comme reussie sans argent verse.
- Si le solde est insuffisant, la transaction est quand meme creee et le solde inchange.
- Pas de transaction SQL ni de verrou : deux retraits simultanes depassent le solde (condition de course).
- Le solde de demonstration `420000` est offert a tout inscrit `teacher` (`register`) : creation d'argent fictif retirable.
- Valeurs par defaut metier (`25000`, `771234567`, `demo_teacher_cheikh`) pour des champs absents.
- Correction : utilisateur issu du jeton, montant valide (min/max, entier positif), transaction avec `lockForUpdate`, statut `PENDING` par defaut puis confirmation, echec Intech = `FAILED`, solde initial a 0.

## 3. Failles elevees

- E1. IDOR generalise : `GET /students/{id}/enrollments`, `/teachers/{id}/wallet`, `/payments/transactions?userId=`, `/conversations?userId=`, `/conversations/{id}/messages` retournent les donnees de n'importe qui. Les messages prives sont lisibles par tous.
- E2. `GET /admin/users` expose email, telephone, solde de tous les utilisateurs sans authentification. Fuite de donnees personnelles (loi senegalaise 2008-12 sur les donnees a caractere personnel, et RGPD pour les utilisateurs europeens).
- E3. `PATCH /admin/users/{uid}/role` et `POST /admin/assign-corrector` : prise de controle de la plateforme par n'importe qui.
- E4. Jetons d'API stockes en clair dans `users.api_token`, longs et sans expiration. Une fuite de base donne un acces direct a tous les comptes. Jeton jamais renouvele a la connexion.
- E5. `CourseController` : creation, modification, suppression, publication de formations ouvertes a tous ; `teacherId` pris dans le corps. Contournement du paiement : `POST /enrollments` accepte `status`, `price` et `paymentMethod` du client, un apprenant s'inscrit gratuitement a tout cours.
- E6. `PATCH /homeworks/{id}/grade` et `PATCH /enrollments/{id}/status` : note et statut modifiables par n'importe qui ; certificats falsifiables.
- E7. Jetons LiveKit : `POST /livekit/token` delivre un jeton avec droit de publication a toute personne qui envoie `isTeacher=true`. N'importe qui peut prendre la parole, ou terminer un live (`POST /live-sessions/{id}/end`).
- E8. Aucune limitation de debit (`throttle`) : force brute sur `/auth/login`, enumeration de comptes, abus sur `/auth/register`.

## 4. Failles moyennes

- M1. Validation d'entree quasi absente : seul `register` valide. `CourseController`, `ChatController`, `HomeworkController`, etc. utilisent `$request->input()` avec valeurs par defaut, sans type ni taille. Risque de donnees corrompues et de stockage de contenu arbitraire (`file_url`, `attachment_url`, `replay_url` acceptent n'importe quelle URL, y compris `javascript:` rendu cote client).
- M2. Mot de passe minimum de 6 caracteres (`register`). Recommandation : 10 minimum, liste de mots de passe courants.
- M3. Comptes de demonstration avec mots de passe faibles (`password123`, `admin123`) crees automatiquement par `docker/entrypoint.sh` (`db:seed`) quand la base est vide, y compris en production (`APP_ENV=production`). Un `super_admin` connu est cree sur le VPS.
- M4. Telephone par defaut fictif `+221 77 000 00 00` ecrit en base pour tout inscrit : donnee fausse presentee comme reelle.
- M5. `docker-compose.yml` : phpMyAdmin publie sur le port 8096 avec identifiants preconfigures, ouvert sur Internet. Redis sans mot de passe. Les services ecoutent en HTTP clair (pas de TLS, `APP_URL=http://...`).
- M6. `docker/nginx.conf` : aucun en-tete de securite (`X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Strict-Transport-Security`) ; `client_max_body_size 150M` sans authentification en amont (abus de ressources).
- M7. `.env.docker` : `LOG_LEVEL=debug` en production ; les erreurs Intech (`catch (\Throwable)`) sont avalees, donc non journalisees.

## 5. Failles faibles

- F1. `/health` expose le message d'erreur de la base (`'error: ' . $e->getMessage()`), qui peut contenir hote et utilisateur.
- F2. `AdminController::updateUserRole` renvoie le modele `User` complet (incluant `api_token`).
- F3. `Dockerfile` : conteneur lance en root par `supervisord`, installation `composer` par script distant sans verification d'empreinte, image `phpmyadmin:latest` non epinglee.
- F4. Couverture de tests quasi nulle (`ExampleTest` uniquement) : aucun garde-fou contre la regression des corrections ci-dessus.

## 6. Protection des donnees personnelles

Donnees traitees : nom, email, telephone, photo, solde, historique de paiement, messages prives, devoirs rendus, notes.

Ecarts constates :
1. Aucun controle d'acces : toutes ces donnees sont lisibles publiquement (E1, E2).
2. Pas de consentement trace : `acceptLegalDocument` accepte n'importe quel `userId` fourni (usurpation du consentement).
3. Pas de droit a l'effacement ni a l'export : aucune route de suppression de compte ni d'export de donnees.
4. Pas de chiffrement en transit garanti : HTTP clair sur le VPS.
5. Jetons et secrets exposes (C5, E4).
6. Pas de duree de conservation definie pour messages, transactions, journaux.
7. Donnees fictives enregistrees comme reelles (M4).

Actions recommandees : authentification forte, minimisation des champs retournes, TLS, hachage des jetons, route de suppression et d'export de compte, politique de conservation, journal d'acces aux donnees d'administration, desactivation de phpMyAdmin en production.

## 7. Elements hors depot (front-end et PWA)

Le depot audite ne contient que l'API. Il n'y a ni manifeste, ni service worker, ni feuille de style applicative (`resources/css/app.css` est le gabarit Laravel vide, `welcome.blade.php` n'est pas utilise par l'application). L'interface mobile et les defauts de responsive (textes et boites qui debordent en mode telephone) se trouvent dans un autre depot, non fourni. Ils n'ont donc pas pu etre audites ici : voir la liste de controle section 8.

## 8. Responsive : liste de controle de correction (a appliquer dans le depot front-end)

Causes habituelles de debordement sur telephone, a verifier une par une :
1. Balise viewport presente : `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`.
2. Aucune largeur fixe en pixels sur les conteneurs ; utiliser `max-width: 100%`, `width: 100%`, `min-width: 0` sur les enfants flex et grid.
3. Textes longs (emails, URLs) : `overflow-wrap: anywhere; word-break: break-word;` ; titres tronques avec `text-overflow: ellipsis` ou retour a la ligne.
4. Images et videos : `max-width: 100%; height: auto;` ; lecteur video en `aspect-ratio: 16/9; width: 100%`.
5. Tableaux (admin, transactions) : envelopper dans `overflow-x: auto` ou les transformer en cartes empilees sous 640 px.
6. Grilles : `grid-template-columns: repeat(auto-fit, minmax(min(100%, 16rem), 1fr))`.
7. Rangees de boutons et onglets : `flex-wrap: wrap` ou defilement horizontal controle.
8. `box-sizing: border-box` global ; eviter `100vw` (inclut la barre de defilement), preferer `100%` ou `100dvh`.
9. Cibles tactiles d'au moins 44 x 44 px ; champs de saisie a 16 px minimum pour eviter le zoom automatique d'iOS.
10. Marges de securite : `padding: env(safe-area-inset-*)` pour les encoches iPhone.
11. Recette : tester a 320, 360, 390 et 414 px, en portrait et paysage, avec les outils d'emulation du navigateur puis sur appareil reel.

## 9. Guide d'installation de la PWA pour les utilisateurs

Prerequis cote produit (a verifier dans le depot front-end) : site servi en HTTPS, fichier `manifest.webmanifest` (nom, icones 192 et 512 px, `display: standalone`, `start_url`), service worker enregistre.

### Android (Chrome)
1. Ouvrir le site du Club des Formateurs dans Chrome.
2. Appuyer sur le menu (trois points) en haut a droite.
3. Choisir "Installer l'application" (ou "Ajouter a l'ecran d'accueil").
4. Confirmer avec "Installer".
5. L'icone apparait sur l'ecran d'accueil et dans la liste des applications ; l'ouvrir lance le site en plein ecran.
Alternative : une banniere "Installer" peut s'afficher automatiquement en bas de l'ecran.
Samsung Internet : menu, "Ajouter la page a", "Ecran d'accueil".

### iPhone et iPad (Safari)
1. Ouvrir le site dans Safari.
2. Appuyer sur le bouton Partager (carre avec une fleche vers le haut).
3. Faire defiler et choisir "Sur l'ecran d'accueil".
4. Verifier le nom, puis appuyer sur "Ajouter".
5. Ouvrir l'application depuis l'icone creee.
Limites iOS : les notifications push exigent iOS 16.4 ou plus et une installation prealable sur l'ecran d'accueil ; le cache hors ligne peut etre purge par le systeme apres quelques semaines sans usage.

### Desinstallation
Android : appui long sur l'icone puis "Desinstaller". iPhone : appui long sur l'icone puis "Supprimer l'app".

## 10. Plan de remediation par priorite

| Priorite | Action | Etat |
|---|---|---|
| Immediate (hors code) | Rotation LiveKit, Intech, APP_KEY, mots de passe MySQL ; fermer le port 8096 | A faire par l'equipe |
| 1 | C5 : retirer les secrets du code et de git | Commits de la branche |
| 2 | C2, C3 : inscription, profil, connexion | Commits de la branche |
| 3 | C1, E1-E3 : middleware d'authentification et de role | Commits de la branche |
| 4 | C6 : retraits | Commits de la branche |
| 5 | C4, E7, E8, M1-M7 | A planifier |
| 6 | Tests de non-regression (F4) | A planifier |
