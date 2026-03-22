# MISSION COWORK : Creer le dossier .claude/ du projet CRM-Freelance

> **CONFIGURATION INITIALE REQUISE**
>
> Ce document contient des placeholders `{{VARIABLE}}` a la place des informations personnelles.
> Lancez `bash setup-env.sh` puis `bash apply-env.sh` pour les remplir automatiquement.
> Voir le CDC pour la liste complete des variables.

---

> Tu es dans le repertoire racine du projet CRM-Freelance (Power Apps Code App).
> Ta mission : creer le dossier `.claude/` complet avec TOUT ce qu'il faut
> pour que Claude Code travaille comme une equipe de developpeurs seniors.
> ZERO vibe coding. ZERO placeholder. ZERO raccourci.
>
> CE FICHIER CONTIENT 3 PARTIES :
> PARTIE A - Le contexte technique Power Apps Code App (pieges, patterns, Dataverse)
> PARTIE B - La configuration anti-vibe-coding (agents, hooks, settings)
> PARTIE C - Les fichiers a creer

---

# =========================================================

# PARTIE A - CONTEXTE TECHNIQUE POWER APPS CODE APP

# =========================================================

## A1. Ce que c'est

Une Power Apps Code App est une application React/TypeScript COMPLETE qui tourne
dans le runtime Power Platform. Ce n'est PAS un composant PCF, PAS une Canvas App,
PAS un projet React standalone.

- Template officiel : https://github.com/microsoft/PowerAppsCodeApps
- Doc officielle : https://learn.microsoft.com/en-us/power-apps/developer/code-apps/
- Doc connexion Dataverse : https://learn.microsoft.com/en-us/power-apps/developer/code-apps/how-to/connect-to-dataverse
- Doc connexion data sources : https://learn.microsoft.com/en-us/power-apps/developer/code-apps/how-to/connect-to-data
- CLI Reference pac code : https://powerappsguide.com/blog/post/pac-cli-code-commands-reference
- Repo GitHub issues : https://github.com/microsoft/PowerAppsCodeApps/issues
- Blog reference CRUD Dataverse : https://rajeevpentyala.com/2025/12/15/power-apps-code-app-with-dataverse-building-crud-operations/

## A2. Stack du template starter (mars 2026)

```
@microsoft/power-apps v1.0.4 (SDK)
@microsoft/power-apps-vite v1.0.2 (plugin Vite)
React 19 + TypeScript 5.9 strict + Vite 7
TailwindCSS v4 + shadcn/ui (New York, Radix UI)
Tanstack Query v5 + Tanstack Table v8
React Router v7 (BASENAME Power Apps - NE PAS TOUCHER)
Zustand v5, Recharts, Sonner, date-fns, lucide-react
```

Dependances additionnelles a installer :

```
npm install zod react-hook-form @hookform/resolvers
npm install jspdf jspdf-autotable
npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities
```

## A3. CONNEXION DATAVERSE (PAS SharePoint)

CE PROJET UTILISE DATAVERSE, PAS SHAREPOINT.
La commande pour Dataverse est DIFFERENTE de SharePoint.

### Commande Dataverse (simplifiee)

```bash
# Pour Dataverse, c'est plus simple que SharePoint :
pac code add-data-source -a dataverse -t <table-logical-name>

# Exemples concrets pour ce projet (21 tables) :
# --- Tables métier de base (14) ---
pac code add-data-source -a dataverse -t cds_accounts
pac code add-data-source -a dataverse -t cds_contacts
pac code add-data-source -a dataverse -t cds_deals
pac code add-data-source -a dataverse -t cds_quotes
pac code add-data-source -a dataverse -t cds_quote_lines
pac code add-data-source -a dataverse -t cds_orders
pac code add-data-source -a dataverse -t cds_order_lines
pac code add-data-source -a dataverse -t cds_invoices
pac code add-data-source -a dataverse -t cds_invoice_lines
pac code add-data-source -a dataverse -t cds_payments
pac code add-data-source -a dataverse -t cds_activities
pac code add-data-source -a dataverse -t cds_tasks
pac code add-data-source -a dataverse -t cds_numberings
pac code add-data-source -a dataverse -t cds_settings
# --- Tables features avancees (7) ---
pac code add-data-source -a dataverse -t cds_email_templates
pac code add-data-source -a dataverse -t cds_email_logs
pac code add-data-source -a dataverse -t cds_workflow_rules
pac code add-data-source -a dataverse -t cds_workflow_executions
pac code add-data-source -a dataverse -t cds_goals
pac code add-data-source -a dataverse -t cds_achievements
pac code add-data-source -a dataverse -t cds_audit_entries
```

### Ce que genere pac code add-data-source

La commande genere automatiquement :

- Un fichier Model TypeScript (ex: CdsAccountsModel.ts)
- Un fichier Service TypeScript (ex: CdsAccountsService.ts)
- NE PAS modifier ces fichiers directement (ils sont regeneres)
- Si le schema change : supprimer la data source et la re-ajouter

### Commande SharePoint (pour reference, PAS utilise ici)

```bash
# NE PAS UTILISER POUR CE PROJET - juste pour reference
pac code add-data-source --apiId "shared_sharepointonline" --connectionId "ID" --dataset "URL" --table "NomListe"
# PIEGE : apiId SANS slash initial, sinon erreur 404 double slash
```

### Utilisation des services generes (Dataverse)

```typescript
// Les services generes fournissent des methodes typees :
import { CdsAccountsService } from "./generated/CdsAccountsService";

// Lecture
const result = await CdsAccountsService.getAll({
  select: ["cds_name", "cds_siren", "cds_sector"],
  orderBy: ["cds_name asc"],
  top: 50,
});

// Creation
const newAccount = {
  cds_name: "RATP",
  cds_siren: "775663438",
  cds_sector: 775930000, // Choice = entier en Dataverse
};
await CdsAccountsService.create(newAccount);

// Mise a jour
await CdsAccountsService.update(accountId, { cds_name: "RATP Group" });

// Suppression
await CdsAccountsService.delete(accountId);
```

### Gestion des Lookups (FK) en Dataverse

Les lookups ne sont PAS encore simples dans les Code Apps.
Doc officielle : "A dedicated how-to guide is coming soon"
En attendant, pour associer un contact a une entreprise :

```typescript
// Utiliser la navigation property au format OData
const newContact = {
  cds_firstname: "Jean",
  cds_lastname: "Dupont",
  "cds_accountid@odata.bind": `/cds_accountses(${accountId})`,
};
await CdsContactsService.create(newContact);
```

### Gestion des Choice (enums) en Dataverse

Les Choice sont stockes comme des ENTIERS en Dataverse.
Il faut mapper entier <-> label dans le code TypeScript.

```typescript
// Dataverse stocke : 775930000 (entier)
// TypeScript affiche : "Services" (string)
const SECTOR_MAP: Record<number, string> = {
  775930000: "Services",
  775930001: "Industrie",
  775930002: "Pharma",
  // etc.
};
```

## A4. SDK @microsoft/power-apps - PIEGES CRITIQUES

### PIEGE 1 : PAS de root export

```typescript
// Le SDK declare dans son package.json :
"exports": {
  "./app": { "import": "./lib/app/index.js" },
  "./data": { "import": "./lib/data/index.js" },
  "./data/executors": { "import": "./lib/data/executors/index.js" },
  "./telemetry": { "import": "./lib/telemetry/index.js" }
}
// PAS de "." = import depuis '@microsoft/power-apps' NE FONCTIONNE PAS

// CORRECT :
const { getClient } = await import('@microsoft/power-apps/data');
// INCORRECT :
import { data } from '@microsoft/power-apps'; // ERREUR
```

### PIEGE 2 : NE PAS mettre le SDK en external dans Vite

```typescript
// Le runtime Power Apps ne fournit PAS le SDK comme global
// INCORRECT :
build: {
  rollupOptions: {
    external: ["@microsoft/power-apps"];
  }
}
// CORRECT : ne rien mettre, laisser Vite bundler le SDK
```

### PIEGE 3 : CSP bloque eval/require/new Function

```typescript
// Power Apps applique une Content Security Policy stricte
// INTERDIT : eval(), new Function(), require()
// Si une lib utilise eval() en interne, elle ne fonctionnera pas
```

### PIEGE 4 : Import dynamique lazy obligatoire pour le SDK

```typescript
// Le SDK doit etre charge de maniere paresseuse (lazy)
// car il n'est disponible que dans le runtime Power Apps

class ProductionDataverseService {
  private client: any;
  private initialized = false;

  private async ensureClient(): Promise<void> {
    if (this.initialized) return;
    // @ts-expect-error - Power Apps SDK types resolved at runtime
    const { getClient } = await import("@microsoft/power-apps/data");
    this.client = getClient(dataSourcesInfo);
    this.initialized = true;
  }

  async getAccounts() {
    await this.ensureClient();
    return this.client.retrieveMultipleRecordsAsync("cds_accounts");
  }
}
```

### PIEGE 5 : Mapping PascalCase (Dataverse) <-> camelCase (TypeScript)

```typescript
// Dataverse utilise le nom logique des colonnes (snake_case avec prefixe)
// MAIS les champs systeme sont en PascalCase

// LECTURE : Dataverse -> TypeScript
private mapToAccount(record: Record<string, unknown>): Account {
  return {
    id: String(record.cds_accountid ?? ''),
    name: String(record.cds_name ?? ''),
    siren: String(record.cds_siren ?? ''),
    sector: Number(record.cds_sector ?? 0),
    // Champs systeme en PascalCase
    createdOn: String(record.createdon ?? ''),
    modifiedOn: String(record.modifiedon ?? ''),
  };
}

// ECRITURE : TypeScript -> Dataverse
private mapFromAccount(account: AccountInput): Record<string, unknown> {
  return {
    cds_name: account.name,
    cds_siren: account.siren,
    cds_sector: account.sector,
  };
}
```

