

[frontend summary](sum.flutterFRONTEND.md)
[backend summary](sum.alBACKEND.md)
[middleware summary](sum.nodeMIDDLEWARE.md)


# **producTiv**

Plan de Déploiement en Production

*Guide complet de bout en bout — Extension BC · Proxy Node · IA Python · Flutter*

Juin 2026

---

# **1. Prérequis Avant Déploiement**

## **1.1 Exigences d'Infrastructure**

| **Composant** | **Exigence** |
|---|---|
| Serveur Business Central | BC 21 (Plateforme 21.0.0.0) ou ultérieur ; OData V4 activé ; licence de développement pour l'installation de l'extension AL |
| Serveur Proxy (Windows) | Windows Server 2019+ ou Windows 10/11 ; Node.js 18+ installé ; joint au domaine pour SSPI ; PowerShell 5.1+ ; .NET Framework 4.7+ |
| Serveur de l'Agent IA | Linux ou Windows ; Python 3.10+ ; pip ; 4 Go de RAM minimum (8 Go recommandés pour un LLM local) ; accès réseau au point de terminaison LLM choisi |
| Réseau | Le serveur proxy doit atteindre le serveur BC sur le port OData (par défaut 7048 ou 443) ; les clients Flutter atteignent le serveur proxy sur PROXY_PORT (par défaut 3000) |
| Fournisseur LLM | L'un des suivants : instance Ollama locale, clé API OpenAI, token HuggingFace, clé API Groq/Together/Mistral, ou clé API Anthropic |
| Configuration BC | GUID de la société, nom de l'instance, OData V4 activé dans la configuration du serveur BC |

## **1.2 Actions de Sécurité Critiques (Avant TOUT Déploiement)**

⚠ Ces actions doivent être effectuées avant la mise en production : 1. Supprimer src/3-CodeUnit/dev-toberemoved/MESDevSetup.al du projet AL entièrement 2. Définir allow_origins dans main.py sur le domaine/IP Flutter réel (et non \*) 3. Connecter express-rate-limit aux routes de index.js

---

# **2. Phase 1 — Extension AL Business Central**

## **2.1 Préparer le Projet AL**

- Ouvrir le projet AL dans Visual Studio Code avec l'extension AL Language installée
- Vérifier app.json : confirmer runtime = '10.0', platform = '21.0.0.0', application = '21.0.0.0'
- Supprimer ou exclure src/3-CodeUnit/dev-toberemoved/MESDevSetup.al de la compilation

## **2.2 Configurer launch.json**

```json
{ "version": "0.2.0", "configurations": [{ "type": "al", "request": "launch", "name": "producTiv Production", "server": "https://your-bc-server.example.com", "serverInstance": "YourBCInstance", "tenant": "default", "authentication": "Windows", "startupObjectType": "Page", "startupObjectId": 50140 }]}
```

## **2.3 Déployer l'Extension**

- Exécuter Ctrl+Shift+B (ou F5) pour publier l'extension dans BC
- S'assurer que le service web MES est publié dans BC : Admin → Services Web → vérifier que 'MESWebService' avec ServiceName et ObjectID 50126 est Actif
- Alternativement, publier depuis WebServices.xml en l'important dans BC (Paramètres → Personnalisation → Services Web → Importer)

## **2.4 Configuration Initiale**

