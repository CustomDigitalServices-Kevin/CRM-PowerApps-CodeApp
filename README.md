# CRM Suivi d'Affaires - Power Apps Code App

Un cahier des charges complet et une configuration Claude Code cle-en-main pour developper un **CRM de suivi d'affaires** en tant que **Power Apps Code App** (React / TypeScript / Dataverse).

Ce projet fournit tout le necessaire pour qu'un developpeur (ou Claude Code) puisse construire un CRM professionnel de A a Z, sans improvisation.

---

## Contenu du repository

| Fichier | Description |
|---|---|
| `COWORK_SETUP_CLAUDE_DIR_V2.md` | **Mission de setup** - A executer EN PREMIER. Instructions pour creer le dossier `.claude/` avec agents, hooks et configurations anti-vibe-coding. Contient aussi toute la documentation technique Power Apps Code App (pieges SDK, patterns, Dataverse). |
| `CDC_CRM_PowerApps_CodeApp.md` | **Cahier des charges complet** - Specifications fonctionnelles et techniques du CRM : modele de donnees (21 tables Dataverse), modules fonctionnels, maquettes, roadmap, deploiement. Sert de reference pour le developpement. |
| `setup-env.sh` | **Script de configuration** - Detecte automatiquement vos environnements Power Platform (via PAC CLI), collecte vos informations entreprise et genere un fichier `.env.project`. |
| `apply-env.sh` | **Script d'application** - Remplace les placeholders `{{VARIABLE}}` dans les documents par vos vraies valeurs depuis `.env.project`. |
| `.gitignore` | Protege `.env.project` et `.dataverse_token` (informations sensibles). |

---

## Pour qui ?

- **Consultants freelance** Power Platform / IA qui veulent un CRM sur-mesure
- **Developpeurs** React/TypeScript qui veulent decouvrir les Power Apps Code Apps
- **Utilisateurs de Claude Code** qui veulent un exemple de configuration anti-vibe-coding avec agents, hooks et quality gates

---

## Comment utiliser ce projet

### Etape 1 : Cloner et configurer

```bash
# Cloner le repo
git clone https://github.com/YOUR_USERNAME/CRM-PowerApps-CodeApp.git
cd CRM-PowerApps-CodeApp

# Lancer la configuration (detecte vos environnements Power Platform)
bash setup-env.sh

# Appliquer vos informations dans les documents
bash apply-env.sh
```

Le script `setup-env.sh` va :
- Verifier que PAC CLI est installe
- Lister vos environnements Power Platform (`pac env list`)
- Recuperer l'URL Dataverse automatiquement (`pac env who`)
- Vous demander vos informations entreprise (nom, SIREN, email, etc.)
- Generer un fichier `.env.project` (non commite sur git)

### Etape 2 : Creer le projet Power Apps Code App

```bash
# Creer le projet depuis le template officiel Microsoft
npx degit microsoft/PowerAppsCodeApps/templates/starter crm-freelance
cd crm-freelance
npm install

# Installer les dependances additionnelles
npm install zod react-hook-form @hookform/resolvers
npm install jspdf jspdf-autotable
npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities
```

### Etape 3 : Lancer le COWORK (setup .claude/)

Ouvrez Claude Code dans le dossier du projet et donnez-lui le fichier `COWORK_SETUP_CLAUDE_DIR_V2.md` :

```
Lis le fichier COWORK_SETUP_CLAUDE_DIR_V2.md et execute la mission :
cree le dossier .claude/ complet avec tous les fichiers decrits.
```

Claude Code va creer :

```
.claude/
  settings.json          # Permissions + hooks
  agents/
    enforcer.md          # Revieweur intransigeant (30+ points de controle)
    no-shortcut-dev.md   # Developpeur qui ne triche jamais
    architect.md         # Valide la structure et la coherence
    test-writer.md       # Expert tests (calculs financiers, regles metier)
  hooks/
    quality-gate.sh      # Bloque l'arret si le code n'est pas propre
    block-lazy-code.sh   # Bloque l'ecriture de code lazy (TODO, any, etc.)
  commands/
    review.md            # Commande /review pour lancer l'enforcer

CLAUDE.md                # Contraintes techniques du projet (racine)
```

### Etape 4 : Relancer Claude Code

**Important** : apres la creation du `.claude/`, quittez et relancez Claude Code pour qu'il prenne en compte la nouvelle configuration (hooks, agents, permissions).

### Etape 5 : Lancer le developpement avec le CDC

Donnez le CDC a Claude Code pour commencer le developpement :

```
Lis le fichier CDC_CRM_PowerApps_CodeApp.md.
C'est le cahier des charges complet du CRM.
Commence par la Phase 1 : Fondations.
```

Claude Code suivra le workflow impose par les agents :
1. **Comprendre** les regles metier (CDC)
2. **Planifier** avant de coder (plan ecrit)
3. **Typer** en premier (types TypeScript)
4. **Coder** avec les patterns obligatoires (Mock + Production + Proxy)
5. **Tester** avant de conclure (quality gate)

---

## Architecture du CRM

### Stack technique

| Couche | Technologie |
|---|---|
| Framework | Power Apps Code App |
| Frontend | React 19 + TypeScript 5.9 strict |
| Build | Vite 7 |
| UI | TailwindCSS v4 + shadcn/ui |
| State | Zustand v5 + Tanstack Query v5 |
| Tables | Tanstack Table v8 |
| Graphiques | Recharts |
| Formulaires | react-hook-form + Zod v4 |
| PDF | jsPDF + jspdf-autotable |
| Donnees | Dataverse (21 tables custom) |