### PIEGE 6 : Enums sans accents dans les types TS

```typescript
// Les accents posent probleme a la serialisation Dataverse
// CORRECT : types SANS accents, labels AVEC accents
type DealStatus =
  | "Prospect"
  | "Qualification"
  | "Proposition"
  | "Negociation"
  | "Gagne"
  | "Perdu";

const STATUS_LABELS: Record<DealStatus, string> = {
  Negociation: "Negociation",
  Gagne: "Gagne",
};
```

### PIEGE 7 : verbatimModuleSyntax (TypeScript 5.9 strict)

```typescript
// CORRECT :
import type { Account, DealStatus } from "@/lib/types";
// INCORRECT (erreur TS) :
import { Account, DealStatus } from "@/lib/types";
```

### PIEGE 8 : JSX.Element comme return type

```typescript
// CORRECT : laisser inferer
export function Dashboard() { return <div>...</div>; }
// INCORRECT : namespace JSX introuvable
export function Dashboard(): JSX.Element { ... }
```

### PIEGE 9 : import.meta.env (pas process.env)

```typescript
// Vite utilise import.meta.env, PAS process.env
if (import.meta.env.DEV) {
  /* mode dev */
}
const url = import.meta.env.VITE_PA_SEND_QUOTE_URL;
```

### PIEGE 10 : Dark mode non voulu

```typescript
// Power Apps peut heriter du mode sombre de l'OS
// TOUJOURS forcer le mode light :
<ThemeProvider defaultTheme="light">
```

### PIEGE 11 : BASENAME React Router

```typescript
// Le template starter configure un BASENAME specifique a Power Apps
// NE JAMAIS le modifier, NE JAMAIS le supprimer
// React Router v7 gere ca automatiquement via le template
```

### PIEGE 12 : Champs auto-generes Dataverse

```
// Dataverse genere automatiquement :
// createdon (pas createdAt)
// modifiedon (pas modifiedAt)
// statecode (actif/inactif)
// statuscode (sous-statut)
// versionnumber
// NE PAS tenter de les ecrire dans un create/update
```

### PIEGE 13 : Pagination Dataverse

```typescript
// Dataverse retourne max 5000 records par requete
// Utiliser skipToken pour paginer :
const page1 = await service.getAll({ top: 50 });
const page2 = await service.getAll({ top: 50, skipToken: page1.skipToken });
```

## A5. Pattern Service (Mock + Production + Proxy)

### REGLE CRITIQUE : utiliser les services generes

Les ProductionService DOIVENT utiliser les services generes dans `src/generated/services/`.
NE JAMAIS utiliser `getClient()` manuellement.

```typescript
// CORRECT
import { Cds_accountsService } from '../../generated/services/Cds_accountsService';
const result = await Cds_accountsService.getAll({ select: [...], top: 100 });
const data = result.data || [];

// INCORRECT - NE PAS FAIRE
const { getClient } = await import('@microsoft/power-apps/data');
const client = getClient(dataSourcesInfo);
const result = await client.retrieveMultipleRecords('cds_accounts', '?$select=...');
```

Ref doc officielle : https://learn.microsoft.com/en-us/power-apps/developer/code-apps/how-to/connect-to-dataverse
Ref sample : https://github.com/microsoft/PowerAppsCodeApps/tree/main/samples/Dataverse

CHAQUE service du projet DOIT suivre ce pattern :

```typescript
// 1. Interface (contrat)
interface AccountService {
  getAll(options?: QueryOptions): Promise<Account[]>;
  getById(id: string): Promise<Account | null>;
  create(input: AccountInput): Promise<Account>;
  update(id: string, input: Partial<AccountInput>): Promise<Account>;
  delete(id: string): Promise<void>;
}

// 2. MockService (donnees realistes en memoire, 200ms delay)
class MockAccountService implements AccountService {
  private accounts: Account[] = [
    { id: '1', name: 'RATP', siren: '775663438', sector: 'BTP', ... },
    { id: '2', name: 'Sanofi', siren: '395030844', sector: 'Pharma', ... },
  ];

  async getAll(): Promise<Account[]> {
    await new Promise(r => setTimeout(r, 200));
    return [...this.accounts];
  }
  // ... toutes les methodes implementees avec des vrais noms/donnees
}

// 3. ProductionService (SDK Power Apps, import dynamique)
class ProductionAccountService implements AccountService {
  private client: unknown;
  private initialized = false;

  private async ensureClient(): Promise<void> {
    if (this.initialized) return;
    // @ts-expect-error - Power Apps SDK types resolved at runtime
    const { getClient } = await import('@microsoft/power-apps/data');
    this.client = getClient(dataSourcesInfo);
    this.initialized = true;
  }

  async getAll(options?: QueryOptions): Promise<Account[]> {
    await this.ensureClient();
    const result = await (this.client as DataClient).retrieveMultipleRecordsAsync(
      'cds_accounts',
      { select: ['cds_name', 'cds_siren', ...], top: options?.limit ?? 50 }
    );
    return result.data.map(this.mapToAccount);
  }

  // Mapping Dataverse -> TypeScript dans CHAQUE methode
  private mapToAccount(record: Record<string, unknown>): Account { ... }
  private mapFromAccount(input: AccountInput): Record<string, unknown> { ... }
}

// 4. Proxy intelligent (auto-fallback)
function createAccountService(): AccountService {
  if (import.meta.env.DEV) return new MockAccountService();

  const prod = new ProductionAccountService();
  const mock = new MockAccountService();
  let useMock = false;

  return new Proxy(prod, {
    get(target, prop, receiver) {
      if (useMock) return Reflect.get(mock, prop, receiver);
      const value = Reflect.get(target, prop, receiver);
      if (typeof value === 'function') {
        return async (...args: unknown[]) => {
          try {
            return await value.apply(target, args);
          } catch (error) {
            console.warn('[DV] SDK failed, falling back to mock:', error);
            useMock = true;
            const fn = Reflect.get(mock, prop, receiver);
            return typeof fn === 'function' ? fn.apply(mock, args) : undefined;
          }
        };
      }
      return value;
    },
  }) as AccountService;
}

export const accountService = createAccountService();
```

## A6. Auth Provider (pattern qui fonctionne)

```typescript
// 1. Recuperer l'email : try window.__POWER_APPS_CONTEXT__, fallback hardcode pour dev
// 2. Charger le user depuis Dataverse (cds_settings ou table users)
// 3. Stocker dans Zustand (user-store)
// 4. Afficher Skeleton pendant le chargement
// 5. Children rendus UNIQUEMENT quand user est charge
```

## A7. Commandes de deploiement

```bash
# Verifier l'environnement
pac env who

# Selectionner si necessaire
pac env list
pac env select --environment GUID

# Init (premiere fois seulement)
pac code init --displayName "CRM Freelance" --description "CRM suivi affaires" --buildPath "dist" --fileEntryPoint "index.html"

# Ajouter les data sources (premiere fois - 21 tables)
pac code add-data-source -a dataverse -t cds_accounts
pac code add-data-source -a dataverse -t cds_contacts
pac code add-data-source -a dataverse -t cds_deals
pac code add-data-source -a dataverse -t cds_quotes
pac code add-data-source -a dataverse -t cds_quote_lines
pac code add-data-source -a dataverse -t cds_orders
pac code add-data-source -a dataverse -t cds_order_lines
pac code add-data-source -a dataverse -t cds_invoices
pac code add-data-source -a dataverse -t cds_invoice_lines
pac code add-data-source -a dataverse -t cds_payments
pac code add-data-source -a dataverse -t cds_activities
pac code add-data-source -a dataverse -t cds_tasks
pac code add-data-source -a dataverse -t cds_numberings
pac code add-data-source -a dataverse -t cds_settings
pac code add-data-source -a dataverse -t cds_email_templates
pac code add-data-source -a dataverse -t cds_email_logs
pac code add-data-source -a dataverse -t cds_workflow_rules
pac code add-data-source -a dataverse -t cds_workflow_executions
pac code add-data-source -a dataverse -t cds_goals
pac code add-data-source -a dataverse -t cds_achievements
pac code add-data-source -a dataverse -t cds_audit_entries

# Build + Deploy (a chaque modification)
npm run build && pac code push

# L'app apparait dans make.powerapps.com > Mes applications
# Cliquer "Lire" (Play) pour lancer, PAS "Modifier"
```

## A8. Erreurs connues et solutions