- Dans BC : ouvrir la Page 50140 (MES API Debug)
- Cliquer sur 'Run Setup' — crée l'utilisateur ADMIN (id : ADMIN, authId : AUTH-ADMIN01) avec le mot de passe temporaire '00000000' et enregistre la file d'attente de travaux pour l'expiration des mots de passe
- CHANGER IMMÉDIATEMENT le mot de passe administrateur via la connexion Flutter à la première utilisation (l'indicateur de changement forcé est activé)
- Créer les enregistrements d'employés dans BC pour tous les utilisateurs MES avant d'utiliser Admin Create User dans Flutter
- Affecter les centres de charge aux centres de charge machine dans BC — ceux-ci déterminent la liste des machines dans Flutter

---

# **3. Phase 2 — Proxy Middleware Node.js**

## **3.1 Installer Node.js**

- Télécharger et installer Node.js 18 LTS depuis nodejs.org sur le serveur proxy Windows
- Vérifier : node --version et npm --version dans PowerShell

## **3.2 Déployer les Fichiers de l'Application**

```bash
# Copier node-middleware/ sur le serveur, ex. C:\Apps\producTiv-proxy\
cd C:\Apps\producTiv-proxy
npm install
```

## **3.3 Configurer l'Environnement**

Copier .env.example vers .env et renseigner toutes les valeurs :

```
BC_HOST=https://your-bc-server.example.com
BC_INSTANCE=YourBCInstance
BC_COMPANY=YOUR-COMPANY-GUID-HERE
PROXY_PORT=3000
NODE_ENV=production
ALLOWED_ORIGINS=http://192.168.1.100,https://yourdomain.com
BC_TIMEOUT_MS=30000
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=300
AI_AGENT_URL=http://localhost:8000
AI_TIMEOUT_MS=120000
# Compte de service Windows qui exécute le processus Node (pour SSPI) :
# BC_DOMAIN=CONTOSO
# BC_USERNAME=svc-mes-proxy
# BC_PASSWORD=<password>
```

## **3.4 Connecter la Limitation de Débit (Correctif de Sécurité)**

Dans index.js, ajouter ce qui suit avant le montage des routes pour activer la limitation de débit :

```javascript
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({ windowMs: config.RATE_LIMIT_WINDOW, max: config.RATE_LIMIT_MAX, standardHeaders: true, legacyHeaders: false,});
app.use('/api/', limiter);
```

## **3.5 Restreindre CORS (Correctif de Sécurité)**

Dans src/cors.js, remplacer la fonction origin toujours vraie par une vérification d'origine correcte :

```javascript
const { ALLOWED_ORIGINS } = require('./config');
module.exports = { origin: function(origin, callback) { if (!origin || ALLOWED_ORIGINS.includes(origin)) { callback(null, true); } else { callback(new Error('CORS: origin ' + origin + ' not allowed')); } }, // ... reste des options inchangé};
```

## **3.6 Exécuter en tant que Service Windows**

- Installer pm2 globalement : npm install -g pm2

```bash
pm2 start index.js --name producTiv-proxy
pm2 save
pm2 startup windows-service
# Suivre la sortie de la commande pour enregistrer en tant que service Windows
# Vérifier :
pm2 status
curl http://localhost:3000/health
```

## **3.7 Valider la Configuration**

```bash
npm test # Valide que toutes les variables d'environnement requises sont chargées correctement
```

## 3.7 Recréer la Couche de Communication

En fonction du schéma de connexion de l'installation de Business Central, il peut être nécessaire de recréer une partie du code pour utiliser ce schéma, qui sera plus sécurisé que la version actuelle qui utilise le compte courant de la session Windows connectée, laquelle est vulnérable aux cybermenaces.

---

# **4. Phase 3 — Agent IA Python**

## **4.1 Configuration de l'Environnement**

```bash
# Python 3.10+ requis
cd python-ai/
python -m venv .venv
source .venv/bin/activate   # Linux/macOS
.venv\Scripts\activate      # Windows
pip install -r requirements.txt
```

## **4.2 Configurer l'Environnement**

Copier env.example vers .env et définir les valeurs selon le fournisseur LLM choisi :

```
# Choisir UN fournisseur :
LLM_PROVIDER=anthropic   # ou ollama / openai / huggingface / openai_compatible
LLM_TEMPERATURE=0.1
LLM_MAX_TOKENS=2048
LLM_TIMEOUT=120
# Pour Anthropic :
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-3-5-haiku-20241022
# Pour Ollama (local, sans coût) :
# LLM_PROVIDER=ollama
# OLLAMA_BASE_URL=http://localhost:11434
# OLLAMA_MODEL=llama3.1:8b
MIDDLEWARE_BASE_URL=http://localhost:3000/api
BC_COMPANY=YOUR-COMPANY-GUID-HERE
TOOL_HTTP_TIMEOUT=20
LLM_MAX_CONTEXT_CHARS=12000
DEBUG_DATA=false
```

## **4.3 Configurer CORS**

Dans main.py, mettre à jour allow_origins pour restreindre au seul serveur proxy Node :

```python
app.add_middleware( CORSMiddleware, allow_origins=["http://localhost:3000", "http://YOUR-PROXY-SERVER-IP:3000"], allow_methods=["POST", "GET", "OPTIONS"], allow_headers=["*"],)
```

## **4.4 Démarrer l'Agent**

```bash
# Développement :
uvicorn main:app --reload --host 0.0.0.0 --port 8000
# Production (avec gestionnaire de processus) :
pip install gunicorn
gunicorn main:app -w 2 -k uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000 --timeout 150
# Sur Linux — enregistrer avec systemd (recommandé) :
# Voir le modèle de service systemd ci-dessous
```

## **4.5 Service Systemd (Linux)**

```ini
[Unit]
Description=producTiv AI Agent
After=network.target
[Service]
Type=simple
User=mesai
WorkingDirectory=/opt/producTiv/python-ai
EnvironmentFile=/opt/producTiv/python-ai/.env
ExecStart=/opt/producTiv/python-ai/.venv/bin/gunicorn main:app \
  -w 2 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000 --timeout 150
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
```

## **4.6 Vérifier l'Agent**

```bash
curl http://localhost:8000/health
# Attendu : {"status": "ok"}
# Via le proxy Node :
curl http://localhost:3000/api/ai/health
# Attendu : {"node_proxy": "ok", "python_agent": {"status": "ok"}}
```

---

# **5. Phase 4 — Build et Distribution de l'Application Flutter**

## **5.1 Corrections Avant Build**

- Définir AppConstants.devToken = null
- Définir AppConstants.aiDebug = false

## **5.2 Configuration de l'Environnement**

L'URL de l'hôte est configurable à l'exécution via la ParingPage (écran de configuration au premier lancement). Cependant, pour un déploiement en entreprise où l'URL du proxy est connue, vous pouvez coder la valeur par défaut en dur dans AppConstants :

```dart
// lib/core/app_constants.dart
// Option A : Laisser l'hôte vide — les utilisateurs scannent/saisissent l'URL du proxy au premier lancement (par défaut)
static String host = '';
// Option B : Coder en dur pour l'entreprise (mettre en commentaire loadHost() dans l'initialisation de main.dart)
static String host = 'http://YOUR-PROXY-SERVER:3000/api/';
```

## **5.3 Build Android**

```bash
flutter build apk --release
# Sortie : build/app/outputs/flutter-apk/app-release.apk
# Ou pour le Play Store :
flutter build appbundle --release
# Sortie : build/app/outputs/bundle/release/app-release.aab
# Distribuer via :
# - Installation directe APK (sideload) — le plus simple pour l'entreprise
# - Firebase App Distribution
# - Google Play Store (App Bundle)
```

## **5.4 Build iOS**

```bash
# Nécessite macOS avec Xcode 15+
flutter build ipa --release
# Sortie : build/ios/ipa/pfe_mes.ipa
# Distribuer via :
# - Apple Business Manager (entreprise)
# - TestFlight (tests)
# - App Store
```

## **5.5 Build Web (Tableau de Bord Admin)**

```bash
flutter build web --release
# Sortie : build/web/
# Servir avec Nginx ou tout serveur statique :
# Exemple nginx.conf — servir build/web/ sur le port 80/443
# Ajouter proxy_pass si nécessaire pour atteindre le proxy Node sur le port 3000
```

## **5.6 Build Desktop Windows**

```bash
flutter build windows --release
# Sortie : build/windows/x64/runner/Release/
# Distribuer sous forme de ZIP ou utiliser Inno Setup / NSIS pour créer un installateur
```

---

# **6. Phase 5 — Post-Déploiement et Liste de Contrôle de Mise en Production**

## **6.1 Configuration Admin (via le Panneau Admin Flutter)**

- Se connecter en tant qu'ADMIN (AUTH-ADMIN01) — le changement de mot de passe forcé se déclenchera
- Définir un mot de passe administrateur sécurisé (minimum 8 caractères, majuscule + minuscule + chiffre + caractère spécial)
- Naviguer vers Paramètres → définir la Période de Changement de Mot de Passe (ex. 90 jours) et activer la 2FA si des badges QR sont déployés
- Naviguer vers Utilisateurs et Rôles → créer des comptes pour tous les superviseurs et opérateurs
- Pour chaque utilisateur : générer un mot de passe temporaire, le partager de manière sécurisée, lui demander de le changer à la première connexion
- Si la 2FA est activée : utiliser 'View Badge' pour exporter le PDF QR de chaque utilisateur ; distribuer les badges

## **6.2 Tests de Fumée**

| **#** | **Test** | **Résultat Attendu** |
|---|---|---|
| 1 | GET /health sur le proxy Node | {status: 'ok', uptime: N, timestamp: ...} |
| 2 | GET /api/ai/health sur le proxy Node | {node_proxy: 'ok', python_agent: {status: 'ok'}} |
| 3 | Connexion Flutter avec les identifiants ADMIN | L'écran de changement de mot de passe forcé apparaît |
| 4 | Créer un utilisateur Superviseur, affecter un centre de charge | L'utilisateur apparaît dans la liste, badge de configuration en attente affiché |
| 5 | Se connecter en tant qu'Opérateur, voir la liste des machines | Les machines du centre de charge affecté apparaissent avec leur statut |
| 6 | Démarrer une opération sur un ordre lancé | Le statut de la machine passe à En cours ; l'onglet 1 affiche l'opération en cours |
| 7 | Déclarer une quantité produite | Le % de progression se met à jour ; le bouton d'impression d'étiquette apparaît à 100 % |
| 8 | Scanner un code-barres de composant | Composant consommé ; la quantité restante de la nomenclature diminue |
| 9 | Déclarer un rebut (Produit Fini) | La quantité de rebut apparaît dans les données en direct ; le taux de rebut est calculé |
| 10 | Le superviseur termine l'opération | La machine passe en Inactif ; le statut de l'ordre de production BC se met à jour |
| 11 | Chat IA : 'Quelles machines sont en marche ?' | Résultat de requête composite listant les machines En cours |
| 12 | File d'attente de travaux d'expiration des mots de passe | Vérifier dans les Entrées de File d'Attente de Travaux BC — statut MES Password Expiry Check = Prêt |

## **6.3 Surveillance et Maintenance**

- Journaux du proxy Node : pm2 logs producTiv-proxy — surveiller les erreurs 502/504 indiquant des problèmes de connectivité BC
- Journaux de l'agent Python : journalctl -u producTiv-ai -f (systemd Linux) — surveiller les délais d'expiration LLM et les taux d'échec des outils
- File d'attente BC : s'assurer que MES Password Expiry Check s'exécute quotidiennement (toutes les 1440 minutes)
- Nettoyage des tokens : MESAuthMgt.CleanupExpiredTokens() n'est pas planifié — configurer une entrée de file d'attente de travaux pour un nettoyage hebdomadaire

---

# **7. Référence de l'Environnement de Production**

| **Service** | **Point de Terminaison par Défaut** | **Remarques** |
|---|---|---|
| Service Web OData BC | https://\<bc-host\>/\<instance\>/ODataV4/MESWebService\_\<endpoint\>?company=\<GUID\> | Authentification SSPI uniquement ; ne jamais exposer directement aux clients Flutter |
| API Personnalisée BC | https://\<bc-host\>/\<instance\>/api/yourcompany/v1/v1.0/companies(\<GUID\>)/\<resource\> | scrapCodes, workCenters, employees |
| Proxy Node.js | http://\<proxy-server\>:3000/api/\<endpoint\> | Les clients Flutter pointent ici ; le proxy gère toute l'authentification BC |
| Agent IA Python | http://localhost:8000/chat (interne) | Accessible uniquement par le proxy Node ; non exposé à l'extérieur |
| Chat IA (via proxy) | http://\<proxy-server\>:3000/api/ai/chat | Flutter appelle ceci ; le proxy transfère vers l'agent Python |
| URL Hôte de l'App Flutter | http://\<proxy-server\>:3000/api/ | Définie par l'utilisateur sur la ParingPage ou codée en dur pour les builds entreprise |

## **7.1 Règles de Pare-feu Requises**

| **Source** | **Destination** | **Port/Protocole** | **Objet** |
|---|---|---|---|
| Clients Flutter | Proxy Node | TCP 3000 (ou 443 avec TLS) | Communication App → Proxy |
| Proxy Node | Serveur BC | TCP 7048 (OData) ou 443 | Proxy → BC (authentifié SSPI) |
| Proxy Node | Agent IA (localhost) | TCP 8000 | Interne — même hôte ou réseau privé |
| Agent IA | Fournisseur LLM | TCP 443 | IA → API LLM externe (si pas Ollama local) |
| Serveur BC | Proxy Node | N/A | Aucun flux entrant requis — BC n'initie jamais d'appels vers le proxy |