### Modules fonctionnels

- **Entreprises** - CRUD complet + vue 360 degres client
- **Contacts** - Rattachement entreprise + decisionnaires
- **Affaires** - Pipeline Kanban avec drag and drop
- **Devis** - Editeur de lignes + calculs temps reel + generation PDF
- **Commandes** - Conversion depuis devis + pieces jointes
- **Factures** - Suivi paiements + statut automatique + PDF conforme
- **Activites** - Timeline chronologique + rattachement polymorphique
- **Dashboard** - KPIs + graphiques Recharts + cross-filtering style Power BI
- **Emails** - Templates avec variables + tracking + Power Automate
- **Automatisations** - Regles Trigger > Condition > Action configurables
- **Objectifs** - Barres de progression + gamification (trophees)
- **Import/Export** - CSV + parser LinkedIn
- **Audit trail** - Historique complet de toutes les modifications

### Modele de donnees (21 tables Dataverse)

```
Account ---1:N---> Contact
   |                  |
   +---1:N---> Deal <-+
                 |
                 +---1:N---> Quote ---1:N---> QuoteLine
                               |
                               +---> Order ---1:N---> OrderLine
                                       |
                                       +---> Invoice ---1:N---> InvoiceLine
                                               |
                                               +---1:N---> Payment

+ Activity, Task, EmailTemplate, EmailLog, WorkflowRule,
  WorkflowExecution, Goal, Achievement, AuditEntry,
  Numbering, Settings
```

---

## Configuration anti-vibe-coding

Ce projet inclut une configuration Claude Code en 3 couches de defense :

### Couche 1 : Hooks (bloquants)

- **block-lazy-code.sh** : intercepte chaque ecriture de fichier et bloque si `TODO`, `any`, `console.log`, `require()`, `process.env`, imports SDK incorrects
- **quality-gate.sh** : s'execute quand Claude veut s'arreter - bloque si TypeScript a des erreurs, si des tests echouent, ou si des patterns interdits subsistent

### Couche 2 : Agents (methodologiques)

- **no-shortcut-dev** : impose le workflow Comprendre > Planifier > Typer > Coder > Tester
- **enforcer** : review avec 20+ points bloquants specifiques Power Apps Code App
- **architect** : valide la coherence donnees/types/relations
- **test-writer** : couvre calculs financiers, transitions de statut, numerotation

### Couche 3 : Contraintes (CLAUDE.md)

- 13 pieges SDK documentes et a connaitre par coeur
- Pattern service obligatoire : Interface > Mock > Production > Proxy
- Calculs financiers avec arrondi 2 decimales
- Regles metier francaises (facture emise non supprimable, etc.)

---

## Variables a configurer

Les documents utilisent des placeholders `{{VARIABLE}}` pour les informations personnelles.
Le script `setup-env.sh` les collecte et `apply-env.sh` les applique.

| Variable | Description |
|---|---|
| `{{NOM_AUTEUR}}` | Nom complet du responsable du projet |
| `{{NOM_ENTREPRISE}}` | Raison sociale |
| `{{SIREN}}` | Numero SIREN (9 chiffres) |
| `{{EMAIL}}` | Email professionnel |
| `{{TELEPHONE}}` | Telephone |
| `{{ADRESSE}}` | Adresse complete |
| `{{SITE_WEB}}` | URL du site web |
| `{{URL_LOGO}}` | URL du logo (pour les PDF) |
| `{{URL_DATAVERSE}}` | URL de votre org Dataverse (ex: monorg.crm12.dynamics.com) |
| `{{MSAL_CLIENT_ID}}` | ID de l'application Azure AD pour l'auth MSAL |

---

## Prerequis

- **Node.js** 20+ (pas 24+ pour la compatibilite pac npm)
- **PAC CLI** (Power Apps CLI) : `winget install Microsoft.PowerAppsCLI`
- **Acces Power Platform** avec un environnement Dataverse
- **Claude Code** (recommande pour le developpement assiste)

---

## Licence

Ce projet est un template open-source. Utilisez-le librement pour creer votre propre CRM.

---

## Ressources

- [Power Apps Code Apps - Template officiel](https://github.com/microsoft/PowerAppsCodeApps)
- [Documentation officielle Code Apps](https://learn.microsoft.com/en-us/power-apps/developer/code-apps/)
- [Connexion Dataverse](https://learn.microsoft.com/en-us/power-apps/developer/code-apps/how-to/connect-to-dataverse)
- [PAC CLI Reference](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/code)

## À propos

Conçu et maintenu par [Kevin Tomas](https://www.custom-digital-services.com/?utm_source=github&utm_medium=readme&utm_campaign=crm-powerapps-codeapp), consultant freelance Power Platform et IA Microsoft (Custom Digital Services).
Projets Power Apps Code Apps : [www.custom-digital-services.com/expertises/architecture-power-platform](https://www.custom-digital-services.com/expertises/architecture-power-platform/?utm_source=github&utm_medium=readme&utm_campaign=crm-powerapps-codeapp). Autres outils gratuits : [www.custom-digital-services.com/outils](https://www.custom-digital-services.com/outils/?utm_source=github&utm_medium=readme&utm_campaign=crm-powerapps-codeapp)