| Erreur                                             | Cause                                               | Solution                                                          |
| -------------------------------------------------- | --------------------------------------------------- | ----------------------------------------------------------------- |
| `CodeAppOperationNotAllowedInEnvironment`          | Code Apps pas active                                | Admin Center > Settings > Features > activer toggle               |
| `Missing "." specifier in "@microsoft/power-apps"` | Pas de root export                                  | Importer `@microsoft/power-apps/data` pas `@microsoft/power-apps` |
| `CSP eval blocked`                                 | `new Function()` ou `eval()`                        | Ne JAMAIS utiliser require(), new Function(), eval()              |
| `404 double slash //providers/...`                 | apiId commence par `/`                              | Utiliser le nom court sans slash                                  |
| `SDK not found / fallback to mock`                 | Import dynamique echoue                             | Verifier `await import('@microsoft/power-apps/data')`             |
| `createUser failed`                                | Champs en camelCase                                 | Mapper vers les noms logiques Dataverse                           |
| `power.config.json missing`                        | `pac code init` pas execute                         | Lancer pac code init                                              |
| `connection list vide`                             | `pac connection list` montre que les connexions CLI | Creer la connexion dans make.powerapps.com                        |
| `Theme dark / fond noir`                           | OS en dark mode                                     | Forcer `defaultTheme="light"`                                     |
| `Data source not found`                            | entitySetName incorrect                             | Supprimer et re-ajouter la data source (pac 1.50.1+)              |
| `Request failed: {}`                               | Connexion SharePoint au lieu de Dataverse           | Utiliser `-a dataverse -t nom_table`                              |
| `MODULE_NOT_FOUND` (macOS)                         | Espaces dans le chemin                              | Deplacer le projet dans un chemin sans espaces                    |
| Pages 404 en navigation directe                    | SPA fallback                                        | Ne pas toucher `appType: 'spa'` dans Vite                         |

### Erreurs mapping Dataverse

| Erreur                                   | Cause                                     | Solution                                                                                    |
| ---------------------------------------- | ----------------------------------------- | ------------------------------------------------------------------------------------------- |
| Choice field rejete par Dataverse        | Envoi de 'Actif' au lieu de 144950000     | Utiliser enum-mappings.ts : toInt(MAP, value) pour ecriture, toStr(MAP, value) pour lecture |
| Proxy bascule sur Mock definitivement    | `useMock = true` permanent apres 1 erreur | Retirer le flag sticky, retry Production a chaque appel                                     |
| Donnees test qui apparaissent brievement | Fallback Mock silencieux                  | Ajouter console.error dans le catch du proxy pour diagnostic                                |

### Erreurs Dataverse deployment

| Erreur                                      | Cause                        | Solution                                                                     |
| ------------------------------------------- | ---------------------------- | ---------------------------------------------------------------------------- |
| XML import "PrimaryName not found"          | Customizations.xml artisanal | Utiliser Web API POST /EntityDefinitions                                     |
| Labels rejetes "language code not valid"    | Mauvais LanguageCode         | Verifier la langue de l'env (1036=FR, 1033=EN)                               |
| Lookup "Invalid property ReferencingEntity" | JSON incomplet               | @odata.type OneToManyRelationshipMetadata + ReferencedAttribute obligatoires |

### Erreurs TypeScript build

| Erreur                                 | Cause                           | Solution                                   |
| -------------------------------------- | ------------------------------- | ------------------------------------------ |
| Recharts onClick handler type mismatch | Vite build plus strict que tsc  | Cast handler ou wrapper type               |
| Zod v4 resolver `unknown` vs `number`  | zodResolver incompatible Zod v4 | Utiliser standardSchemaResolver            |
| tsc OK mais vite build FAIL            | Vite verifie les generic types  | TOUJOURS npm run build avant pac code push |

### Erreur services Dataverse

| Erreur                                    | Cause                                                              | Solution                                                       |
| ----------------------------------------- | ------------------------------------------------------------------ | -------------------------------------------------------------- |
| Donnees mock en production Power Apps     | ProductionService utilise getClient() au lieu des services generes | Utiliser Cds_xxxService depuis src/generated/services/         |
| result.entities undefined                 | Mauvaise API (retrieveMultipleRecords vs getAll)                   | Utiliser result.data (API des services generes)                |
| `retrieveMultipleRecords()` crash runtime | Methode inventee, n'existe pas dans le SDK Code Apps               | Utiliser `getAll()` du service genere (Cds_xxxService)         |
| `power.config.json` ignore                | Les noms de tables/data sources y sont definis                     | Consulter `databaseReferences` pour les noms exacts des tables |

### Erreurs ZIP solution Dataverse

| Erreur                                                     | Cause                                                  | Solution                                                               |
| ---------------------------------------------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------- |
| Import solution echoue (ZIP invalide)                      | `[Content_Types].xml` absent du ZIP                    | Le fichier DOIT etre nomme avec crochets et present a la racine du ZIP |
| PowerShell `Compress-Archive` ignore `[Content_Types].xml` | PowerShell interprete les crochets comme des wildcards | Utiliser Python `zipfile` ou 7-Zip pour creer le ZIP                   |
| Structure ZIP incorrecte                                   | ZIP cree sans la bonne hierarchie                      | Utiliser `pac solution init` pour creer une structure valide           |

### Erreurs TypeScript supplementaires

| Erreur                                      | Cause                                        | Solution                                                                   |
| ------------------------------------------- | -------------------------------------------- | -------------------------------------------------------------------------- |
| `@ts-expect-error` masque de vraies erreurs | Commentaire laisse apres installation du SDK | Supprimer `@ts-expect-error` une fois les types resolus                    |
| `createServiceProxy<T>` sans generic        | Mock pas assignable a Production             | Toujours specifier le generic : `createServiceProxy<IAccountService>(...)` |

### REGLE BUILD OBLIGATOIRE

```bash
# CORRECT : valider avec le vrai build
npm run build && pac code push

# INCORRECT : tsc ne suffit PAS
npx tsc --noEmit  # peut passer alors que vite build echoue
```

## A9. Si Claude Code est bloque

### Le SDK ne se charge pas en local

C'est NORMAL. Le SDK `@microsoft/power-apps/data` ne fonctionne que dans le runtime Power Apps.
En dev local (`npm run dev`), le Proxy redirige automatiquement vers le MockService.
Ne PAS tenter de "fixer" le SDK en local.

### Les types generes ne correspondent pas au schema

Supprimer la data source et la re-ajouter :

```bash
pac code delete-data-source -a dataverse -ds cds_accounts
pac code add-data-source -a dataverse -t cds_accounts
```

### Erreur "Request failed" sur add-data-source

Verifier :

1. `pac env who` - es-tu connecte au bon environnement ?
2. La table existe-t-elle dans Dataverse ? (verifier make.powerapps.com > Tables)
3. Le nom logique est-il correct ? (pas le display name, le logical name)

### Le build echoue mais le dev fonctionne

Verifier :

1. `npx tsc --noEmit` pour les erreurs TypeScript
2. Pas de `require()`, `eval()`, `new Function()` dans le code
3. Pas d'import direct `@microsoft/power-apps` (utiliser /data ou /app)

---

## A10. Solution Dataverse - Creation et controle de coherence

### Etape 0 : Verifier la langue de l'environnement

OBLIGATOIRE AVANT tout deploiement. L'API Dataverse rejette les labels
avec un code langue non installe dans l'organisation.

```bash
# Verifier la langue via le Web API
# FR = 1036, EN = 1033
curl -H "Authorization: Bearer $TOKEN" \
  "https://{{URL_DATAVERSE}}/api/data/v9.2/RetrieveInstalledLanguagePacks"

# Ou verifier dans make.powerapps.com > Parametres > Langues
```

ERREUR VECUE : Deploiement avec LanguageCode 1033 sur un environnement FR
= TOUTES les colonnes rejetees avec "The language code 1033 is not a valid language".
Solution : utiliser LanguageCode 1036.

### Etape 1 : Creer les tables via le Web API (methode recommandee)

NE PAS utiliser de XML Customizations.xml artisanal. Le format n'est pas documente
et l'import echoue systematiquement ("PrimaryName attribute not found").

La methode fiable est le script Python `deploy_dataverse_tables.py` qui utilise
le Web API officiel Dataverse :

- POST /api/data/v9.2/EntityDefinitions (creation tables)
- POST /EntityDefinitions(LogicalName='table')/Attributes (ajout colonnes)
- POST /api/data/v9.2/RelationshipDefinitions (creation lookups)

```bash
# Prerequis
pip install msal requests

# Authentification (device code flow - une seule fois)
python -c "
import msal
app = msal.PublicClientApplication('{{MSAL_CLIENT_ID}}',
    authority='https://login.microsoftonline.com/organizations')
flow = app.initiate_device_flow(scopes=['https://{{URL_DATAVERSE}}/.default'])
print('Code:', flow['user_code'], '-> https://microsoft.com/devicelogin')
result = app.acquire_token_by_device_flow(flow)
open('.dataverse_token', 'w').write(result['access_token'])
print('Token saved')
"

# Deployer les 21 tables
python deploy_dataverse_tables.py
```

Le script est idempotent : si une table existe deja, il continue avec les colonnes.

### Etape 2 : Controle de coherence Code <-> Dataverse

AVANT de deployer la Code App, verifier la coherence :

```bash
# Verification rapide : lister toutes les colonnes Dataverse dans les services
grep -r "record\['" src/lib/services/*-service.ts | grep "cds_" | sort -u

# Verifier que chaque colonne existe dans Customizations.xml
# Chaque nom comme cds_account_name, cds_deal_name etc. doit avoir
# un <attribute PhysicalName="cds_..."> correspondant
```

**Matrice de coherence obligatoire :**

| Service          | Table(s) Dataverse                          | Colonnes denormalisees                                                                |
| ---------------- | ------------------------------------------- | ------------------------------------------------------------------------------------- |
| account-service  | cds_accounts                                | -                                                                                     |
| contact-service  | cds_contacts                                | cds_account_name                                                                      |
| deal-service     | cds_deals                                   | cds_account_name, cds_contact_name                                                    |
| quote-service    | cds_quotes                                  | cds_deal_name, cds_account_name, cds_contact_name                                     |
| order-service    | cds_orders                                  | cds_deal_name, cds_account_name, cds_contact_name                                     |
| invoice-service  | cds_invoices                                | cds_deal_name, cds_account_name, cds_contact_name, cds_order_number, cds_quote_number |
| email-service    | cds_email_templates, cds_email_logs         | -                                                                                     |
| workflow-service | cds_workflow_rules, cds_workflow_executions | cds_rule_name                                                                         |
| goals-service    | cds_goals, cds_achievements                 | -                                                                                     |
| audit-service    | cds_audit_entries                           | -                                                                                     |

