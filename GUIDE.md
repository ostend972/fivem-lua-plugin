# FiveM Lua Plugin — Guide d'utilisation

Plugin Claude Code pour creer des scripts FiveM en Lua avec un process structure, des regles de qualite automatiques et les best practices ESX/QBCore/QBOX.

---

## Installation

```bash
# 1. Ajouter le marketplace
claude plugin marketplace add https://github.com/ostend972/fivem-lua-plugin

# 2. Installer le plugin
claude plugin install fivem-lua

# 3. Verifier
claude plugin list
# => fivem-lua@fivem-lua-marketplace — Status: enabled
```

> Tu dois etre collaborateur sur le repo GitHub (demande a Alan de t'ajouter) ou le repo doit etre public.

---

## Le Process : 6 commandes, dans l'ordre

Le plugin suit un workflow structure inspire de spec-kit. Chaque commande produit un fichier dans `specs/` qui sert d'input a la suivante.

```
/fivem.specify  →  specs/spec.md     (QUOI faire)
      ↓
/fivem.plan     →  specs/plan.md     (COMMENT le faire)
      ↓
/fivem.tasks    →  specs/tasks.md    (DANS QUEL ORDRE)
      ↓
/fivem.implement →  le code           (EXECUTION)
      ↓
/fivem.review   →  rapport d'audit   (QUALITE)
      ↓
/fivem.optimize →  optimisations     (PERFORMANCE)
```

---

## Commandes en detail

### `/fivem.specify` — Definir le script

Decris ce que tu veux en langage naturel. Claude genere une specification complete.

```
/fivem.specify un systeme de garage avance pour QBCore avec garage public,
impound, garage de job police/EMS, sauvegarde des mods vehicule
```

**Ce que ca produit** : `specs/spec.md` avec features, dependances, scenarios utilisateur, exigences securite/performance, schema DB, config values.

**Conseils** :
- Precise toujours le framework (ESX, QBCore, QBOX)
- Mentionne les dependances si tu en veux (ox_target, ox_inventory, etc.)
- Plus ta description est detaillee, meilleur sera le spec

---

### `/fivem.plan` — Plan technique

Genere l'architecture complete du script a partir du spec.

```
/fivem.plan
```

**Ce que ca produit** : `specs/plan.md` avec structure de fichiers, fxmanifest.lua, decisions techniques (framework init, performance strategy, security strategy, database design), diagramme d'architecture.

---

### `/fivem.tasks` — Decoupage en taches

Transforme le plan en taches ordonnees et executables.

```
/fivem.tasks
```

**Ce que ca produit** : `specs/tasks.md` avec des taches numerotees (T001, T002...) organisees par phase :
- Phase 1 : Setup (structure, fxmanifest, config, locales, SQL)
- Phase 2 : Server foundation
- Phase 3 : Client foundation
- Phase 4+ : Features (une phase par feature)
- Phase finale : Polish et validation

Les taches marquees `[P]` peuvent etre executees en parallele.

---

### `/fivem.implement` — Ecrire le code

Execute toutes les taches une par une avec verification constitution a chaque etape.

```
/fivem.implement
```

**Ce que ca fait** :
- Cree tous les fichiers dans l'ordre du plan
- Applique automatiquement les patterns de securite (validation 6 etapes sur chaque event serveur)
- Utilise les patterns de performance (dynamic Wait, cache.ped, lib.zones)
- Coche chaque tache `[X]` dans tasks.md au fur et a mesure
- A la fin : validation constitution sur tout le code

**Le hook automatique** : Chaque fichier `.lua` ecrit ou modifie est verifie automatiquement pour :
- `while true` sans `Wait()` (crash serveur)
- `GetPlayerPed(-1)` deprecie
- `string.format` dans des requetes SQL (injection)
- Fonctions globales sans `local`

---

### `/fivem.review` — Auditer le code

Analyse complete du code contre les regles de qualite.

```
/fivem.review
```

ou pour un fichier specifique :

```
/fivem.review server/main.lua
```

**Ce que ca produit** : Un rapport avec :
- Grade global (A a F)
- Issues par severite (CRITICAL / HIGH / MEDIUM / LOW)
- Pour chaque issue : fichier, ligne, code actuel, fix recommande
- Table de conformite constitution

---

### `/fivem.optimize` — Optimiser les performances

Analyse et corrige les problemes de performance pour minimiser le resmon.

```
/fivem.optimize
```

**Ce que ca fait** :
- Detecte les threads qui consomment trop de CPU
- Remplace les natives non-cachees par `cache.ped`, `cache.coords`, etc.
- Convertit les boucles statiques en dynamic Wait
- Propose de remplacer les threads manuels par `lib.zones` / `lib.points`
- Applique les corrections et montre le avant/apres

**Cible** : < 0.2ms idle sur resmon.

---

## Commande bonus

### `/fivem.native` — Rechercher une native

Cherche une native GTA V / FiveM par nom ou par description.

```
/fivem.native GetEntityCoords
/fivem.native comment teleporter un joueur
/fivem.native creer un blip sur la map
```

---

## La Constitution (regles non-negociables)

Le plugin applique des regles strictes a chaque etape. Les violations sont bloquantes.

### NEVER (jamais faire)
1. `while true do` sans `Wait()` a l'interieur
2. Operations argent/items/armes cote client
3. `GetPlayerPed(-1)` — deprecie, utiliser `PlayerPedId()` ou `cache.ped`
4. Variables globales — toujours `local`
5. `string.format` dans des requetes SQL — utiliser les prepared statements `@param`
6. `source` utilise apres un yield dans un handler serveur
7. Valeurs hardcodees — tout dans `Config`
8. `Citizen.CreateThread` / `Citizen.Wait` — utiliser `CreateThread` / `Wait`
9. Envoyer des donnees sensibles via events client
10. `TriggerClientEvent` a tous les joueurs pour des donnees specifiques a un joueur

### ALWAYS (toujours faire)
1. `lua54 'yes'` dans fxmanifest.lua
2. `RegisterNetEvent` AVANT `AddEventHandler`
3. Sauvegarder `source` dans une variable locale AVANT tout yield
4. Validation serveur 6 etapes sur chaque event
5. Dynamic `Wait()` pour les boucles de proximite
6. `cache.ped` / `cache.coords` au lieu de `PlayerPedId()` / `GetEntityCoords()` dans les boucles
7. `#(a - b)` au lieu de `Vdist()`
8. Prepared statements pour toutes les requetes SQL
9. `SetNuiFocus(false, false)` quand on ferme un NUI
10. Cleanup des handlers sur `onResourceStop`

---

## Structure type d'un script genere

```
mon_script/
├── fxmanifest.lua          -- fx_version 'cerulean', lua54 'yes'
├── config/
│   └── config.lua          -- Config = {} (toutes les valeurs configurables)
├── client/
│   ├── main.lua            -- Init framework, threads, zones
│   └── [feature].lua       -- Modules par feature
├── server/
│   ├── main.lua            -- Init framework, callbacks, events
│   └── [feature].lua       -- Modules par feature
├── shared/
│   └── utils.lua           -- Fonctions partagees (si besoin)
├── locales/
│   ├── en.lua              -- Traductions anglais
│   └── fr.lua              -- Traductions francais
└── sql/
    └── install.sql         -- Schema de base de donnees
```

---

## Frameworks supportes

| Framework | Init Server | Init Client |
|-----------|-------------|-------------|
| **ESX Legacy** | `ESX = exports['es_extended']:getSharedObject()` | Idem |
| **QBCore** | `QBCore = exports['qb-core']:GetCoreObject()` | Idem |
| **QBOX** | Comme QBCore + ox_lib partout | Idem |

Le plugin charge automatiquement les patterns du framework que tu specifies.

---

## Ecosysteme ox (recommande)

Le plugin utilise par defaut l'ecosysteme ox quand c'est pertinent :

| Outil | Usage |
|-------|-------|
| **ox_lib** | Notifications, menus, progress bars, zones, points, cache, callbacks |
| **ox_target** | Interactions 3D (eye target) |
| **ox_inventory** | Inventaire (si besoin) |
| **oxmysql** | Requetes DB avec prepared statements |

---

## Tips

- **Commence toujours par `/fivem.specify`** — meme pour un petit script, ca structure ta pensee
- **Utilise `/fivem.review` sur du code existant** — ca marche aussi pour auditer des scripts deja ecrits
- **`/fivem.optimize` apres chaque script** — ca peut diviser ton resmon par 10
- **Le hook est automatique** — chaque `.lua` que tu ecris est verifie en temps reel
- **Invoque `/fivem-lua`** pour avoir une reference rapide sur n'importe quel sujet FiveM
- **Tu peux sauter des etapes** — si tu as deja ton plan, va direct a `/fivem.tasks`

---

## Mise a jour du plugin

```bash
claude plugin marketplace update fivem-lua-marketplace
claude plugin update fivem-lua@fivem-lua-marketplace
```

---

## En cas de probleme

```bash
# Verifier le statut
claude plugin list

# Desinstaller / reinstaller
claude plugin uninstall fivem-lua
claude plugin install fivem-lua

# Valider la structure du plugin
claude plugin validate chemin/vers/le/plugin
```