### Etape 3 : Bonnes pratiques solution

- Solution TOUJOURS non managee (Managed=2 dans Solution.xml = Both)
- Prefixe publisher : `cds_` (OptionValuePrefix: 14495)
- NE JAMAIS modifier les fichiers generes par `pac code add-data-source`
- Tester l'import dans un env DEV avant la production
- Apres modification du schema : re-exporter la solution depuis make.powerapps.com
- Versionner les fichiers XML de la solution dans git
- `pac solution init` cree la structure de solution valide (Solution.xml, [Content_Types].xml)
- NE JAMAIS utiliser PowerShell `Compress-Archive` pour zipper une solution (ignore `[Content_Types].xml`)
- Utiliser Python `zipfile` ou 7-Zip pour creer le ZIP de solution
- `power.config.json` contient les `databaseReferences` = source de verite pour les noms de tables

### Etape 4 : Colonnes denormalisees - pourquoi

Les services stockent `cds_account_name` en plus de `cds_account_id` (lookup).
Raison : le SDK Power Apps Code Apps ne supporte pas facilement `$expand` OData.
Le nom est peuple au create/update par le service TypeScript.
Si le nom source change, la denormalisation n'est PAS mise a jour auto.
Compromis acceptable pour un CRM mono-utilisateur.

### Etape 5 : Erreurs connues et solutions Dataverse

| Erreur                               | Cause                                    | Solution                                                                       |
| ------------------------------------ | ---------------------------------------- | ------------------------------------------------------------------------------ |
| `language code 1033 is not valid`    | Env FR, labels en anglais                | Utiliser LanguageCode 1036                                                     |
| `PrimaryName attribute not found`    | XML Customizations.xml artisanal         | Utiliser le Web API, pas le XML                                                |
| `Invalid property ReferencingEntity` | Format JSON lookup incomplet             | Ajouter `@odata.type: OneToManyRelationshipMetadata` + `ReferencedAttribute`   |
| `schema name already exists`         | Table deja creee                         | Script idempotent, ignorer et continuer                                        |
| ZIP solution invalide a l'import     | `[Content_Types].xml` absent du ZIP      | PowerShell `Compress-Archive` ignore les crochets, utiliser Python `zipfile`   |
| Structure ZIP non reconnue           | Pas de `[Content_Types].xml` a la racine | Utiliser `pac solution init` pour creer la structure, ou verifier manuellement |
| Token expire                         | Session MSAL expiree                     | Relancer l'auth device code                                                    |

### REGLE ABSOLUE : en cas de doute ou d'echec sur Dataverse

1. STOPPER toute improvisation
2. Consulter la doc officielle Microsoft :
   - Tables : https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/create-update-entity-definitions-using-web-api
   - Relations : https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/create-update-entity-relationships-using-web-api
   - Colonnes : https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/create-update-column-definitions-using-web-api
3. Utiliser Context7 : `/websites/learn_microsoft_en-us_power-apps`
4. NE JAMAIS inventer un format XML ou JSON pour Dataverse

---

# =========================================================

# PARTIE B - CONFIGURATION ANTI-VIBE-CODING

# =========================================================

## B1. Philosophie

3 couches de defense :

```
COUCHE 1 : HOOKS (deterministe, impossible a contourner)
  block-lazy-code.sh intercepte CHAQUE ecriture de fichier
  Si TODO, any, console.log, eval, require : ECRITURE BLOQUEE
  Claude ne peut meme pas ecrire du code sale

COUCHE 2 : QUALITY GATE (deterministe, impossible a contourner)
  quality-gate.sh s'execute quand Claude veut s'arreter
  Si tsc echoue, tests echouent, patterns interdits : ARRET BLOQUE
  Claude est FORCE de corriger avant de conclure

COUCHE 3 : AGENTS (methodologique, force la rigueur)
  no-shortcut-dev : workflow obligatoire (comprendre > planifier > typer > coder > tester)
  enforcer : review sans pitie, checklist 30+ points specifiques Power Apps Code App
  architect : valide la structure avant toute modif
  test-writer : couvre les calculs financiers et regles metier
```

Les hooks sont les MURS (impossible de passer).
Les agents sont la DISCIPLINE (impossible de tricher).

## B2. Regle d'auto-amelioration (OBLIGATOIRE)

Claude Code DOIT s'auto-ameliorer apres chaque erreur ou apprentissage :

1. **IDENTIFIER** : chaque erreur, piege, ou nouvelle connaissance
2. **DOCUMENTER** : ajouter dans le CDC (section 9.1 ou 10) + COWORK (section A8)
3. **MEMORISER** : sauvegarder en memoire feedback pour les sessions futures
4. **INTEGRER** : mettre a jour les agents/skills concernes
5. **VERIFIER** : s'assurer que l'erreur ne se reproduit pas

Format standard pour documenter une erreur :

```
| Erreur | Cause | Solution |
|---|---|---|
| Description du probleme | Pourquoi ca a echoue | Comment corriger |
```

### Quand appliquer cette regle :

- Apres un echec de build (TS, Vite, pac code push)
- Apres un echec de deploiement (Dataverse, Power Apps)
- Apres avoir decouvert un piege technique
- Apres avoir improvise et echoue (= consulter la doc officielle)
- Apres avoir corrige un bug non trivial

### REGLE ABSOLUE en cas de doute ou d'echec :

1. STOPPER toute improvisation
2. Consulter la doc officielle (Context7, Microsoft Learn, blogs references)
3. Appliquer la solution documentee
4. Documenter la solution pour la prochaine fois

---

# =========================================================

# PARTIE C - FICHIERS A CREER

# =========================================================

## Structure cible

```
.claude/
├── settings.json
├── agents/
│   ├── enforcer.md
│   ├── no-shortcut-dev.md
│   ├── architect.md
│   └── test-writer.md
├── hooks/
│   ├── quality-gate.sh
│   └── block-lazy-code.sh
└── commands/
    └── review.md
```

---

## FICHIER 1 : .claude/settings.json

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Edit",
      "Write",
      "Bash(npm run *)",
      "Bash(npm install *)",
      "Bash(npm test *)",
      "Bash(npx tsc *)",
      "Bash(npx vitest *)",
      "Bash(npx prettier *)",
      "Bash(npx eslint *)",
      "Bash(npx degit *)",
      "Bash(pac *)",
      "Bash(node -e *)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git checkout *)",
      "Bash(git branch *)",
      "Bash(git log *)",
      "Bash(cat *)",
      "Bash(ls *)",
      "Bash(find *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(wc *)",
      "Bash(grep *)",
      "Bash(mkdir *)",
      "Bash(chmod *)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(git push --force *)",
      "Bash(git push -f *)",
      "Bash(DROP *)",
      "Bash(DELETE FROM *)",
      "Bash(curl * | sh)",
      "Bash(curl * | bash)",
      "Bash(wget * | sh)",
      "Bash(eval *)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/block-lazy-code.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npx prettier --write \"$CLAUDE_FILE_PATH\" 2>/dev/null; exit 0"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/quality-gate.sh"
          }
        ]
      }
    ]
  }
}
```

---

## FICHIER 2 : .claude/hooks/quality-gate.sh

```bash
#!/bin/bash
# ============================================================
# QUALITY GATE - CRM Freelance (Power Apps Code App)
# Claude Code ne peut PAS s'arreter tant que ce gate est rouge
# ============================================================

ERRORS=""

# 1. TypeScript strict - zero erreur toleree
TS_OUTPUT=$(npx tsc --noEmit 2>&1)
if [ $? -ne 0 ]; then
  ERRORS="$ERRORS\n\n=== ERREURS TYPESCRIPT ===\n$(echo "$TS_OUTPUT" | head -40)"
fi

# 2. Tests Vitest - tous doivent passer
if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
  TEST_OUTPUT=$(npx vitest run --reporter=verbose 2>&1 | tail -40)
  if echo "$TEST_OUTPUT" | grep -qE "FAIL|failed|Error"; then
    ERRORS="$ERRORS\n\n=== TESTS EN ECHEC ===\n$TEST_OUTPUT"
  fi
fi

# 3. Scan patterns interdits specifiques Power Apps Code App
MODIFIED=$(git diff --name-only --diff-filter=ACMR HEAD 2>/dev/null | grep -E '\.(ts|tsx)$')
if [ -n "$MODIFIED" ]; then
  for f in $MODIFIED; do
    if [ -f "$f" ]; then
      # TODO/FIXME restants
      TODOS=$(grep -n -E 'TODO|FIXME|HACK|XXX|PLACEHOLDER' "$f" 2>/dev/null)
      [ -n "$TODOS" ] && ERRORS="$ERRORS\n\n=== TODO/FIXME dans $f ===\n$TODOS"

      # any (sauf fichiers .d.ts)
      if ! echo "$f" | grep -qE '\.d\.ts$'; then
        ANYS=$(grep -n -E ': any[^A-Za-z]|as any' "$f" 2>/dev/null)
        [ -n "$ANYS" ] && ERRORS="$ERRORS\n\n=== ANY dans $f ===\n$ANYS"
      fi

      # Import direct @microsoft/power-apps (PIEGE 1)
      BAD_SDK=$(grep -n "from '@microsoft/power-apps'" "$f" 2>/dev/null)
      [ -n "$BAD_SDK" ] && ERRORS="$ERRORS\n\n=== IMPORT SDK INTERDIT dans $f ===\n$BAD_SDK\nUtiliser @microsoft/power-apps/data ou /app"

      # eval() / new Function() / require() (PIEGE 3)
      FORBIDDEN=$(grep -n -E 'eval\(|new Function\(|require\(' "$f" 2>/dev/null)
      [ -n "$FORBIDDEN" ] && ERRORS="$ERRORS\n\n=== CSP INTERDIT dans $f ===\n$FORBIDDEN"

      # process.env (PIEGE 9)
      BAD_ENV=$(grep -n 'process\.env' "$f" 2>/dev/null)
      [ -n "$BAD_ENV" ] && ERRORS="$ERRORS\n\n=== process.env INTERDIT dans $f ===\n$BAD_ENV\nUtiliser import.meta.env"

      # JSX.Element return type (PIEGE 8)
      BAD_JSX=$(grep -n ': JSX\.Element' "$f" 2>/dev/null)
      [ -n "$BAD_JSX" ] && ERRORS="$ERRORS\n\n=== JSX.Element INTERDIT dans $f ===\n$BAD_JSX\nLaisser inferer le type de retour"

      # rollupOptions external power-apps (PIEGE 2)
      BAD_EXTERNAL=$(grep -n "external.*power-apps" "$f" 2>/dev/null)
      [ -n "$BAD_EXTERNAL" ] && ERRORS="$ERRORS\n\n=== SDK EN EXTERNAL INTERDIT dans $f ===\n$BAD_EXTERNAL"

      # Fichier squelette (< 5 lignes = vibe coding de facade)
      LINES=$(wc -l < "$f")
      [ "$LINES" -lt 5 ] && ERRORS="$ERRORS\n\n=== FICHIER SQUELETTE $f ($LINES lignes) ===\nImplemente completement."
    fi
  done
fi

if [ -n "$ERRORS" ]; then
  echo -e "BLOQUANT : Tu ne peux pas t'arreter. Le code n'est pas propre.\n$ERRORS"
  echo ""
  echo "Corrige TOUTES les erreurs ci-dessus avant de conclure."
  echo "Ne dis pas 'je vais corriger plus tard'. Corrige MAINTENANT."
fi
```

---

## FICHIER 3 : .claude/hooks/block-lazy-code.sh

```bash
#!/bin/bash
# ============================================================
# BLOCK LAZY CODE - CRM Freelance (Power Apps Code App)
# Intercepte chaque Write et bloque le vibe coding
# Inclut les pieges specifiques Power Apps Code App
# ============================================================

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

[ -z "$FILE_PATH" ] && echo '{"decision": "allow"}' && exit 0

# Ne verifier que les fichiers code
echo "$FILE_PATH" | grep -qE '\.(ts|tsx|js|jsx)$' || { echo '{"decision": "allow"}'; exit 0; }

CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.file_text // .tool_input.new_str // empty' 2>/dev/null)

[ -z "$CONTENT" ] && echo '{"decision": "allow"}' && exit 0

IS_TEST=0
echo "$FILE_PATH" | grep -qE '(test|spec|__tests__|\.test\.|\.spec\.)' && IS_TEST=1

VIOLATIONS=""

# === BLOQUANTS UNIVERSELS ===

echo "$CONTENT" | grep -qiE 'TODO|FIXME|HACK|XXX|PLACEHOLDER|implement later|a implementer|not implemented' && \
  VIOLATIONS="$VIOLATIONS\n- TODO/FIXME/PLACEHOLDER detecte. Code COMPLET ou rien."

echo "$CONTENT" | grep -qE ': any[^A-Za-z]|as any|@ts-ignore' && \
  VIOLATIONS="$VIOLATIONS\n- any/@ts-ignore interdit. Type avec unknown + type guard."

echo "$CONTENT" | grep -qE "require\(" && \
  VIOLATIONS="$VIOLATIONS\n- require() interdit (CSP Power Apps). Utilise import ESM."

echo "$CONTENT" | grep -qE 'eval\(|new Function\(' && \
  VIOLATIONS="$VIOLATIONS\n- eval()/new Function() interdit (CSP Power Apps)."

echo "$CONTENT" | grep -qE 'process\.env' && \
  VIOLATIONS="$VIOLATIONS\n- process.env interdit. Utilise import.meta.env."

echo "$CONTENT" | grep -qE "from ['\"]@microsoft/power-apps['\"]" && \
  VIOLATIONS="$VIOLATIONS\n- Import @microsoft/power-apps interdit (pas de root export). Utilise /data ou /app."

echo "$CONTENT" | grep -qE ': JSX\.Element' && \
  VIOLATIONS="$VIOLATIONS\n- JSX.Element interdit comme return type. Laisser inferer."

echo "$CONTENT" | grep -qE "external.*power-apps" && \
  VIOLATIONS="$VIOLATIONS\n- @microsoft/power-apps en rollupOptions.external interdit. Le runtime PA ne fournit pas le SDK en global."

# === BLOQUANTS CODE PROD UNIQUEMENT ===

if [ "$IS_TEST" -eq 0 ]; then
  echo "$CONTENT" | grep -qE 'console\.(log|debug|info|warn)' && \
    VIOLATIONS="$VIOLATIONS\n- console.log interdit en prod. Utilise sonner/toast."

  echo "$CONTENT" | grep -qiE 'fake|dummy|hardcoded|lorem ipsum' && \
    VIOLATIONS="$VIOLATIONS\n- Fakes/dummy/hardcoded en prod. Implemente le vrai code."

  echo "$CONTENT" | grep -PzoqE 'catch\s*\([^)]*\)\s*\{\s*\}' 2>/dev/null && \
    VIOLATIONS="$VIOLATIONS\n- Catch vide. Gere l'erreur (log, toast, rethrow)."
fi

# @ts-expect-error autorise UNIQUEMENT pour l'import SDK Power Apps
if echo "$CONTENT" | grep -qE '@ts-expect-error' && ! echo "$CONTENT" | grep -qE '@microsoft/power-apps'; then
  VIOLATIONS="$VIOLATIONS\n- @ts-expect-error autorise uniquement pour l'import SDK Power Apps."
fi

if [ -n "$VIOLATIONS" ]; then
  REASON=$(echo -e "CODE LAZY BLOQUE :$VIOLATIONS" | jq -Rs .)
  echo "{\"decision\": \"block\", \"reason\": $REASON}"
else
  echo '{"decision": "allow"}'
fi
```

---

## FICHIER 4 : .claude/agents/enforcer.md

```markdown
---
name: enforcer
description: |
  Revieweur intransigeant CRM Freelance Power Apps Code App.
  Utiliser SYSTEMATIQUEMENT avant chaque commit ou fin de feature.
  Connait TOUS les pieges Power Apps Code App.
tools: Read, Glob, Grep, Bash
---

Tu es le lead developer senior du projet CRM Freelance (Power Apps Code App).
Intolerance TOTALE au vibe coding. Tu connais tous les pieges du SDK.

## REFERENCES

- Cahier des charges : docs/CDC_CRM_Freelance.md
- Template : https://github.com/microsoft/PowerAppsCodeApps
- Doc Dataverse : https://learn.microsoft.com/en-us/power-apps/developer/code-apps/how-to/connect-to-dataverse
- Doc connexion : https://learn.microsoft.com/en-us/power-apps/developer/code-apps/how-to/connect-to-data

## BLOQUANTS (= refus total)

1. `any`, `as any`, `@ts-ignore` -> Type avec unknown + type guard
2. `TODO`, `FIXME`, `PLACEHOLDER` -> Code COMPLET ou rien
3. `console.log` en prod -> Utilise sonner/toast
4. Import `@microsoft/power-apps` sans sous-module -> Utiliser /data ou /app (PIEGE 1)
5. `eval()`, `new Function()`, `require()` -> Interdit par CSP (PIEGE 3)
6. `process.env` -> Utiliser import.meta.env (PIEGE 9)
7. `: JSX.Element` -> Laisser inferer (PIEGE 8)
8. SDK en rollupOptions.external -> Ne PAS faire (PIEGE 2)
9. Donnees non validees Zod -> Tout input passe par Zod
10. Fichier squelette < 10 lignes -> Implementer completement
11. Service sans pattern Mock + Production + Proxy -> Obligatoire
12. Fonction > 50 lignes -> Decomposer
13. Composant > 150 lignes -> Extraire sous-composants
14. Champs Dataverse mal mappes (PascalCase vs camelCase) -> Mapper dans le service (PIEGE 5)
15. Enums avec accents dans les types TS -> Sans accents dans types, avec dans labels (PIEGE 6)
16. import sans `import type` pour les types -> verbatimModuleSyntax (PIEGE 7)
17. BASENAME React Router modifie -> NE JAMAIS TOUCHER (PIEGE 11)
18. ThemeProvider sans defaultTheme="light" -> Forcer light (PIEGE 10)
19. Calcul financier sans arrondi 2 decimales -> Math.round(x \* 100) / 100
20. Facture emise supprimee -> INTERDIT (reglement francais)

## CHECKLIST SPECIFIQUE

- [ ] Services utilisent import dynamique lazy du SDK ?
- [ ] Chaque service a Mock + Production + Proxy ?
- [ ] Mapping PascalCase/camelCase dans CHAQUE methode ?
- [ ] Choice Dataverse mappes entier <-> label ?
- [ ] Lookups utilisent @odata.bind pour les FK ?
- [ ] Formulaires valides par Zod + react-hook-form ?
- [ ] Numerotation DEV/CMD/FAC/AVO-YYYY-NNN strictement sequentielle ?
- [ ] Mentions legales sur les PDF factures (art 293 B, penalites retard) ?
- [ ] Fichier .env pour les URLs Power Automate (pas en dur) ?

## FORMAT SORTIE

[BLOQUANT|MAJEUR|MINEUR] fichier:ligne - Probleme + Correction
Verdict final : MERGE OK ou MERGE REFUSE
```

---

## FICHIER 5 : .claude/agents/no-shortcut-dev.md

```markdown
---
name: no-shortcut-dev
description: |
  Developpeur senior Power Apps Code App qui ne triche JAMAIS.
  Connait tous les pieges SDK, Dataverse, CSP, TypeScript strict.
  Produit du code complet, teste, type.
tools: Read, Glob, Grep, Edit, Write, Bash
---

Tu es un developpeur senior expert React/TypeScript/Power Apps Code App.
Tu ne prends JAMAIS de raccourcis. 200 lignes robustes > 30 lignes fragiles.

## REFERENCES OBLIGATOIRES A CONSULTER

Avant de coder quoi que ce soit, lis :

- docs/CDC_CRM_Freelance.md (cahier des charges complet)
- CLAUDE.md (contraintes techniques et conventions)
- https://learn.microsoft.com/en-us/power-apps/developer/code-apps/how-to/connect-to-dataverse
- https://github.com/microsoft/PowerAppsCodeApps (template et exemples)

## WORKFLOW OBLIGATOIRE

### 1. COMPRENDRE (ne code rien)

- Lis le CDC pour les regles metier de la feature
- Lis le CLAUDE.md pour les contraintes techniques
- Identifie les entites, relations et regles impactees

### 2. PLANIFIER (plan ecrit)

- Ecris un plan dans docs/plan-[feature].md
- Liste : fichiers a creer/modifier, ordre, dependances
- Identifie les edge cases

### 3. TYPES EN PREMIER

- Commence par src/lib/types/ (le contrat)
- `import type` partout (verbatimModuleSyntax)
- Enums SANS accents, labels AVEC accents dans constants.ts
- Choice Dataverse = entiers, mapper dans le service

### 4. SERVICE COMPLET

- Interface TypeScript du service
- MockService avec donnees REALISTES (RATP, Sanofi, pas "test"/"foo")
- ProductionService avec import SDK dynamique lazy
- Proxy intelligent (prod en prod, mock en dev, fallback auto)
- Mapping Dataverse (noms logiques cds\_\*) <-> TypeScript (camelCase)
- @ts-expect-error UNIQUEMENT pour l'import SDK

### 5. HOOKS TANSTACK QUERY

- use-[entite].ts par entite
- useQuery pour lecture (staleTime 5min pour donnees stables, 1min pour dashboard)
- useMutation pour ecritures (invalidation du cache + toast sonner)

### 6. COMPOSANTS COMPLETS

- Loading state, empty state, error state, data state
- Formulaires : Zod + react-hook-form + validation complete
- Listes : Tanstack Table + tri + filtre + pagination
- Montants : format francais (espace milliers, virgule decimale)
- Badges statut avec couleurs par statut

### 7. TESTER

- `npx tsc --noEmit` apres chaque fichier (zero erreur)
- Tests vitest pour chaque service
- `npm run dev` pour verifier visuellement

## PIEGES A EVITER (appris de l'experience)

Tu dois connaitre ces pieges PAR COEUR :

- PIEGE 1 : SDK n'a PAS de root export -> @microsoft/power-apps/data
- PIEGE 2 : NE PAS mettre le SDK en external Vite
- PIEGE 3 : CSP bloque eval/require/new Function
- PIEGE 4 : Import dynamique lazy obligatoire pour le SDK
- PIEGE 5 : Mapping noms logiques Dataverse <-> camelCase TS
- PIEGE 6 : Enums sans accents dans les types
- PIEGE 7 : verbatimModuleSyntax = import type obligatoire
- PIEGE 8 : Pas de JSX.Element, laisser inferer
- PIEGE 9 : import.meta.env pas process.env
- PIEGE 10 : Forcer ThemeProvider defaultTheme="light"
- PIEGE 11 : NE JAMAIS toucher le BASENAME React Router
- PIEGE 12 : Champs auto Dataverse (createdon, modifiedon, statecode)
- PIEGE 13 : Pagination Dataverse max 5000 records, utiliser skipToken

## CE QUE TU NE FAIS JAMAIS

- Ecrire TODO/FIXME -> Implemente MAINTENANT
- Fichier de 5 lignes avec un export vide -> Code COMPLET
- Utiliser any -> Type correctement
- Creer un composant "Coming soon" -> Pas de facade
- Skipper la validation Zod -> Chaque formulaire valide
- Hardcoder des URLs Power Automate -> .env VITE\_\*
- Ignorer les calculs financiers -> Arrondi 2 decimales
- Supprimer une facture emise -> INTERDIT (loi francaise)
- Utiliser require() ou eval() -> Casse le CSP Power Apps
- Import direct @microsoft/power-apps -> Utiliser /data ou /app
```

---

## FICHIER 6 : .claude/agents/architect.md

```markdown
---
name: architect
description: |
  Architecte logiciel senior Power Platform / React / Dataverse.
  Valide structure, coherence donnees/types, patterns.
tools: Read, Glob, Grep, Bash
---

Tu es un architecte senior specialise React/TypeScript et Power Platform.

## REFERENCES

- CDC : docs/CDC_CRM_Freelance.md (section 4 = modele de donnees)
- Template : https://github.com/microsoft/PowerAppsCodeApps
- Dataverse : https://learn.microsoft.com/en-us/power-apps/developer/code-apps/how-to/connect-to-dataverse

## TON ROLE

1. Valider l'architecture selon CLAUDE.md
2. Verifier coherence modele Dataverse <-> types TypeScript
3. Verifier relations 1-N / N-1 (Lookups via @odata.bind)
4. Proposer optimisations (lazy loading, pagination skipToken, staleTime)
5. S'assurer que la chaine Devis > Commande > Facture est coherente

## AVANT TOUTE MODIFICATION D'ARCHITECTURE

1. Plan ecrit dans docs/plan.md
2. Lister les fichiers impactes
3. Identifier les risques de regression
4. Attendre validation

## REGLES D'ARCHITECTURE

- Chaque entite : type + service + hook + page(s)
- Services : pattern Interface > Mock > Production > Proxy
- Hooks : encapsulent Tanstack Query (pas de fetch dans les composants)
- Stores Zustand : uniquement state global (user, UI, settings)
- Calculs metier : dans les services, JAMAIS dans les composants
- Numerotation : centralisee dans numbering-service.ts
- PDF : generes cote client (jsPDF), pas de serveur
- Email : Power Automate via HTTP POST (URLs dans .env)

## CHECKLIST COHERENCE DONNEES

Pour chaque table Dataverse :

- [ ] Type TypeScript avec une propriete par colonne
- [ ] Service avec mappers mapToEntity() / mapFromEntity()
- [ ] Lookups = Lookup Dataverse (pas Text)
- [ ] Choice = Choice Dataverse (entier, pas Text)
- [ ] Currency = type Currency Dataverse (precision 2)
- [ ] Fichiers generes par pac non modifies directement
```

---

## FICHIER 7 : .claude/agents/test-writer.md

```markdown
---
name: test-writer
description: |
  Expert tests CRM Freelance. Couvre services, calculs financiers,
  regles metier, transitions de statut, numerotation.
tools: Read, Glob, Grep, Edit, Write, Bash
---

Tu es un expert QA senior React/TypeScript.

## FRAMEWORK : Vitest + @testing-library/react

Convention : fichier.test.ts a cote de fichier.ts

## TESTS OBLIGATOIRES

### Calculs financiers (precision critique)

- quantite x PU HT = montant HT
- montant HT x taux TVA / 100 = montant TVA
- somme des lignes HT = total HT
- remise % appliquee sur total HT avant TVA
- Arrondi : Math.round(x \* 100) / 100 (jamais de floating point)
- Edge cases : qte 0, PU 0, TVA 0%, qte decimale (0.5 jours)

### Numerotation

- Format : DEV-2026-001, CMD-2026-001, FAC-2026-001, AVO-2026-001
- Increment sequentiel (pas de trous pour factures = obligation legale)
- Reset annuel du compteur

### Transitions de statut

- Devis : Brouillon > Envoye > Accepte/Refuse/Expire
- Commande : En attente > En cours > Livre/Annule
- Facture : Brouillon > Emise > Payee/En retard
- Deal Gagne exige un devis Accepte
- Deal Perdu exige un motif
- Facture Emise non supprimable

### Paiements

- Solde = TTC - somme paiements
- Auto Payee quand solde = 0
- Auto En retard quand echeance depassee

### Validations Zod

- SIREN : exactement 9 chiffres
- Email : format valide
- Montant : > 0
- Probabilite : 0-100
- Date closing : futur (sauf Gagne/Perdu)

### Mapping Dataverse

- Chaque service Mock teste en CRUD complet
- Mapper : Dataverse record -> TypeScript entity (et inverse)
- Choice : entier Dataverse -> label string
```

---

## FICHIER 8 : .claude/commands/review.md

```markdown
Utilise l'agent enforcer pour reviewer tous les fichiers modifies.
Lance `git diff --name-only` pour identifier les fichiers changes.
Pour chaque fichier .ts ou .tsx modifie, applique la checklist complete
incluant les pieges Power Apps Code App (SDK, CSP, Dataverse).
Termine par un verdict : MERGE OK ou MERGE REFUSE avec la liste des corrections.
```

---

## FICHIER 9 : CLAUDE.md (a la racine du projet)

```markdown
# CRM Freelance - Power Apps Code App

> Ce fichier est lu par Claude Code au debut de CHAQUE session.
> Il contient les contraintes techniques NON NEGOCIABLES du projet.

## Projet

CRM de suivi d'affaires pour consultant freelance Power Platform & IA.
Power Apps Code App (React 19 / TypeScript 5.9 strict / Vite 7 / Dataverse).
CDC complet : docs/CDC_CRM_Freelance.md

## Stack
```

@microsoft/power-apps v1.0.4 (SDK)
@microsoft/power-apps-vite v1.0.2 (plugin Vite)
React 19 + TypeScript 5.9 strict + Vite 7
TailwindCSS v4 + shadcn/ui (New York, Radix UI)
Tanstack Query v5 + Tanstack Table v8
React Router v7 (BASENAME Power Apps - NE PAS TOUCHER)
Zustand v5, Recharts, Sonner, date-fns, lucide-react
react-hook-form + Zod v4 + @hookform/resolvers/standard-schema
jsPDF + jspdf-autotable (generation PDF cote client)
@dnd-kit/core + @dnd-kit/sortable (Kanban drag & drop)

```

## Donnees : Dataverse (PAS SharePoint)

- 21 tables custom prefixe `cds_`
- Connexion via `pac code add-data-source -a dataverse -t <table>`
- Services generes dans `src/generated/services/` (NE PAS MODIFIER)
- ProductionService DOIT utiliser les services generes (Cds_xxxService.getAll(), etc.)
- NE JAMAIS utiliser getClient() manuellement

## 13 Pieges SDK - A connaitre PAR COEUR

1. **Pas de root export** : importer `@microsoft/power-apps/data` ou `/app`, JAMAIS `@microsoft/power-apps`
2. **Pas en external Vite** : ne PAS mettre le SDK dans rollupOptions.external
3. **CSP stricte** : INTERDIT `eval()`, `new Function()`, `require()`
4. **Import dynamique lazy** : le SDK n'est dispo qu'au runtime Power Apps, utiliser `await import()`
5. **Mapping Dataverse** : noms logiques `cds_*` (Dataverse) <-> camelCase (TypeScript) via mappers
6. **Enums sans accents** : types TS sans accents (`Negociation`), labels UI avec accents (`Négociation`)
7. **verbatimModuleSyntax** : `import type { X }` obligatoire pour tous les types
8. **Pas de JSX.Element** : laisser inferer le type de retour des composants
9. **import.meta.env** : utiliser `import.meta.env.DEV`, JAMAIS `process.env`
10. **Forcer light mode** : `<ThemeProvider defaultTheme="light">`
11. **BASENAME React Router** : NE JAMAIS MODIFIER, configure par le template starter
12. **Champs auto Dataverse** : `createdon`, `modifiedon`, `statecode`, `statuscode` - NE PAS ecrire
13. **Pagination** : max 5000 records, utiliser `skipToken` pour paginer

## Pattern Service obligatoire

Chaque entite DOIT suivre : Interface > MockService > ProductionService > Proxy

```

src/lib/services/
├── account/
│ ├── index.ts # createServiceProxy<IAccountService>(mock, prod)
│ ├── types.ts # Interface IAccountService
│ ├── mock-service.ts # Donnees realistes (RATP, Sanofi, pas "test")
│ ├── production-service.ts # Utilise Cds_accountsService genere
│ └── enum-mappings.ts # Choice entier <-> string

````

- Dev (`import.meta.env.DEV`) : MockService
- Prod : ProductionService avec fallback Mock PAR APPEL (pas sticky)
- Generic obligatoire : `createServiceProxy<IAccountService>(mock, prod)`

## Choice fields Dataverse (entiers)

Les Choice sont des ENTIERS en Dataverse. Mapping bidirectionnel dans `enum-mappings.ts` :

```typescript
// Prefixe publisher CDS : OptionValuePrefix 14495
// Valeurs : 144950000, 144950001, 144950002...
export const ACCOUNT_STATUS_MAP = {
  144950000: "Actif",
  144950001: "Inactif",
  144950002: "Prospect",
} as const;

export function toInt<T extends Record<number, string>>(map: T, label: string): number {
  const entry = Object.entries(map).find(([, v]) => v === label);
  if (!entry) throw new Error(`Label inconnu: ${label}`);
  return Number(entry[0]);
}

export function toStr<T extends Record<number, string>>(map: T, value: number): string {
  return map[value as keyof T] ?? "Inconnu";
}
````

## Conventions de nommage

| Element              | Convention             | Exemple                          |
| -------------------- | ---------------------- | -------------------------------- |
| Table Dataverse      | `cds_` + snake_case    | `cds_account`, `cds_quote_line`  |
| Colonne Dataverse    | `cds_` + snake_case    | `cds_first_name`, `cds_total_ht` |
| Type TypeScript      | PascalCase             | `Account`, `QuoteLine`           |
| Propriete TypeScript | camelCase              | `firstName`, `totalHt`           |
| Composant React      | PascalCase             | `AccountCard`, `DealKanban`      |
| Hook React           | `use` + PascalCase     | `useAccounts`, `useDealKanban`   |
| Service              | camelCase + `Service`  | `accountService`                 |
| Fichier              | kebab-case             | `account-card.tsx`               |
| Enum value (TS)      | PascalCase sans accent | `EnAttente`, `Negociation`       |
| Label UI             | Francais avec accents  | `En attente`, `Négociation`      |

## Calculs financiers

- TOUJOURS arrondir : `Math.round(x * 100) / 100`
- ligne HT = qte x PU x (1 - remise/100)
- ligne TVA = ligne HT x (taux/100)
- total HT = somme lignes HT - remise globale
- total TTC = total HT + total TVA
- Solde facture = TTC - somme paiements

## Numerotation

- Format : `{PREFIX}-{YYYY}-{NNN}` (ex: DEV-2026-001, FAC-2026-001)
- Table `cds_numbering` : compteur par prefixe + annee
- Sequence sans trous pour les factures (obligation legale)
- Reset annuel du compteur

## Regles metier critiques

- Facture Emise = VERROUILLEE (pas de modification, pas de suppression - loi francaise)
- Pour corriger : creer un avoir (facture avec montants negatifs)
- Deal Gagne → probabilite 100%, date closing = aujourd'hui
- Deal Perdu → probabilite 0%, motif obligatoire
- Devis Envoye → non modifiable, dupliquer pour creer une v2
- Devis Expire auto si date validite depassee et statut Envoye
- Paiement : solde = 0 → facture Payee auto, echeance depassee → EnRetard auto

## Ordre de deploiement (STRICT)

1. Validation localhost avec MockService (`npm run dev`) - TOUS les modules
2. Creation tables Dataverse (Web API ou import solution)
3. `pac code add-data-source` pour les 21 tables
4. Branchement ProductionService sur services generes
5. `npm run build` (OBLIGATOIRE avant push)
6. `pac code push`
7. Donnees initiales dans cds_settings
8. Solution managee pour publication

NE JAMAIS inverser cet ordre. NE JAMAIS publier sans validation localhost.

## Build

```bash
# CORRECT : valider avec le vrai build
npm run build && pac code push

# INCORRECT : tsc ne suffit PAS
npx tsc --noEmit  # peut passer alors que vite build echoue
```

## power.config.json = source de verite

Le fichier `power.config.json` a la racine contient les `databaseReferences` avec les noms exacts des tables et entitySetNames apres `pac code add-data-source`. TOUJOURS le consulter en cas de doute sur un nom de table.

## En cas de doute ou d'echec

1. STOPPER toute improvisation
2. Consulter la doc officielle Microsoft :
   - Code Apps : https://learn.microsoft.com/en-us/power-apps/developer/code-apps/
   - Dataverse : https://learn.microsoft.com/en-us/power-apps/developer/code-apps/how-to/connect-to-dataverse
   - Web API : https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/
3. Appliquer la solution documentee
4. Documenter l'erreur dans CDC section 9.1 + COWORK section A8

## Interdits absolus

- `any`, `as any`, `@ts-ignore` → unknown + type guard
- `TODO`, `FIXME`, `PLACEHOLDER` → code complet ou rien
- `console.log` en prod → sonner/toast
- Fichier squelette < 10 lignes → implementer completement
- Composant "Coming soon" → pas de facade
- Hardcoder URLs Power Automate → `.env` VITE\_\*
- Supprimer facture emise → INTERDIT (loi francaise)
- Modifier fichiers `src/generated/` → regeneres par pac
- `require()`, `eval()`, `new Function()` → CSP Power Apps

````

---

## FICHIER 10 (ajout) : Section A11 - Enum Mappings complet (Choice fields)

> Ajouter dans la PARTIE A du document, apres A10.

## A11. Enum Mappings Dataverse - Reference complete

Toutes les valeurs Choice (picklist) Dataverse commencent a 144950000 (prefixe publisher CDS = 14495).

Chaque service DOIT utiliser `enum-mappings.ts` pour la conversion bidirectionnelle.

```typescript
// src/lib/services/shared/enum-mappings.ts

// === Helper generique ===
export function toInt<T extends Record<number, string>>(map: T, label: string): number {
  const entry = Object.entries(map).find(([, v]) => v === label);
  if (!entry) throw new Error(`[enum-mappings] Label inconnu: "${label}"`);
  return Number(entry[0]);
}

export function toStr<T extends Record<number, string>>(map: T, value: number): string {
  return map[value as keyof T] ?? "Inconnu";
}

// === Account Status ===
export const ACCOUNT_STATUS_MAP = {
  144950000: "Actif",
  144950001: "Inactif",
  144950002: "Prospect",
} as const;

// === Contact Status ===
export const CONTACT_STATUS_MAP = {
  144950000: "Actif",
  144950001: "Inactif",
} as const;

// === Contact Preference ===
export const CONTACT_PREF_MAP = {
  144950000: "Email",
  144950001: "Telephone",
  144950002: "LinkedIn",
  144950003: "Teams",
} as const;

// === Company Sector ===
export const SECTOR_MAP = {
  144950000: "Pharma",
  144950001: "IT",
  144950002: "Industrie",
  144950003: "BTP",
  144950004: "Services",
  144950005: "Transport",
  144950006: "Energie",
  144950007: "Autre",
} as const;

// === Company Size ===
export const COMPANY_SIZE_MAP = {
  144950000: "TPE",
  144950001: "PME",
  144950002: "ETI",
  144950003: "GE",
} as const;

// === Deal Stage ===
export const DEAL_STAGE_MAP = {
  144950000: "Prospect",
  144950001: "Qualification",
  144950002: "Proposition",
  144950003: "Negociation",
  144950004: "Gagne",
  144950005: "Perdu",
} as const;

// === Deal Source ===
export const DEAL_SOURCE_MAP = {
  144950000: "Malt",
  144950001: "LinkedIn",
  144950002: "Recommandation",
  144950003: "AppelEntrant",
  144950004: "SiteWeb",
  144950005: "Salon",
  144950006: "Autre",
} as const;

// === Deal Loss Reason ===
export const DEAL_LOSS_REASON_MAP = {
  144950000: "Prix",
  144950001: "Timing",
  144950002: "Concurrent",
  144950003: "Budget",
  144950004: "PasDeReponse",
  144950005: "Autre",
} as const;

// === Quote Status ===
export const QUOTE_STATUS_MAP = {
  144950000: "Brouillon",
  144950001: "Envoye",
  144950002: "Accepte",
  144950003: "Refuse",
  144950004: "Expire",
} as const;

// === Order Status ===
export const ORDER_STATUS_MAP = {
  144950000: "EnAttente",
  144950001: "EnCours",
  144950002: "Livre",
  144950003: "Annule",
} as const;

// === Invoice Status ===
export const INVOICE_STATUS_MAP = {
  144950000: "Brouillon",
  144950001: "Emise",
  144950002: "Payee",
  144950003: "EnRetard",
  144950004: "Avoir",
} as const;

// === Activity Type ===
export const ACTIVITY_TYPE_MAP = {
  144950000: "Appel",
  144950001: "Email",
  144950002: "Reunion",
  144950003: "Relance",
  144950004: "Note",
} as const;

// === Activity Outcome ===
export const ACTIVITY_OUTCOME_MAP = {
  144950000: "Positif",
  144950001: "Neutre",
  144950002: "Negatif",
  144950003: "SansReponse",
} as const;

// === Task Priority ===
export const TASK_PRIORITY_MAP = {
  144950000: "Haute",
  144950001: "Moyenne",
  144950002: "Basse",
} as const;

// === Task Status ===
export const TASK_STATUS_MAP = {
  144950000: "AFaire",
  144950001: "EnCours",
  144950002: "Terminee",
  144950003: "Annulee",
} as const;

// === Line Unit ===
export const LINE_UNIT_MAP = {
  144950000: "Jour",
  144950001: "Heure",
  144950002: "Unite",
  144950003: "Forfait",
} as const;

// === Payment Method ===
export const PAYMENT_METHOD_MAP = {
  144950000: "Virement",
  144950001: "Cheque",
  144950002: "CB",
  144950003: "Autre",
} as const;

// === Email Template Category ===
export const EMAIL_CATEGORY_MAP = {
  144950000: "Relance",
  144950001: "Facturation",
  144950002: "Commercial",
  144950003: "Autre",
} as const;

// === Email Log Status ===
export const EMAIL_LOG_STATUS_MAP = {
  144950000: "Envoye",
  144950001: "Erreur",
  144950002: "Brouillon",
} as const;

// === Workflow Execution Result ===
export const WORKFLOW_RESULT_MAP = {
  144950000: "Succes",
  144950001: "Erreur",
  144950002: "Ignore",
} as const;
````

---

## A12. createServiceProxy - Pattern generique (non sticky)

Le proxy NE DOIT PAS etre sticky : une erreur sur un appel ne bascule PAS tous les appels suivants sur Mock.

```typescript
// src/lib/services/shared/service-proxy.ts

export function createServiceProxy<T extends object>(
  mockService: T,
  productionService: T,
): T {
  if (import.meta.env.DEV) return mockService;

  return new Proxy(productionService, {
    get(target, prop, receiver) {
      const value = Reflect.get(target, prop, receiver);
      if (typeof value !== "function") return value;

      return async (...args: unknown[]) => {
        try {
          return await value.apply(target, args);
        } catch (error: unknown) {
          const errMsg = error instanceof Error ? error.message : String(error);
          // NE PAS mettre useMock = true ici (pas de fallback sticky)
          // Log pour diagnostic en production
          if (typeof window !== "undefined" && "console" in window) {
            (window.console as Console).error(
              `[ServiceProxy] ${String(prop)} failed, fallback mock:`,
              errMsg,
            );
          }
          const mockFn = Reflect.get(mockService, prop, receiver);
          return typeof mockFn === "function"
            ? mockFn.apply(mockService, args)
            : undefined;
        }
      };
    },
  }) as T;
}
```

Usage dans chaque service :

```typescript
// src/lib/services/account/index.ts
import type { IAccountService } from "./types";
import { MockAccountService } from "./mock-service";
import { ProductionAccountService } from "./production-service";
import { createServiceProxy } from "../shared/service-proxy";

export const accountService = createServiceProxy<IAccountService>(
  new MockAccountService(),
  new ProductionAccountService(),
);
```

---

## A13. power.config.json - Source de verite

Apres `pac code init` + `pac code add-data-source`, le fichier `power.config.json` a la racine contient la reference exacte des tables :

```json
{
  "appType": "spa",
  "databaseReferences": {
    "cds_accounts": {
      "apiId": "dataverse",
      "entitySetName": "cds_accountses",
      "logicalName": "cds_accounts"
    },
    "cds_contacts": {
      "apiId": "dataverse",
      "entitySetName": "cds_contactses",
      "logicalName": "cds_contacts"
    }
    // ... 21 tables
  }
}
```

**ATTENTION** : le `entitySetName` genere par Dataverse peut etre surprenant (ex: `cds_accountses` avec double 's'). TOUJOURS verifier dans ce fichier, NE PAS deviner le pluriel.

Les services generes dans `src/generated/services/` utilisent ces entitySetNames. C'est pourquoi il faut utiliser les services generes et NE PAS construire les URLs OData manuellement.

---

## A14. Ordre de deploiement strict (reference CDC Annexe C)

```
ETAPE 0 : Validation localhost (OBLIGATOIRE)
  └─ npm run dev + test TOUS les modules avec MockService
  └─ Zero erreur console, tous CRUD, graphiques, filtres, Kanban DnD
  └─ NE PAS passer a l'etape suivante si un point echoue

ETAPE 1 : Creer les tables Dataverse
  └─ Import solution CRMFreelance_Unmanaged.zip (make.powerapps.com > Solutions)
  └─ OU script Web API deploy_dataverse_tables.py
  └─ Verifier langue env : FR = 1036, EN = 1033

ETAPE 2 : Verifier les 21 tables
  └─ make.powerapps.com > Tables > verifier colonnes + relations

ETAPE 3 : pac code add-data-source (21 tables)
  └─ pac code init (premiere fois)
  └─ pac code add-data-source -a dataverse -t cds_xxx (x21)
  └─ Verifie que src/generated/services/ est peuple

ETAPE 3bis : Brancher ProductionService
  └─ Chaque ProductionService utilise les services generes
  └─ Mapper Dataverse -> TS (noms, types, Choice entiers)
  └─ Proxy en place (prod en prod, mock en dev)

ETAPE 4 : Build + Deploy
  └─ npm run build (OBLIGATOIRE, tsc ne suffit PAS)
  └─ pac code push
  └─ Verifier dans make.powerapps.com > Mes applications > "Lire"

ETAPE 5 : Donnees initiales
  └─ Inserer dans cds_settings : company_name, siren, adresse, TVA, etc.

ETAPE 6 : Solution managee (optionnel, pour distribution)
  └─ Exporter depuis make.powerapps.com en mode Managed
  └─ NE JAMAIS importer une solution non managee en production
```

---

## Structure cible mise a jour

```
.claude/
├── settings.json
├── agents/
│   ├── enforcer.md
│   ├── no-shortcut-dev.md
│   ├── architect.md
│   └── test-writer.md
├── hooks/
│   ├── quality-gate.sh
│   └── block-lazy-code.sh
└── commands/
    └── review.md

CLAUDE.md  (racine du projet)
```

---

## APRES AVOIR CREE TOUS LES FICHIERS

```bash
# Rendre les hooks executables
chmod +x .claude/hooks/quality-gate.sh
chmod +x .claude/hooks/block-lazy-code.sh

# Verifier la structure
find .claude -type f | sort
cat CLAUDE.md | head -5

# Ajouter au git
git add .claude/ CLAUDE.md
git commit -m "chore: setup .claude/ anti-vibe-coding + CLAUDE.md + Power Apps Code App knowledge"
```
