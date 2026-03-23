# Cahier des Charges - CRM Suivi d'Affaires

## Power Apps Code App (React/TypeScript + Dataverse)

**Version** : 1.0
**Date** : 20 mars 2026
**Auteur** : {{NOM_AUTEUR}} - {{NOM_ENTREPRISE}} (SIREN {{SIREN}})
**Statut** : Draft

---

## Table des matières

1. [Résumé exécutif](#1-résumé-exécutif)
2. [Architecture technique](#2-architecture-technique)
3. [Modèle de données Dataverse](#3-modèle-de-données-dataverse)
4. [Modules fonctionnels](#4-modules-fonctionnels)
5. [Spécifications PDF](#5-spécifications-pdf)
6. [Flux Power Automate](#6-flux-power-automate)
7. [Maquettes fonctionnelles](#7-maquettes-fonctionnelles)
8. [Roadmap de développement](#8-roadmap-de-développement)
9. [Points d'attention techniques](#9-points-dattention-techniques)
10. [Solution Dataverse - Contrôle de cohérence](#10-solution-dataverse---contrôle-de-cohérence)

---

## 1. Résumé exécutif

### 1.1 Objectif

Développer un CRM de suivi d'affaires complet, destiné à un consultant freelance Power Platform & IA. L'application couvre l'intégralité du cycle commercial : prospection, qualification, devis, commande, facturation et suivi de paiement.

### 1.2 Périmètre fonctionnel

- Gestion des entreprises clientes (Accounts)
- Gestion des contacts rattachés
- Pipeline d'opportunités commerciales avec vue Kanban
- Cycle devis > commande > facture avec génération PDF
- Envoi d'emails via Power Automate + templates + tracking
- Suivi d'activités et rappels
- Vue 360° par client
- Tableau de bord interactif avec KPIs, graphiques et cross-filtering style Power BI
- Automatisations / Workflows visuels configurables
- Objectifs commerciaux et Gamification (trophées)
- Import/Export avancé (CSV, LinkedIn parser)
- Historique complet et Audit trail

### 1.3 Cible utilisateur

Utilisateur unique (consultant freelance) avec possibilité d'extension multi-utilisateurs. L'authentification repose sur le contexte Power Apps (`window.__POWER_APPS_CONTEXT__`).

### 1.4 Stack technique

| Couche        | Technologie                                                                    |
| ------------- | ------------------------------------------------------------------------------ |
| Framework     | Power Apps Code App (template `microsoft/PowerAppsCodeApps/templates/starter`) |
| Frontend      | React 19 + TypeScript 5.9 strict                                               |
| Build         | Vite 7                                                                         |
| UI            | TailwindCSS v4 + shadcn/ui (New York)                                          |
| State         | Zustand v5 (global) + Tanstack Query v5 (server state)                         |
| Routing       | React Router v7 (BASENAME Power Apps natif)                                    |
| Tables        | Tanstack Table v8                                                              |
| Graphiques    | Recharts                                                                       |
| Formulaires   | react-hook-form + Zod v4                                                       |
| PDF           | react-pdf/renderer (ou jsPDF en fallback)                                      |
| Notifications | Sonner                                                                         |
| Dates         | date-fns                                                                       |
| Icones        | lucide-react                                                                   |
| Données       | Dataverse (tables custom)                                                      |
| Emails        | Power Automate (HTTP trigger)                                                  |
| Déploiement   | `pac code push`                                                                |

---

## 2. Architecture technique

### 2.1 Schéma des relations entre tables

```
┌─────────────┐       1───N       ┌─────────────┐
│  cds_account │──────────────────▶│ cds_contact  │
└──────┬───────┘                   └──────┬───────┘
       │ 1                                │ 1
       │                                  │
       │ N                                │ N
┌──────▼───────┐                          │
│   cds_deal   │◀─────────────────────────┘
└──────┬───────┘       (contact principal)
       │ 1
       │ N
┌──────▼───────┐
│  cds_quote   │
└──────┬───────┘
       │ 1                    ┌──────────────────┐
       │ N                    │ cds_quote_line    │
       │◀─────────────────────┤ (lignes devis)   │
       │                      └──────────────────┘
       │ 1 (devis accepté)
       │ N
┌──────▼───────┐
│  cds_order   │
└──────┬───────┘
       │ 1                    ┌──────────────────┐
       │ N                    │ cds_order_line    │
       │◀─────────────────────┤ (lignes commande)│
       │                      └──────────────────┘
       │ 1
       │ N
┌──────▼───────┐
│ cds_invoice  │
└──────┬───────┘
       │ 1                    ┌──────────────────┐
       │ N                    │ cds_invoice_line  │
       │◀─────────────────────┤ (lignes facture) │
       │                      └──────────────────┘
       │ 1
       │ N
┌──────▼────────────┐
│ cds_payment       │
│ (suivi paiements) │
└───────────────────┘

┌──────────────┐
│ cds_activity │──── Lookup polymorphique vers Account / Contact / Deal
└──────────────┘

┌──────────────┐
│  cds_task    │──── Lookup vers Account / Contact / Deal / Activity
└──────────────┘

┌────────────────┐
│ cds_attachment  │──── Lookup vers Quote / Order / Invoice
└────────────────┘

┌──────────────────┐
│ cds_email_template│──── Templates d'emails réutilisables
└────────┬─────────┘
         │ 1
         │ N
┌────────▼─────────┐
│  cds_email_log   │──── Historique emails envoyés + tracking
└──────────────────┘     Lookup vers Account / Contact / Template

┌──────────────────┐
│ cds_workflow_rule│──── Règles d'automatisation configurables
└────────┬─────────┘
         │ 1
         │ N
┌────────▼─────────────┐
│ cds_workflow_execution│──── Journal d'exécution des workflows
└──────────────────────┘

┌──────────────┐
│  cds_goal    │──── Objectifs commerciaux avec progression
└──────────────┘

┌────────────────┐
│ cds_achievement│──── Trophées et récompenses gamification
└────────────────┘

┌──────────────────┐
│ cds_audit_entry  │──── Journal d'audit complet (qui, quoi, quand)
└──────────────────┘
```

### 2.2 Architecture projet (arborescence fichiers)

```
src/
├── lib/
│   ├── types/
│   │   ├── index.ts              # Re-export
│   │   ├── account.ts            # Account, AccountInput, AccountFilters
│   │   ├── contact.ts            # Contact, ContactInput
│   │   ├── deal.ts               # Deal, DealInput, DealStatus
│   │   ├── quote.ts              # Quote, QuoteLine, QuoteInput
│   │   ├── order.ts              # Order, OrderLine
│   │   ├── invoice.ts            # Invoice, InvoiceLine, Payment
│   │   ├── activity.ts           # Activity, Task
│   │   └── enums.ts              # Tous les enums (Choice fields)
│   ├── services/
│   │   ├── dataverse.ts          # Interface + Mock + Production + Proxy
│   │   ├── account-service.ts    # CRUD Account
│   │   ├── contact-service.ts    # CRUD Contact
│   │   ├── deal-service.ts       # CRUD Deal
│   │   ├── quote-service.ts      # CRUD Quote + QuoteLines
│   │   ├── order-service.ts      # CRUD Order + OrderLines
│   │   ├── invoice-service.ts    # CRUD Invoice + InvoiceLines + Payments
│   │   ├── activity-service.ts   # CRUD Activity + Task
│   │   ├── numbering-service.ts  # Générateur numéros auto (DEV-, FAC-, CMD-)
│   │   ├── pdf-service.ts        # Génération PDF devis/facture
│   │   ├── email-service.ts      # Appel Power Automate HTTP trigger
│   │   ├── workflow-service.ts    # CRUD Workflow Rules + Execution log
│   │   ├── goals-service.ts       # Objectifs + Achievements
│   │   ├── audit-service.ts       # Audit trail complet
│   │   └── import-export-service.ts # CSV export/import + LinkedIn parser
│   └── utils.ts                  # cn(), formatCurrency(), formatDate()
├── hooks/
│   ├── use-accounts.ts           # Tanstack Query hooks
│   ├── use-contacts.ts
│   ├── use-deals.ts
│   ├── use-quotes.ts
│   ├── use-orders.ts
│   ├── use-invoices.ts
│   ├── use-activities.ts
│   ├── use-dashboard.ts
│   ├── use-emails.ts
│   ├── use-workflows.ts
│   ├── use-goals.ts
│   ├── use-audit.ts
│   └── use-import-export.ts
├── stores/
│   ├── user-store.ts             # Zustand : utilisateur courant
│   ├── ui-store.ts               # Sidebar collapsed, active filters, etc.
│   └── numbering-store.ts        # Cache compteurs numérotation
├── providers/
│   ├── auth-provider.tsx         # Init user via __POWER_APPS_CONTEXT__
│   ├── query-provider.tsx        # QueryClient config
│   ├── theme-provider.tsx        # Force light theme
│   └── sonner-provider.tsx       # Toast notifications
├── pages/
│   ├── _layout.tsx               # Sidebar + header + content area
│   ├── dashboard.tsx             # KPIs + graphiques + alertes
│   ├── accounts/
│   │   ├── account-list.tsx      # Liste + recherche + filtres
│   │   └── account-detail.tsx    # Vue 360° client
│   ├── contacts/
│   │   ├── contact-list.tsx
│   │   └── contact-detail.tsx
│   ├── deals/
│   │   ├── deal-kanban.tsx       # Vue Kanban pipeline
│   │   ├── deal-list.tsx         # Vue liste
│   │   └── deal-detail.tsx
│   ├── quotes/
│   │   ├── quote-list.tsx
│   │   ├── quote-form.tsx        # Création/édition devis
│   │   └── quote-detail.tsx      # Aperçu + actions
│   ├── orders/
│   │   ├── order-list.tsx
│   │   └── order-detail.tsx
│   ├── invoices/
│   │   ├── invoice-list.tsx
│   │   └── invoice-detail.tsx
│   ├── activities/
│   │   └── activity-list.tsx     # Journal d'activités global
│   └── not-found.tsx
├── components/
│   ├── ui/                       # shadcn/ui components
│   ├── shared/
│   │   ├── data-table.tsx        # Table générique Tanstack Table
│   │   ├── search-bar.tsx
│   │   ├── status-badge.tsx
│   │   ├── currency-display.tsx
│   │   ├── confirm-dialog.tsx
│   │   ├── empty-state.tsx
│   │   └── loading-skeleton.tsx
│   ├── accounts/
│   │   ├── account-card.tsx
│   │   └── account-form.tsx
│   ├── deals/
│   │   ├── deal-kanban-card.tsx
│   │   └── deal-form.tsx
│   ├── quotes/
│   │   ├── quote-line-editor.tsx  # Éditeur lignes devis inline
│   │   └── quote-pdf-preview.tsx
│   ├── invoices/
│   │   ├── invoice-line-editor.tsx
│   │   ├── invoice-pdf-preview.tsx
│   │   └── payment-form.tsx
│   └── activities/
│       ├── activity-form.tsx
│       ├── activity-timeline.tsx  # Chronologie verticale
│       └── task-card.tsx
├── pdf/
│   ├── quote-template.tsx        # Template react-pdf devis
│   ├── invoice-template.tsx      # Template react-pdf facture
│   └── shared/
│       ├── pdf-header.tsx        # Logo + infos société
│       ├── pdf-footer.tsx        # Mentions légales + pagination
│       └── pdf-line-table.tsx    # Table lignes réutilisable
├── router.tsx
├── App.tsx
└── main.tsx
```

### 2.3 Pattern d'accès aux données

Le service Dataverse utilise les **services générés** par `pac code add-data-source` (dans `src/generated/services/`).

**IMPORTANT** : NE JAMAIS utiliser `getClient()` manuellement. Toujours utiliser les services générés.

- **Dev local** (`import.meta.env.DEV`) : MockService avec données en mémoire
- **Production** : ProductionService qui appelle les services générés (`Cds_accountsService`, etc.)
- **Proxy fallback** : si le service généré échoue, bascule automatique sur Mock

```typescript
// Pattern correct - ProductionService utilise le service généré
import { Cds_accountsService } from "../../generated/services/Cds_accountsService";

class ProductionAccountService implements IAccountService {
  async getAll(): Promise<Account[]> {
    const result = await Cds_accountsService.getAll({
      select: ["cds_accountid", "cds_name", "cds_siren"],
      orderBy: ["cds_name asc"],
      top: 100,
    });
    return (result.data || []).map((r) => this.mapToAccount(r));
  }

  async create(input: AccountInput): Promise<Account> {
    const result = await Cds_accountsService.create(this.mapFromAccount(input));
    return this.mapToAccount(result.data!);
  }
}
```

Chaque service métier garde le mapping camelCase (TypeScript) <-> snake_case (Dataverse) via `mapToEntity` / `mapFromEntity`.

---

## 3. Modèle de données Dataverse

### 3.1 Table : cds_account (Entreprises)

| Colonne           | Nom logique        | Type Dataverse        | Requis | Description                                                     |
| ----------------- | ------------------ | --------------------- | ------ | --------------------------------------------------------------- |
| ID                | cds_accountid      | Uniqueidentifier (PK) | Auto   | Identifiant unique                                              |
| Nom               | cds_name           | Text (200)            | Oui    | Raison sociale                                                  |
| SIREN             | cds_siren          | Text (9)              | Non    | Numéro SIREN (9 chiffres)                                       |
| Secteur           | cds_sector         | Choice                | Non    | Pharma, IT, Industrie, BTP, Services, Transport, Energie, Autre |
| Taille            | cds_company_size   | Choice                | Non    | TPE, PME, ETI, GE                                               |
| Adresse           | cds_address        | Text (500)            | Non    | Adresse complète                                                |
| Code postal       | cds_postal_code    | Text (10)             | Non    | Code postal                                                     |
| Ville             | cds_city           | Text (100)            | Non    | Ville                                                           |
| Pays              | cds_country        | Text (100)            | Non    | Pays (defaut: France)                                           |
| Site web          | cds_website        | Text (300)            | Non    | URL du site                                                     |
| Telephone         | cds_phone          | Text (20)             | Non    | Numero principal                                                |
| Email general     | cds_email          | Text (200)            | Non    | Email principal                                                 |
| Logo URL          | cds_logo_url       | Text (500)            | Non    | URL du logo                                                     |
| Tags              | cds_tags           | Text (500)            | Non    | Tags separes par virgule                                        |
| Score priorite    | cds_priority_score | Whole Number (0-100)  | Non    | Score de priorisation manuelle                                  |
| Notes             | cds_notes          | Multiline Text (5000) | Non    | Notes internes                                                  |
| Statut            | cds_status         | Choice                | Oui    | Actif, Inactif, Prospect                                        |
| Date creation     | createdon          | DateTime              | Auto   | Date de creation                                                |
| Date modification | modifiedon         | DateTime              | Auto   | Derniere modification                                           |

**Index recommandes** : cds_name, cds_siren, cds_sector, cds_status, cds_priority_score

---

### 3.2 Table : cds_contact (Contacts)

| Colonne            | Nom logique           | Type Dataverse        | Requis | Description                       |
| ------------------ | --------------------- | --------------------- | ------ | --------------------------------- |
| ID                 | cds_contactid         | Uniqueidentifier (PK) | Auto   | Identifiant unique                |
| Prenom             | cds_first_name        | Text (100)            | Oui    | Prenom                            |
| Nom                | cds_last_name         | Text (100)            | Oui    | Nom de famille                    |
| Entreprise         | cds_account_id        | Lookup (cds_account)  | Oui    | Entreprise rattachee              |
| Poste              | cds_job_title         | Text (200)            | Non    | Intitule de poste                 |
| Email              | cds_email             | Text (200)            | Oui    | Email professionnel               |
| Telephone          | cds_phone             | Text (20)             | Non    | Telephone direct                  |
| Mobile             | cds_mobile            | Text (20)             | Non    | Telephone mobile                  |
| LinkedIn           | cds_linkedin_url      | Text (300)            | Non    | URL profil LinkedIn               |
| Preference contact | cds_contact_pref      | Choice                | Non    | Email, Telephone, LinkedIn, Teams |
| Est decisionnaire  | cds_is_decision_maker | Yes/No                | Non    | Contact decisionnaire             |
| Notes              | cds_notes             | Multiline Text (5000) | Non    | Notes internes                    |
| Statut             | cds_status            | Choice                | Oui    | Actif, Inactif                    |
| Date creation      | createdon             | DateTime              | Auto   |                                   |
| Date modification  | modifiedon            | DateTime              | Auto   |                                   |

**Relations** : N-1 vers cds_account (cds_account_id)
**Index recommandes** : cds_last_name, cds_email, cds_account_id, cds_status

---

### 3.3 Table : cds_deal (Affaires / Opportunites)

| Colonne              | Nom logique             | Type Dataverse        | Requis | Description                                                         |
| -------------------- | ----------------------- | --------------------- | ------ | ------------------------------------------------------------------- |
| ID                   | cds_dealid              | Uniqueidentifier (PK) | Auto   | Identifiant unique                                                  |
| Titre                | cds_name                | Text (300)            | Oui    | Nom de l'affaire                                                    |
| Entreprise           | cds_account_id          | Lookup (cds_account)  | Oui    | Entreprise liee                                                     |
| Contact principal    | cds_contact_id          | Lookup (cds_contact)  | Non    | Contact referent                                                    |
| Statut               | cds_stage               | Choice                | Oui    | Prospect, Qualification, Proposition, Negociation, Gagne, Perdu     |
| Montant estime       | cds_amount              | Currency              | Non    | Montant estime HT                                                   |
| Probabilite          | cds_probability         | Whole Number (0-100)  | Non    | Probabilite de closing (%)                                          |
| Montant pondere      | cds_weighted_amount     | Currency              | Non    | Calcule : montant x probabilite                                     |
| Date estimee closing | cds_expected_close_date | Date Only             | Non    | Date prevue de conclusion                                           |
| Date closing reelle  | cds_actual_close_date   | Date Only             | Non    | Date reelle si Gagne/Perdu                                          |
| Source               | cds_source              | Choice                | Non    | Malt, LinkedIn, Recommandation, AppelEntrant, SiteWeb, Salon, Autre |
| Raison perte         | cds_loss_reason         | Choice                | Non    | Prix, Timing, Concurrent, Budget, PasDeReponse, Autre               |
| Notes                | cds_notes               | Multiline Text (5000) | Non    | Notes internes                                                      |
| Date creation        | createdon               | DateTime              | Auto   |                                                                     |
| Date modification    | modifiedon              | DateTime              | Auto   |                                                                     |

**Relations** : N-1 vers cds_account, N-1 vers cds_contact
**Index recommandes** : cds_stage, cds_account_id, cds_expected_close_date, cds_source

**Regles metier** :

- Quand `cds_stage` passe a "Gagne" : `cds_probability` = 100, `cds_actual_close_date` = aujourd'hui
- Quand `cds_stage` passe a "Perdu" : `cds_probability` = 0, `cds_actual_close_date` = aujourd'hui, `cds_loss_reason` obligatoire
- `cds_weighted_amount` = `cds_amount` x (`cds_probability` / 100), recalcule a chaque modification

---

### 3.4 Table : cds_quote (Devis)

| Colonne                | Nom logique             | Type Dataverse        | Requis | Description                                |
| ---------------------- | ----------------------- | --------------------- | ------ | ------------------------------------------ |
| ID                     | cds_quoteid             | Uniqueidentifier (PK) | Auto   | Identifiant unique                         |
| Numero                 | cds_number              | Text (20)             | Auto   | Numero auto DEV-AAAA-NNN                   |
| Affaire                | cds_deal_id             | Lookup (cds_deal)     | Oui    | Affaire liee                               |
| Entreprise             | cds_account_id          | Lookup (cds_account)  | Oui    | Herite de l'affaire                        |
| Contact                | cds_contact_id          | Lookup (cds_contact)  | Non    | Destinataire du devis                      |
| Statut                 | cds_status              | Choice                | Oui    | Brouillon, Envoye, Accepte, Refuse, Expire |
| Date emission          | cds_issue_date          | Date Only             | Oui    | Date d'emission                            |
| Date validite          | cds_valid_until         | Date Only             | Oui    | Date d'expiration                          |
| Duree validite jours   | cds_validity_days       | Whole Number          | Non    | Defaut 30 jours                            |
| Total HT               | cds_total_ht            | Currency              | Auto   | Somme lignes HT                            |
| Total TVA              | cds_total_vat           | Currency              | Auto   | Somme lignes TVA                           |
| Total TTC              | cds_total_ttc           | Currency              | Auto   | HT + TVA                                   |
| Remise globale %       | cds_global_discount_pct | Decimal (0-100)       | Non    | Remise en pourcentage                      |
| Remise globale montant | cds_global_discount_amt | Currency              | Non    | Montant remise                             |
| Conditions             | cds_terms               | Multiline Text (5000) | Non    | Conditions particulieres                   |
| Notes internes         | cds_internal_notes      | Multiline Text (5000) | Non    | Notes non visibles client                  |
| Source devis duplique  | cds_source_quote_id     | Lookup (cds_quote)    | Non    | Reference si duplication                   |
| Date creation          | createdon               | DateTime              | Auto   |                                            |
| Date modification      | modifiedon              | DateTime              | Auto   |                                            |

**Relations** : N-1 vers cds_deal, N-1 vers cds_account, N-1 vers cds_contact
**Index recommandes** : cds_number, cds_status, cds_deal_id, cds_account_id, cds_issue_date

**Regles metier** :

- `cds_number` : genere automatiquement au format `DEV-{AAAA}-{NNN}` (compteur annuel incremental)
- `cds_valid_until` = `cds_issue_date` + `cds_validity_days` (recalcul auto)
- `cds_total_ht` = somme des lignes HT - remise globale
- `cds_total_vat` = somme des lignes TVA (recalcule apres remise)
- `cds_total_ttc` = `cds_total_ht` + `cds_total_vat`
- Un devis "Envoye" ne peut plus etre modifie (creer une nouvelle version)
- Un devis "Accepte" declenche la possibilite de creer une commande
- Un devis passe a "Expire" automatiquement si `cds_valid_until` < date du jour et statut = "Envoye"

---

### 3.5 Table : cds_quote_line (Lignes de devis)

| Colonne          | Nom logique           | Type Dataverse        | Requis | Description                 |
| ---------------- | --------------------- | --------------------- | ------ | --------------------------- |
| ID               | cds_quote_lineid      | Uniqueidentifier (PK) | Auto   |                             |
| Devis            | cds_quote_id          | Lookup (cds_quote)    | Oui    | Devis parent                |
| Ordre            | cds_line_order        | Whole Number          | Oui    | Ordre d'affichage           |
| Designation      | cds_description       | Text (500)            | Oui    | Description prestation      |
| Quantite         | cds_quantity          | Decimal               | Oui    | Quantite (jours, unites)    |
| Unite            | cds_unit              | Choice                | Non    | Jour, Heure, Unite, Forfait |
| Prix unitaire HT | cds_unit_price        | Currency              | Oui    | PU HT                       |
| Taux TVA         | cds_vat_rate          | Decimal               | Oui    | Defaut 20.00                |
| Remise ligne %   | cds_line_discount_pct | Decimal (0-100)       | Non    | Remise sur la ligne         |
| Total HT ligne   | cds_line_total_ht     | Currency              | Auto   | qte x PU - remise           |
| Total TVA ligne  | cds_line_total_vat    | Currency              | Auto   | HT x taux TVA               |
| Total TTC ligne  | cds_line_total_ttc    | Currency              | Auto   | HT + TVA                    |

**Relations** : N-1 vers cds_quote
**Index recommandes** : cds_quote_id, cds_line_order

**Regles metier** :

- `cds_line_total_ht` = `cds_quantity` x `cds_unit_price` x (1 - `cds_line_discount_pct`/100)
- `cds_line_total_vat` = `cds_line_total_ht` x (`cds_vat_rate`/100)
- `cds_line_total_ttc` = `cds_line_total_ht` + `cds_line_total_vat`

---

### 3.6 Table : cds_order (Commandes)

| Colonne             | Nom logique       | Type Dataverse        | Requis | Description                       |
| ------------------- | ----------------- | --------------------- | ------ | --------------------------------- |
| ID                  | cds_orderid       | Uniqueidentifier (PK) | Auto   |                                   |
| Numero              | cds_number        | Text (20)             | Auto   | CMD-AAAA-NNN                      |
| Devis source        | cds_quote_id      | Lookup (cds_quote)    | Oui    | Devis d'origine                   |
| Affaire             | cds_deal_id       | Lookup (cds_deal)     | Oui    | Herite du devis                   |
| Entreprise          | cds_account_id    | Lookup (cds_account)  | Oui    | Herite du devis                   |
| Contact             | cds_contact_id    | Lookup (cds_contact)  | Non    | Herite du devis                   |
| Statut              | cds_status        | Choice                | Oui    | EnAttente, EnCours, Livre, Annule |
| Date commande       | cds_order_date    | Date Only             | Oui    | Date de la commande               |
| Total HT            | cds_total_ht      | Currency              | Auto   | Copie depuis devis                |
| Total TVA           | cds_total_vat     | Currency              | Auto   | Copie depuis devis                |
| Total TTC           | cds_total_ttc     | Currency              | Auto   | Copie depuis devis                |
| Reference BC client | cds_client_po_ref | Text (100)            | Non    | Reference bon de commande client  |
| PJ Bon de commande  | cds_po_attachment | File                  | Non    | PDF du bon de commande client     |
| Notes               | cds_notes         | Multiline Text (5000) | Non    |                                   |
| Date creation       | createdon         | DateTime              | Auto   |                                   |
| Date modification   | modifiedon        | DateTime              | Auto   |                                   |

**Relations** : N-1 vers cds_quote, N-1 vers cds_deal, N-1 vers cds_account, N-1 vers cds_contact
**Index recommandes** : cds_number, cds_status, cds_quote_id, cds_account_id

**Regles metier** :

- `cds_number` : genere automatiquement au format `CMD-{AAAA}-{NNN}`
- A la creation, les lignes et montants sont copies depuis le devis source
- Le devis source passe a "Accepte" si ce n'est pas deja le cas
- L'affaire liee passe a "Gagne" si ce n'est pas deja le cas

---

### 3.7 Table : cds_order_line (Lignes de commande)

| Colonne          | Nom logique           | Type Dataverse        | Requis | Description                 |
| ---------------- | --------------------- | --------------------- | ------ | --------------------------- |
| ID               | cds_order_lineid      | Uniqueidentifier (PK) | Auto   |                             |
| Commande         | cds_order_id          | Lookup (cds_order)    | Oui    | Commande parent             |
| Ordre            | cds_line_order        | Whole Number          | Oui    | Ordre d'affichage           |
| Designation      | cds_description       | Text (500)            | Oui    |                             |
| Quantite         | cds_quantity          | Decimal               | Oui    |                             |
| Unite            | cds_unit              | Choice                | Non    | Jour, Heure, Unite, Forfait |
| Prix unitaire HT | cds_unit_price        | Currency              | Oui    |                             |
| Taux TVA         | cds_vat_rate          | Decimal               | Oui    |                             |
| Remise ligne %   | cds_line_discount_pct | Decimal (0-100)       | Non    |                             |
| Total HT ligne   | cds_line_total_ht     | Currency              | Auto   |                             |
| Total TVA ligne  | cds_line_total_vat    | Currency              | Auto   |                             |
| Total TTC ligne  | cds_line_total_ttc    | Currency              | Auto   |                             |

**Relations** : N-1 vers cds_order

---

### 3.8 Table : cds_invoice (Factures)

| Colonne                 | Nom logique            | Type Dataverse        | Requis | Description                              |
| ----------------------- | ---------------------- | --------------------- | ------ | ---------------------------------------- |
| ID                      | cds_invoiceid          | Uniqueidentifier (PK) | Auto   |                                          |
| Numero                  | cds_number             | Text (20)             | Auto   | FAC-AAAA-NNN                             |
| Commande source         | cds_order_id           | Lookup (cds_order)    | Oui    | Commande d'origine                       |
| Devis source            | cds_quote_id           | Lookup (cds_quote)    | Non    | Reference directe devis                  |
| Affaire                 | cds_deal_id            | Lookup (cds_deal)     | Oui    |                                          |
| Entreprise              | cds_account_id         | Lookup (cds_account)  | Oui    |                                          |
| Contact                 | cds_contact_id         | Lookup (cds_contact)  | Non    |                                          |
| Statut                  | cds_status             | Choice                | Oui    | Brouillon, Emise, Payee, EnRetard, Avoir |
| Date emission           | cds_issue_date         | Date Only             | Oui    | Date d'emission                          |
| Date echeance           | cds_due_date           | Date Only             | Oui    | Date limite de paiement                  |
| Delai paiement jours    | cds_payment_terms_days | Whole Number          | Non    | Defaut 30 jours                          |
| Total HT                | cds_total_ht           | Currency              | Auto   |                                          |
| Total TVA               | cds_total_vat          | Currency              | Auto   |                                          |
| Total TTC               | cds_total_ttc          | Currency              | Auto   |                                          |
| Montant paye            | cds_amount_paid        | Currency              | Auto   | Somme des paiements recus                |
| Solde restant           | cds_balance_due        | Currency              | Auto   | TTC - paye                               |
| Facture avoir reference | cds_credit_note_ref    | Lookup (cds_invoice)  | Non    | Si avoir, reference la facture originale |
| Notes                   | cds_notes              | Multiline Text (5000) | Non    |                                          |
| Mentions legales        | cds_legal_mentions     | Multiline Text (5000) | Non    | Defaut pre-rempli                        |
| Date creation           | createdon              | DateTime              | Auto   |                                          |
| Date modification       | modifiedon             | DateTime              | Auto   |                                          |

**Relations** : N-1 vers cds_order, N-1 vers cds_quote, N-1 vers cds_deal, N-1 vers cds_account, N-1 vers cds_contact
**Index recommandes** : cds_number, cds_status, cds_order_id, cds_account_id, cds_due_date

**Regles metier** :

- `cds_number` : genere automatiquement au format `FAC-{AAAA}-{NNN}` (sequence distincte des devis)
- `cds_due_date` = `cds_issue_date` + `cds_payment_terms_days`
- `cds_amount_paid` = somme de tous les `cds_payment.cds_amount` lies
- `cds_balance_due` = `cds_total_ttc` - `cds_amount_paid`
- Statut passe a "Payee" automatiquement quand `cds_balance_due` = 0
- Statut passe a "EnRetard" automatiquement quand `cds_due_date` < aujourd'hui et `cds_balance_due` > 0
- Un avoir genere un numero FAC-AAAA-NNN normal mais avec statut "Avoir" et montants negatifs
- Les montants sont initialement copies depuis la commande mais restent modifiables tant que statut = "Brouillon"
- Une facture "Emise" n'est plus modifiable (creer un avoir pour corriger)

---

### 3.9 Table : cds_invoice_line (Lignes de facture)

Structure identique a `cds_order_line`, avec Lookup vers `cds_invoice` au lieu de `cds_order`.

| Colonne          | Nom logique           | Type Dataverse        | Requis | Description    |
| ---------------- | --------------------- | --------------------- | ------ | -------------- |
| ID               | cds_invoice_lineid    | Uniqueidentifier (PK) | Auto   |                |
| Facture          | cds_invoice_id        | Lookup (cds_invoice)  | Oui    | Facture parent |
| Ordre            | cds_line_order        | Whole Number          | Oui    |                |
| Designation      | cds_description       | Text (500)            | Oui    |                |
| Quantite         | cds_quantity          | Decimal               | Oui    |                |
| Unite            | cds_unit              | Choice                | Non    |                |
| Prix unitaire HT | cds_unit_price        | Currency              | Oui    |                |
| Taux TVA         | cds_vat_rate          | Decimal               | Oui    |                |
| Remise ligne %   | cds_line_discount_pct | Decimal (0-100)       | Non    |                |
| Total HT ligne   | cds_line_total_ht     | Currency              | Auto   |                |
| Total TVA ligne  | cds_line_total_vat    | Currency              | Auto   |                |
| Total TTC ligne  | cds_line_total_ttc    | Currency              | Auto   |                |

---

### 3.10 Table : cds_payment (Suivi des paiements)

| Colonne       | Nom logique        | Type Dataverse        | Requis | Description                 |
| ------------- | ------------------ | --------------------- | ------ | --------------------------- |
| ID            | cds_paymentid      | Uniqueidentifier (PK) | Auto   |                             |
| Facture       | cds_invoice_id     | Lookup (cds_invoice)  | Oui    | Facture concernee           |
| Date paiement | cds_payment_date   | Date Only             | Oui    | Date de reception           |
| Montant       | cds_amount         | Currency              | Oui    | Montant recu                |
| Mode paiement | cds_payment_method | Choice                | Non    | Virement, Cheque, CB, Autre |
| Reference     | cds_reference      | Text (100)            | Non    | Reference virement/cheque   |
| Notes         | cds_notes          | Text (500)            | Non    |                             |
| Date creation | createdon          | DateTime              | Auto   |                             |

**Relations** : N-1 vers cds_invoice
**Index recommandes** : cds_invoice_id, cds_payment_date

**Regles metier** :

- Apres creation/modification/suppression d'un paiement, recalculer `cds_invoice.cds_amount_paid` et `cds_invoice.cds_balance_due`
- Si `cds_balance_due` = 0 apres recalcul, passer la facture en "Payee"
- Empecher un paiement dont le montant depasse `cds_balance_due`

---

### 3.11 Table : cds_activity (Activites)

| Colonne               | Nom logique          | Type Dataverse        | Requis | Description                           |
| --------------------- | -------------------- | --------------------- | ------ | ------------------------------------- |
| ID                    | cds_activityid       | Uniqueidentifier (PK) | Auto   |                                       |
| Type                  | cds_type             | Choice                | Oui    | Appel, Email, Reunion, Relance, Note  |
| Sujet                 | cds_subject          | Text (300)            | Oui    | Titre de l'activite                   |
| Contenu               | cds_content          | Multiline Text (5000) | Non    | Detail de l'activite                  |
| Date                  | cds_activity_date    | DateTime              | Oui    | Date et heure                         |
| Duree minutes         | cds_duration_minutes | Whole Number          | Non    | Duree en minutes                      |
| Resultat              | cds_outcome          | Choice                | Non    | Positif, Neutre, Negatif, SansReponse |
| Entreprise            | cds_account_id       | Lookup (cds_account)  | Non    | Rattachement entreprise               |
| Contact               | cds_contact_id       | Lookup (cds_contact)  | Non    | Rattachement contact                  |
| Affaire               | cds_deal_id          | Lookup (cds_deal)     | Non    | Rattachement affaire                  |
| Prochaine action      | cds_next_action      | Text (300)            | Non    | Description prochaine action          |
| Date prochaine action | cds_next_action_date | Date Only             | Non    | Date planifiee                        |
| Date creation         | createdon            | DateTime              | Auto   |                                       |

**Relations** : N-1 vers cds_account (optionnel), N-1 vers cds_contact (optionnel), N-1 vers cds_deal (optionnel)
**Index recommandes** : cds_type, cds_activity_date, cds_account_id, cds_contact_id, cds_deal_id

**Regles metier** :

- Au moins un des trois lookups (account, contact, deal) doit etre renseigne
- Si un contact est selectionne, l'entreprise du contact est auto-remplie
- Si une affaire est selectionnee, l'entreprise et le contact de l'affaire sont auto-remplis

---

### 3.12 Table : cds_task (Taches / Rappels)

| Colonne           | Nom logique     | Type Dataverse        | Requis | Description                        |
| ----------------- | --------------- | --------------------- | ------ | ---------------------------------- |
| ID                | cds_taskid      | Uniqueidentifier (PK) | Auto   |                                    |
| Titre             | cds_title       | Text (300)            | Oui    |                                    |
| Description       | cds_description | Multiline Text (2000) | Non    |                                    |
| Date echeance     | cds_due_date    | Date Only             | Oui    |                                    |
| Priorite          | cds_priority    | Choice                | Oui    | Haute, Moyenne, Basse              |
| Statut            | cds_status      | Choice                | Oui    | AFaire, EnCours, Terminee, Annulee |
| Entreprise        | cds_account_id  | Lookup (cds_account)  | Non    |                                    |
| Contact           | cds_contact_id  | Lookup (cds_contact)  | Non    |                                    |
| Affaire           | cds_deal_id     | Lookup (cds_deal)     | Non    |                                    |
| Activite liee     | cds_activity_id | Lookup (cds_activity) | Non    |                                    |
| Date creation     | createdon       | DateTime              | Auto   |                                    |
| Date modification | modifiedon      | DateTime              | Auto   |                                    |

**Relations** : N-1 vers cds_account, cds_contact, cds_deal, cds_activity (tous optionnels)
**Index recommandes** : cds_due_date, cds_priority, cds_status

---

### 3.13 Table : cds_numbering (Compteurs numerotation)

| Colonne        | Nom logique     | Type Dataverse        | Requis | Description              |
| -------------- | --------------- | --------------------- | ------ | ------------------------ |
| ID             | cds_numberingid | Uniqueidentifier (PK) | Auto   |                          |
| Prefixe        | cds_prefix      | Text (10)             | Oui    | DEV, CMD, FAC            |
| Annee          | cds_year        | Whole Number          | Oui    | 2026                     |
| Dernier numero | cds_last_number | Whole Number          | Oui    | Dernier compteur utilise |

**Index recommandes** : cds_prefix + cds_year (unique)

**Regles metier** :

- A chaque creation de devis/commande/facture, incrementer `cds_last_number` et formater : `{prefix}-{year}-{number.padStart(3, '0')}`
- Si pas d'entree pour l'annee en cours, creer avec `cds_last_number` = 0

---

### 3.14 Table : cds_settings (Parametres application)

| Colonne | Nom logique    | Type Dataverse        | Requis | Description                                |
| ------- | -------------- | --------------------- | ------ | ------------------------------------------ |
| ID      | cds_settingsid | Uniqueidentifier (PK) | Auto   |                                            |
| Cle     | cds_key        | Text (100)            | Oui    | Unique. Ex: company_name, vat_rate_default |
| Valeur  | cds_value      | Text (2000)           | Oui    | Valeur du parametre                        |

**Parametres prevus** :

- `company_name` : {{NOM_ENTREPRISE}}
- `company_siren` : {{SIREN}}
- `company_address` : {{ADRESSE}}
- `company_email` : {{EMAIL}}
- `company_phone` : {{TELEPHONE}}
- `company_logo_url` : {{URL_LOGO}}
- `company_website` : {{SITE_WEB}}
- `vat_rate_default` : 20.00
- `quote_validity_days` : 30
- `payment_terms_days` : 30
- `invoice_legal_mentions` : Mentions legales facture
- `invoice_bank_details` : RIB/IBAN pour paiement
- `power_automate_email_url` : URL du flow HTTP trigger

---

### 3.15 Table : cds_email_template (Templates d'emails)

| Colonne   | Nom logique          | Type Dataverse         | Requis | Description                             |
| --------- | -------------------- | ---------------------- | ------ | --------------------------------------- |
| ID        | cds_email_templateid | Uniqueidentifier (PK)  | Auto   | Identifiant unique                      |
| Nom       | cds_name             | Text (200)             | Oui    | Nom du template                         |
| Sujet     | cds_subject          | Text (300)             | Oui    | Sujet de l'email                        |
| Corps     | cds_body             | Multiline Text (10000) | Non    | Corps avec variables {{var}}            |
| Catégorie | cds_category         | Choice                 | Non    | Relance, Facturation, Commercial, Autre |
| Variables | cds_variables        | Text (500)             | Non    | Variables disponibles                   |

### 3.16 Table : cds_email_log (Historique emails)

| Colonne      | Nom logique       | Type Dataverse              | Requis | Description               |
| ------------ | ----------------- | --------------------------- | ------ | ------------------------- |
| ID           | cds_email_logid   | Uniqueidentifier (PK)       | Auto   | Identifiant unique        |
| Sujet        | cds_subject       | Text (300)                  | Oui    | Sujet de l'email envoyé   |
| Destinataire | cds_to            | Text (200)                  | Oui    | Email destinataire        |
| Copie        | cds_cc            | Text (500)                  | Non    | Emails en copie           |
| Corps        | cds_body          | Multiline Text (10000)      | Non    | Corps envoyé              |
| Date envoi   | cds_sent_at       | DateTime                    | Oui    | Date/heure d'envoi        |
| Statut       | cds_status        | Choice                      | Non    | Envoyé, Erreur, Brouillon |
| Template     | cds_template_id   | Lookup (cds_email_template) | Non    | Template utilisé          |
| Type entité  | cds_related_type  | Text (50)                   | Non    | Type de l'entité liée     |
| ID entité    | cds_related_id    | Text (50)                   | Non    | ID de l'entité liée       |
| Label entité | cds_related_label | Text (200)                  | Non    | Label de l'entité liée    |
| Compte       | cds_account_id    | Lookup (cds_account)        | Non    | Compte associé            |
| Contact      | cds_contact_id    | Lookup (cds_contact)        | Non    | Contact associé           |

### 3.17 Table : cds_workflow_rule (Règles d'automatisation)

| Colonne            | Nom logique          | Type Dataverse        | Requis | Description                |
| ------------------ | -------------------- | --------------------- | ------ | -------------------------- |
| ID                 | cds_workflow_ruleid  | Uniqueidentifier (PK) | Auto   | Identifiant unique         |
| Nom                | cds_name             | Text (300)            | Oui    | Nom de la règle            |
| Description        | cds_description      | Multiline Text (2000) | Non    | Description détaillée      |
| Déclencheur        | cds_trigger          | Text (50)             | Oui    | Type de déclencheur        |
| Conditions         | cds_conditions       | Multiline Text (5000) | Non    | Conditions JSON            |
| Action             | cds_action           | Text (50)             | Oui    | Type d'action              |
| Config action      | cds_action_config    | Multiline Text (5000) | Non    | Configuration JSON         |
| Active             | cds_is_enabled       | Yes/No                | Non    | Règle active (défaut: Oui) |
| Nb exécutions      | cds_execution_count  | Whole Number          | Non    | Compteur d'exécutions      |
| Dernière exécution | cds_last_executed_at | DateTime              | Non    | Date dernière exécution    |

### 3.18 Table : cds_workflow_execution (Journal exécutions)

| Colonne            | Nom logique              | Type Dataverse             | Requis | Description                   |
| ------------------ | ------------------------ | -------------------------- | ------ | ----------------------------- |
| ID                 | cds_workflow_executionid | Uniqueidentifier (PK)      | Auto   | Identifiant unique            |
| Règle              | cds_rule_id              | Lookup (cds_workflow_rule) | Oui    | Règle exécutée                |
| Nom règle          | cds_rule_name            | Text (300)                 | Non    | Nom de la règle (dénormalisé) |
| Date exécution     | cds_executed_at          | DateTime                   | Oui    | Date/heure d'exécution        |
| Entité déclencheur | cds_trigger_entity       | Text (50)                  | Non    | Type entité déclencheur       |
| ID enregistrement  | cds_trigger_record_id    | Text (50)                  | Non    | ID record déclencheur         |
| Action exécutée    | cds_action_taken         | Text (50)                  | Non    | Action réalisée               |
| Résultat           | cds_result               | Choice                     | Non    | Succès, Erreur, Ignoré        |
| Détails            | cds_details              | Multiline Text (2000)      | Non    | Détails / message d'erreur    |

### 3.19 Table : cds_goal (Objectifs commerciaux)

| Colonne         | Nom logique       | Type Dataverse        | Requis | Description                    |
| --------------- | ----------------- | --------------------- | ------ | ------------------------------ |
| ID              | cds_goalid        | Uniqueidentifier (PK) | Auto   | Identifiant unique             |
| Nom             | cds_name          | Text (300)            | Oui    | Nom de l'objectif              |
| Métrique        | cds_metric        | Text (50)             | Oui    | Type de métrique               |
| Période         | cds_period        | Text (20)             | Oui    | Mensuel, Trimestriel, Annuel   |
| Objectif        | cds_target_value  | Decimal (2)           | Oui    | Valeur cible                   |
| Valeur actuelle | cds_current_value | Decimal (2)           | Non    | Progression actuelle           |
| Date début      | cds_start_date    | DateTime (DateOnly)   | Oui    | Début de la période            |
| Date fin        | cds_end_date      | DateTime (DateOnly)   | Oui    | Fin de la période              |
| Atteint         | cds_is_achieved   | Yes/No                | Non    | Objectif atteint (défaut: Non) |

### 3.20 Table : cds_achievement (Trophées / Gamification)

| Colonne          | Nom logique         | Type Dataverse        | Requis | Description                  |
| ---------------- | ------------------- | --------------------- | ------ | ---------------------------- |
| ID               | cds_achievementid   | Uniqueidentifier (PK) | Auto   | Identifiant unique           |
| Nom              | cds_name            | Text (200)            | Oui    | Nom du trophée               |
| Description      | cds_description     | Text (500)            | Non    | Description du trophée       |
| Icône            | cds_icon            | Text (50)             | Non    | Nom icône Lucide             |
| Catégorie        | cds_category        | Text (50)             | Non    | Catégorie du trophée         |
| Type condition   | cds_condition_type  | Text (50)             | Non    | Type de condition            |
| Valeur condition | cds_condition_value | Whole Number          | Non    | Seuil à atteindre            |
| Débloqué         | cds_is_unlocked     | Yes/No                | Non    | Trophée obtenu (défaut: Non) |
| Date déblocage   | cds_unlocked_at     | DateTime              | Non    | Date d'obtention             |
| Progression      | cds_progress        | Whole Number (0-100)  | Non    | Progression en %             |

### 3.21 Table : cds_audit_entry (Journal d'audit)

| Colonne         | Nom logique       | Type Dataverse         | Requis | Description                              |
| --------------- | ----------------- | ---------------------- | ------ | ---------------------------------------- |
| ID              | cds_audit_entryid | Uniqueidentifier (PK)  | Auto   | Identifiant unique                       |
| Type entité     | cds_entity_type   | Text (50)              | Oui    | Type d'entité modifiée                   |
| ID entité       | cds_entity_id     | Text (50)              | Oui    | ID de l'entité                           |
| Label entité    | cds_entity_label  | Text (300)             | Non    | Nom/label de l'entité                    |
| Action          | cds_action        | Text (50)              | Oui    | create, update, delete, status_change... |
| ID utilisateur  | cds_user_id       | Text (50)              | Non    | ID de l'utilisateur                      |
| Nom utilisateur | cds_user_name     | Text (200)             | Non    | Nom de l'utilisateur                     |
| Date            | cds_timestamp     | DateTime               | Oui    | Date/heure de l'action                   |
| Modifications   | cds_changes       | Multiline Text (10000) | Non    | Détail des changements (JSON)            |
| Description     | cds_description   | Multiline Text (2000)  | Non    | Description lisible                      |

---

## 4. Modules fonctionnels

### 4.1 Module Entreprises (Accounts)

#### User Stories

| ID     | En tant que | Je veux                                                                                   | Afin de                                        |
| ------ | ----------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------- |
| ACC-01 | Consultant  | Creer une fiche entreprise avec nom, SIREN, secteur, taille, adresse, site web, telephone | Centraliser mes prospects et clients           |
| ACC-02 | Consultant  | Voir la liste de toutes mes entreprises avec filtres (secteur, taille, statut, tags)      | Retrouver rapidement une entreprise            |
| ACC-03 | Consultant  | Rechercher une entreprise par nom, SIREN ou ville                                         | Acceder rapidement a une fiche                 |
| ACC-04 | Consultant  | Modifier les informations d'une entreprise                                                | Garder mes donnees a jour                      |
| ACC-05 | Consultant  | Supprimer une entreprise (soft delete via statut Inactif)                                 | Nettoyer ma base sans perdre l'historique      |
| ACC-06 | Consultant  | Attribuer un score de priorite (0-100) a une entreprise                                   | Prioriser mes actions commerciales             |
| ACC-07 | Consultant  | Ajouter des tags a une entreprise                                                         | Categoriser librement                          |
| ACC-08 | Consultant  | Acceder a la vue 360° d'une entreprise                                                    | Voir tout le contexte client en un coup d'oeil |
| ACC-09 | Consultant  | Supprimer une entreprise avec option de suppression des contacts associes                 | Nettoyer proprement ma base                    |

#### Regles metier

- Le SIREN doit etre unique et contenir exactement 9 chiffres (validation Zod)
- La suppression est un soft delete : passage du statut a "Inactif"
- A la suppression d'une entreprise : dialog de confirmation avec option "Supprimer egalement les X contacts associes"
- Si l'option est cochee, les contacts associes passent aussi en statut "Inactif"
- Le score de priorite est entre 0 et 100, modifiable manuellement
- Les tags sont stockes comme texte separe par des virgules, avec autocompletion basee sur les tags existants
- Un compte ne peut etre supprime que s'il n'a aucune affaire en statut Prospect/Qualification/Proposition/Negociation
- La creation d'entreprise se fait via un formulaire Dialog inline (pas de page separee)

---

### 4.2 Module Contacts

#### User Stories

| ID     | En tant que | Je veux                                      | Afin de                               |
| ------ | ----------- | -------------------------------------------- | ------------------------------------- |
| CON-01 | Consultant  | Creer un contact rattache a une entreprise   | Suivre mes interlocuteurs             |
| CON-02 | Consultant  | Voir tous les contacts d'une entreprise      | Identifier les interlocuteurs cles    |
| CON-03 | Consultant  | Marquer un contact comme decisionnaire       | Cibler mes actions commerciales       |
| CON-04 | Consultant  | Voir l'historique des activites d'un contact | Contextualiser mes echanges           |
| CON-05 | Consultant  | Rechercher un contact par nom ou email       | Retrouver rapidement un interlocuteur |
| CON-06 | Consultant  | Modifier / desactiver un contact             | Garder ma base a jour                 |
| CON-07 | Consultant  | Supprimer un contact avec confirmation       | Nettoyer ma base                      |

#### Regles metier

- Un contact doit obligatoirement etre rattache a une entreprise
- L'email doit etre unique par entreprise
- Le lien LinkedIn est valide s'il contient "linkedin.com"
- Un contact ne peut etre desactive que s'il n'est contact principal d'aucune affaire active
- La suppression d'un contact affiche un dialog de confirmation avant le soft delete

---

### 4.3 Module Affaires (Deals)

#### User Stories

| ID     | En tant que | Je veux                                                                             | Afin de                            |
| ------ | ----------- | ----------------------------------------------------------------------------------- | ---------------------------------- |
| DEA-01 | Consultant  | Creer une affaire liee a une entreprise et un contact                               | Suivre mon pipe commercial         |
| DEA-02 | Consultant  | Voir mon pipeline en Kanban (colonnes par statut)                                   | Visualiser l'avancement global     |
| DEA-03 | Consultant  | Deplacer une affaire d'un statut a l'autre en drag & drop                           | Mettre a jour rapidement           |
| DEA-04 | Consultant  | Voir la liste des affaires avec filtres (statut, source, date, montant)             | Analyser mon pipe                  |
| DEA-05 | Consultant  | Modifier le montant, la probabilite et la date estimee                              | Affiner mes previsions             |
| DEA-06 | Consultant  | Marquer une affaire comme "Gagee" ou "Perdue" avec raison                           | Cloturer le cycle                  |
| DEA-07 | Consultant  | Voir le montant pondere (montant x probabilite)                                     | Evaluer mon pipe                   |
| DEA-08 | Consultant  | Filtrer les affaires par source                                                     | Mesurer mes canaux d'acquisition   |
| DEA-09 | Consultant  | Creer une affaire directement depuis la liste ou le Kanban via un formulaire Dialog | Ajouter rapidement une opportunite |
| DEA-10 | Consultant  | Modifier une affaire via un formulaire Dialog (pas de page separee)                 | Editer sans quitter le contexte    |

#### Regles metier

- Le passage a "Gagne" met automatiquement probabilite a 100% et date de closing a aujourd'hui
- Le passage a "Perdu" met automatiquement probabilite a 0% et demande une raison de perte
- Le montant pondere est recalcule automatiquement a chaque changement de montant ou probabilite
- On ne peut pas passer de "Gagne" ou "Perdu" vers un autre statut (sauf reouverture explicite)
- La source de l'affaire est obligatoire
- Probabilites par defaut a l'entree dans un stade : Prospect 10%, Qualification 25%, Proposition 50%, Negociation 75%
- La creation et l'edition des affaires se font via des formulaires Dialog inline (pas de page /deals/new)
- Le formulaire peut etre pre-rempli avec un accountId depuis la Vue 360 client

---

### 4.4 Module Devis (Quotes)

#### User Stories

| ID     | En tant que | Je veux                                              | Afin de                    |
| ------ | ----------- | ---------------------------------------------------- | -------------------------- |
| QUO-01 | Consultant  | Creer un devis lie a une affaire                     | Formaliser ma proposition  |
| QUO-02 | Consultant  | Ajouter/modifier/supprimer des lignes de prestation  | Detailler ma proposition   |
| QUO-03 | Consultant  | Voir les totaux HT/TVA/TTC se calculer en temps reel | Verifier mes montants      |
| QUO-04 | Consultant  | Appliquer une remise par ligne ou globale            | Ajuster mon prix           |
| QUO-05 | Consultant  | Generer un PDF professionnel du devis                | Envoyer un document propre |
| QUO-06 | Consultant  | Envoyer le devis par email au contact                | Transmettre ma proposition |
| QUO-07 | Consultant  | Dupliquer un devis existant                          | Gagner du temps            |
| QUO-08 | Consultant  | Changer le statut du devis                           | Suivre l'avancement        |
| QUO-09 | Consultant  | Convertir un devis accepte en commande               | Lancer l'execution         |
| QUO-10 | Consultant  | Voir les devis bientot expires                       | Relancer a temps           |

#### Regles metier

- La numerotation est automatique : `DEV-2026-001`, `DEV-2026-002`, etc.
- Le compteur repart a 001 chaque annee
- Un devis doit avoir au moins une ligne
- La TVA par defaut est 20% (configurable dans cds_settings)
- La duree de validite par defaut est 30 jours (configurable)
- Un devis en statut "Envoye" ne peut plus etre modifie, il faut le dupliquer pour creer une v2
- Le passage a "Accepte" declenche : proposition de creer une commande
- Le passage a "Refuse" demande optionnellement une raison
- Un devis "Envoye" passe automatiquement a "Expire" si la date de validite est depassee (verification au chargement)

---

### 4.5 Module Commandes (Orders)

#### User Stories

| ID     | En tant que | Je veux                                                             | Afin de                                       |
| ------ | ----------- | ------------------------------------------------------------------- | --------------------------------------------- |
| ORD-01 | Consultant  | Convertir un devis accepte en commande                              | Formaliser l'engagement                       |
| ORD-02 | Consultant  | Joindre le bon de commande PDF du client                            | Archiver le document                          |
| ORD-03 | Consultant  | Voir les commandes par statut                                       | Suivre mes engagements                        |
| ORD-04 | Consultant  | Modifier le statut d'une commande                                   | Suivre l'avancement                           |
| ORD-05 | Consultant  | Generer une facture depuis une commande                             | Enchainer le processus                        |
| ORD-06 | Consultant  | Creer une commande directement (sans devis)                         | Gerer les commandes sans proposition formelle |
| ORD-07 | Consultant  | Joindre des pieces jointes (PDF, images) a une commande ou un devis | Archiver les documents lies                   |

#### Regles metier

- La numerotation est automatique : `CMD-2026-001`
- Une commande peut etre creee de 2 facons :
  - Depuis un devis accepte (lignes et montants copies automatiquement)
  - Directement sans devis (saisie manuelle des lignes et montants)
- Si creee depuis un devis, les montants sont copies et non modifiables
- Si creee sans devis, les lignes sont saisies manuellement (editeur de lignes comme les devis)
- Le bon de commande client est un fichier PDF attache (colonne File Dataverse)
- Des pieces jointes supplementaires peuvent etre ajoutees (PJ stockees en base64 ou via File Dataverse)
- Le passage a "Livre" declenche : proposition de creer une facture
- Une commande "Annulee" ne peut plus changer de statut
- Suppression possible uniquement si statut != "Livre" (commande livree = potentiellement facturee)
- Dialog de confirmation avant suppression

---

### 4.6 Module Factures (Invoices)

#### User Stories

| ID     | En tant que | Je veux                                                    | Afin de                              |
| ------ | ----------- | ---------------------------------------------------------- | ------------------------------------ |
| INV-01 | Consultant  | Generer une facture depuis une commande                    | Facturer ma prestation               |
| INV-02 | Consultant  | Modifier les lignes tant que la facture est en brouillon   | Ajuster si besoin                    |
| INV-03 | Consultant  | Generer un PDF de facture professionnel                    | Envoyer au client                    |
| INV-04 | Consultant  | Envoyer la facture par email                               | Transmettre au client                |
| INV-05 | Consultant  | Enregistrer un paiement (date, montant, mode)              | Suivre l'encaissement                |
| INV-06 | Consultant  | Voir le solde restant a payer                              | Savoir ce qui reste du               |
| INV-07 | Consultant  | Etre alerte des factures en retard                         | Relancer rapidement                  |
| INV-08 | Consultant  | Creer un avoir lie a une facture                           | Corriger une erreur                  |
| INV-09 | Consultant  | Voir la liste des factures par statut (filtres)            | Suivre ma facturation                |
| INV-10 | Consultant  | Creer une facture directement depuis la liste des factures | Facturer sans passer par la commande |
| INV-11 | Consultant  | Associer une commande existante a une facture              | Lier la facture a son contexte       |
| INV-12 | Consultant  | Telecharger le PDF de la facture                           | Archiver localement                  |
| INV-13 | Consultant  | Exporter les factures en CSV/Excel                         | Analyser dans un tableur             |
| INV-14 | Consultant  | Envoyer la facture par email avec PDF en PJ                | Transmettre directement au client    |

#### Regles metier

- La numerotation suit une sequence distincte : `FAC-2026-001`
- Une facture peut etre creee de 2 facons :
  - Depuis une commande (lignes et montants copies automatiquement)
  - Directement depuis la liste des factures (saisie manuelle, association commande optionnelle)
- Les lignes sont modifiables en statut "Brouillon"
- Une facture "Emise" est verrouillee (impossible de modifier)
- Le passage a "Emise" enregistre definitivement les montants
- Le solde restant est recalcule automatiquement a chaque enregistrement de paiement
- Quand le solde atteint 0, la facture passe automatiquement a "Payee"
- Quand la date d'echeance est depassee et le solde > 0, statut passe a "EnRetard"
- Un avoir est une facture avec montants negatifs et reference a la facture originale
- Le PDF est genere cote client via jsPDF + jspdf-autotable
- L'envoi par email utilise Power Automate (HTTP trigger) avec le PDF en base64
- Mentions legales obligatoires sur le PDF : mentions EI/micro-entreprise, numero SIREN, conditions de paiement, penalites de retard
- Suppression possible UNIQUEMENT en statut "Brouillon" (une facture Emise/Payee ne peut JAMAIS etre supprimee - reglementation francaise)
- Dialog de confirmation avant suppression avec avertissement reglementaire

---

### 4.7 Module Activites & Suivi

#### User Stories

| ID     | En tant que | Je veux                                                   | Afin de                          |
| ------ | ----------- | --------------------------------------------------------- | -------------------------------- |
| ACT-01 | Consultant  | Logger un appel, email, reunion ou note                   | Garder une trace de mes echanges |
| ACT-02 | Consultant  | Rattacher une activite a un compte, contact et/ou affaire | Contextualiser l'activite        |
| ACT-03 | Consultant  | Planifier une prochaine action avec date                  | Ne rien oublier                  |
| ACT-04 | Consultant  | Creer une tache avec priorite et echeance                 | Organiser mon travail            |
| ACT-05 | Consultant  | Voir la timeline chronologique d'un client                | Retracer l'historique            |
| ACT-06 | Consultant  | Voir mes taches a faire triees par urgence                | Prioriser mes actions            |

#### Regles metier

- Une activite doit etre rattachee a au moins un des trois objets (compte, contact, affaire)
- La selection d'un contact pre-remplit le compte associe
- La selection d'une affaire pre-remplit le compte et le contact principal
- Les taches affichent un badge couleur selon la priorite et la proximite de l'echeance
- Les taches en retard (echeance depassee + statut "AFaire" ou "EnCours") sont mises en evidence

---

### 4.8 Module Vue 360° Client

#### Description

Page dedied par entreprise regroupant toutes les informations en un seul ecran. Structure en sections/onglets :

**Section Header** :

- Nom entreprise, logo, secteur, taille, score priorite
- Boutons : Modifier, Creer activite, Creer affaire

**Section Contacts** :

- Liste des contacts rattaches (cartes avec nom, poste, email, telephone)
- Badge "Decisionnaire" si applicable
- Bouton creer contact

**Section Pipeline** :

- Mini Kanban des affaires en cours (statuts Prospect a Negociation)
- Affaires Gagnees/Perdues recentes

**Section Documents** :

- Tabs : Devis / Commandes / Factures
- Tableau par tab avec numero, date, statut, montant TTC
- Badge couleur par statut

**Section Historique** :

- Timeline chronologique inversee (plus recente en haut)
- Tous types : activites + evenements systeme (devis envoye, facture payee, etc.)

**Section KPIs Client** :

- CA total signe (somme factures payees)
- CA en cours (somme commandes actives)
- CA pipeline (somme affaires ponderees)
- Taux de transformation (affaires gagnees / total affaires closes)
- Delai moyen de paiement (jours entre emission et paiement)
- Nombre d'affaires actives

---

### 4.9 Module Dashboard

#### Filtres globaux

Le dashboard dispose de filtres combinables en haut de page :

**Filtre periode** :

- **Predefinis** : Ce mois, Ce trimestre, Cette annee, 12 derniers mois
- **Personnalise** : Date debut + Date fin
- Par defaut : "12 derniers mois"

**Filtre entreprise** :

- Select "Toutes les entreprises" + liste des entreprises depuis useAccounts
- Filtre toutes les donnees (deals, factures, devis) par accountId

**Filtre source** :

- Select "Toutes les sources" + liste DealSource (Malt, LinkedIn, Recommandation, etc.)
- Filtre les deals par source d'acquisition

**Cross-filtering interactif (style Power BI)** :

- Clic sur une barre du Pipeline => filtre tous les graphiques/KPIs par ce stage
- Clic sur une part du PieChart Sources => filtre par cette source
- Clic sur un point du CA mensuel => filtre par ce mois
- Clic sur une affaire Top 5 => navigue vers le detail
- Re-clic pour desactiver le filtre
- Elements non filtres affiches en opacite 0.3

**Badges filtres actifs** :

- Chaque filtre actif affiche un badge cliquable (X pour supprimer)
- Bouton "Effacer tout" pour reinitialiser

**Technique** :

- Toutes les donnees chargees dynamiquement depuis les services (useDeals, useInvoices, useQuotes, useTasks, useAccounts)
- KPIs et graphiques calcules en temps reel via useMemo
- Filtrage en cascade : chaque graphique exclut son propre filtre (le pipeline reste visible quand on filtre par stage)

#### KPIs globaux (cartes en haut)

| KPI                | Calcul                                                                                 |
| ------------------ | -------------------------------------------------------------------------------------- |
| CA Signe (periode) | Somme des montants des affaires Gagnees dans la periode (filtrees par actualCloseDate) |
| CA Pipeline        | Somme montants ponderes des affaires en cours (ni Gagne ni Perdu)                      |
| Taux de conversion | Affaires gagnees / (gagnees + perdues) sur la periode                                  |
| Factures en retard | Nombre + montant total des factures avec statut EnRetard                               |
| Devis en attente   | Nombre de devis en statut Envoye                                                       |
| Taches urgentes    | Nombre de taches Haute priorite a echeance < 3 jours                                   |

#### Graphiques

| Graphique              | Type                 | Donnees                                             |
| ---------------------- | -------------------- | --------------------------------------------------- |
| Pipeline par etape     | Bar chart horizontal | Nombre + montant par stage (Prospect a Negociation) |
| CA mensuel             | Line chart           | CA facture par mois (12 derniers mois)              |
| Repartition par source | Pie chart            | Nombre d'affaires par source (Malt, LinkedIn, etc.) |
| Evolution pipeline     | Area chart           | Montant pipeline par mois (tendance)                |

#### Listes

- **Top 5 affaires en cours** : triees par montant pondere decroissant, avec entreprise, montant, probabilite, date estimee
- **Activites recentes** : 10 dernieres activites, avec type, sujet, compte, date
- **Taches urgentes** : taches a echeance < 7 jours, triees par priorite puis date

#### Alertes

- Devis expires non traites (statut Envoye + date validite depassee)
- Factures en retard > 15 jours
- Affaires sans activite depuis > 30 jours
- Taches en retard

---

### 4.10 Module Email Templates & Tracking

#### Description

Systeme complet de gestion de templates email avec variables dynamiques et suivi des envois.

#### User Stories

| ID     | En tant que | Je veux                                                               | Afin de                                   |
| ------ | ----------- | --------------------------------------------------------------------- | ----------------------------------------- |
| EML-01 | Consultant  | Creer des templates email avec variables dynamiques                   | Gagner du temps sur les envois repetitifs |
| EML-02 | Consultant  | Envoyer un email depuis un devis/facture/contact                      | Communiquer directement depuis le CRM     |
| EML-03 | Consultant  | Voir l'historique des emails envoyes                                  | Suivre ma communication                   |
| EML-04 | Consultant  | Inserer des variables ({{contact.firstName}}, {{quote.number}}, etc.) | Personnaliser automatiquement             |

#### Details techniques

- **Variables disponibles** : contact (prenom, nom, email), account (nom), quote (numero, montant, validite), invoice (numero, montant, echeance, solde), company (infos emetteur), today
- **Categories templates** : Relance devis, Envoi facture, Relance paiement, Remerciement, Prospection, Custom
- **Logs** : chaque email envoye est trace avec destinataire, sujet, template utilise, entite liee, statut
- **Dialog reutilisable** : SendEmailDialog peut etre ouvert depuis devis detail, facture detail, contact detail

---

### 4.11 Module Automatisations / Workflows

#### Description

Moteur de regles automatiques configurables : Trigger → Condition(s) → Action.

#### User Stories

| ID     | En tant que | Je veux                                                                     | Afin de                        |
| ------ | ----------- | --------------------------------------------------------------------------- | ------------------------------ |
| WKF-01 | Consultant  | Creer une regle automatique (ex: si devis envoye > 7j, creer tache relance) | Ne rien oublier                |
| WKF-02 | Consultant  | Activer/desactiver une regle                                                | Controler les automatismes     |
| WKF-03 | Consultant  | Voir le log d'execution des regles                                          | Verifier le bon fonctionnement |
| WKF-04 | Consultant  | Definir des conditions (montant > X, delai > N jours)                       | Cibler les automatismes        |

#### Triggers disponibles

quote_sent, quote_expired, quote_accepted, invoice_issued, invoice_overdue, invoice_paid, deal_stage_changed, deal_won, deal_lost, deal_inactive, task_overdue

#### Actions disponibles

create_task, create_activity, send_email (template), change_status, notify (toast)

#### Regles par defaut

1. Relance devis 7j (quote_sent + daysSince > 7 → create_task)
2. Alerte facture retard (invoice_overdue → notify)
3. Email relance paiement 30j (invoice_overdue + daysSince > 30 → send_email)
4. Tache apres affaire gagnee (deal_won → create_task)
5. Notification affaire inactive (deal_inactive + daysSince > 30 → notify)

---

### 4.12 Module Objectifs & Gamification

#### Description

Systeme d'objectifs mensuels/trimestriels/annuels avec barres de progression et achievements (trophees) pour motiver et mesurer la performance.

#### User Stories

| ID     | En tant que | Je veux                                          | Afin de                     |
| ------ | ----------- | ------------------------------------------------ | --------------------------- |
| GOL-01 | Consultant  | Definir des objectifs CA/deals/devis par periode | Mesurer ma performance      |
| GOL-02 | Consultant  | Voir ma progression en temps reel                | Rester motive               |
| GOL-03 | Consultant  | Debloquer des trophees en atteignant des jalons  | Gamifier mon activite       |
| GOL-04 | Consultant  | Voir mes trophees debloques vs verrouilles       | Suivre mes accomplissements |

#### Metriques objectifs

revenue_signed, deals_won, deals_created, quotes_sent, invoices_paid, conversion_rate, activities_logged

#### Achievements (10 trophees)

- Premier pas (1ere affaire), Closer (5 gagnees), Machine a devis (10 devis), Cash collector (0 retard 30j), 100K Club (100k CA), Marathonien (50 activites), Sniper (conversion > 80%), Full pipeline (10 affaires en cours), Serial winner (3 gagnees en 1 mois), Zero retard (toutes taches a temps)

---

### 4.13 Module Import/Export

#### Description

Import de donnees depuis CSV et LinkedIn, export CSV de toutes les entites.

#### User Stories

| ID     | En tant que | Je veux                                                       | Afin de                      |
| ------ | ----------- | ------------------------------------------------------------- | ---------------------------- |
| IMP-01 | Consultant  | Exporter mes entreprises/contacts/deals/factures en CSV       | Analyser dans Excel          |
| IMP-02 | Consultant  | Importer des contacts depuis un fichier CSV                   | Alimenter ma base rapidement |
| IMP-03 | Consultant  | Coller un profil LinkedIn et creer un contact automatiquement | Prospecter efficacement      |
| IMP-04 | Consultant  | Voir un apercu avant import et les erreurs                    | Controler la qualite         |

#### Details techniques

- **Export CSV** : separateur ; avec BOM pour Excel FR, colonnes traduites en francais
- **Import CSV** : detection automatique separateur (; ou ,), validation ligne par ligne, rapport d'erreurs
- **Parser LinkedIn** : detecte nom, poste, entreprise, localisation depuis le texte colle
- **Export complet** : fichier multi-sections (comptes + contacts + affaires)

---

### 4.14 Module Historique & Audit Trail

#### Description

Trace complete de toutes les modifications sur toutes les entites du CRM.

#### User Stories

| ID     | En tant que | Je veux                                              | Afin de                            |
| ------ | ----------- | ---------------------------------------------------- | ---------------------------------- |
| AUD-01 | Consultant  | Voir l'historique de toutes les modifications        | Tracer les changements             |
| AUD-02 | Consultant  | Filtrer par type d'entite, action, periode           | Retrouver un changement specifique |
| AUD-03 | Consultant  | Voir le detail d'une modification (ancien → nouveau) | Comprendre ce qui a change         |
| AUD-04 | Consultant  | Voir les statistiques de modifications               | Mesurer l'activite CRM             |

#### Entites tracees

account, contact, deal, quote, order, invoice, activity, task, payment, workflow, email

#### Actions tracees

create, update, delete, status_change, stage_change, email_sent, payment_added, payment_removed, pdf_generated, import

#### Details techniques

- **Timeline verticale** avec icones par entite et badges couleur par action
- **Dates relatives** (il y a 2 heures) + date absolue au survol
- **Detail expandable** : tableau ancien/nouveau pour chaque champ modifie (rouge barre → vert)
- **Statistiques** : compteurs par action + graphique barres 7 derniers jours
- **Filtres** : type entite, type action, recherche texte, periode

---

## 5. Specifications PDF

### 5.1 Template Devis

**Dimensions** : A4 portrait (210 x 297 mm)
**Marges** : 20mm top, 15mm sides, 20mm bottom

**Structure** :

```
┌─────────────────────────────────────────┐
│  [Logo]         DEVIS N° DEV-2026-001  │
│                 Date : 20/03/2026       │
│                 Validite : 19/04/2026   │
├─────────────────────────────────────────┤
│  EMETTEUR              DESTINATAIRE     │
│  {{NOM_ENTREPRISE}}      Entreprise X     │
│  Adresse               Adresse          │
│  SIREN {{SIREN}}         SIREN client     │
│  Email / Tel           Contact / Email  │
├─────────────────────────────────────────┤
│  Objet : [Titre de l'affaire]          │
├─────────────────────────────────────────┤
│  # │ Designation     │ Qte │ PU HT │ TVA │ Total HT │
│  1 │ Consulting PA   │  5  │ 800€  │ 20% │ 4000,00€ │
│  2 │ Formation PBI   │  2  │ 1200€ │ 20% │ 2400,00€ │
│ ...│                 │     │       │     │          │
├─────────────────────────────────────────┤
│                        Total HT : XXX€  │
│                        TVA 20% : XXX€   │
│                        Total TTC : XXX€ │
├─────────────────────────────────────────┤
│  CONDITIONS :                           │
│  - Delai de validite : 30 jours         │
│  - Conditions de paiement...            │
│  [Conditions custom du devis]           │
├─────────────────────────────────────────┤
│  [Bon pour accord]                      │
│  Date :         Signature :             │
├─────────────────────────────────────────┤
│  Page 1/1                               │
│  {{NOM_ENTREPRISE}} - SIREN ...           │
└─────────────────────────────────────────┘
```

**Police** : Inter ou Helvetica
**Couleurs** : Header bleu fonce (#1e293b), texte noir (#0f172a), accents bleu (#3b82f6)

---

### 5.2 Template Facture

Structure similaire au devis avec les differences suivantes :

- Titre : "FACTURE N° FAC-2026-001" (au lieu de DEVIS)
- Ajout : date d'echeance de paiement
- Ajout : coordonnees bancaires (IBAN/BIC)
- Ajout : mentions legales obligatoires en pied :
  - Micro-entreprise / EI : "TVA non applicable, art. 293 B du CGI" (si applicable) OU mentions TVA standard
  - Penalites de retard : "En cas de retard de paiement, une penalite de 3 fois le taux d'interet legal sera appliquee..."
  - Indemnite forfaitaire de recouvrement : 40€
  - Numero SIREN, forme juridique
- Pas de bloc "Bon pour accord / Signature"
- Si avoir : mention "AVOIR" en rouge + reference a la facture originale

---

## 6. Flux Power Automate

### 6.1 Flow : Envoi Devis par Email

**Trigger** : HTTP Request (POST)

**Input JSON** :

```json
{
  "to": "contact@entreprise.com",
  "cc": "",
  "subject": "Devis DEV-2026-001 - {{NOM_ENTREPRISE}}",
  "body": "<html>Bonjour [Prenom],<br><br>Veuillez trouver ci-joint notre devis...<br><br>Cordialement,<br>{{NOM_AUTEUR}}</html>",
  "attachmentName": "DEV-2026-001.pdf",
  "attachmentBase64": "base64encodedPDF..."
}
```

**Actions** :

1. Parse JSON (schema des inputs)
2. Send an email (V2) via connecteur Office 365 Outlook
3. Response HTTP 200 avec `{ "success": true, "messageId": "..." }`

**Cote React** :

```typescript
// email-service.ts
async sendQuoteEmail(quoteId: string, pdfBase64: string): Promise<void> {
  const flowUrl = settingsService.get('power_automate_email_url');
  const response = await fetch(flowUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ to, cc, subject, body, attachmentName, attachmentBase64 }),
  });
  if (!response.ok) throw new Error('Email send failed');
}
```

### 6.2 Flow : Envoi Facture par Email

Meme structure que le flow devis avec :

- Sujet : "Facture FAC-2026-001 - {{NOM_ENTREPRISE}}"
- Corps adapte (mention echeance de paiement, coordonnees bancaires)

### 6.3 Flow : Notification Relance Facture

**Trigger** : Recurrence (quotidien, 8h00)

**Actions** :

1. List rows (Dataverse) : factures ou `cds_status` = "EnRetard" et `cds_due_date` < aujourd'hui - 7 jours
2. Pour chaque facture : envoyer email de relance au contact
3. Logger l'activite de relance (optionnel via HTTP callback)

---

## 7. Maquettes fonctionnelles

### 7.1 Layout general

```
┌──────────────────────────────────────────────────┐
│  [Logo]  CRM Affaires    [Recherche...]  [U] │
├──────┬───────────────────────────────────────────┤
│      │                                           │
│  📊  │                                           │
│  🏢  │         Zone de contenu principale        │
│  👤  │                                           │
│  💼  │         (varie selon la page active)       │
│  📄  │                                           │
│  📦  │                                           │
│  💰  │                                           │
│  📋  │                                           │
│      │                                           │
│      │                                           │
│      │                                           │
│      │                                           │
├──────┴───────────────────────────────────────────┤
│  {{NOM_ENTREPRISE}} - v1.0                          │
└──────────────────────────────────────────────────┘
```

**Sidebar** (collapsible) :

- Dashboard (accueil)
- Entreprises
- Contacts
- Affaires
- Devis
- Commandes
- Factures
- Activites

**Header** : Logo, nom app, barre de recherche globale, initiales utilisateur

### 7.2 Ecran Dashboard

```
┌─────────────────────────────────────────────────────┐
│  [CA Signe]  [Pipeline]  [Conversion]  [En retard]  │
│   125 000€    85 000€      72%          3 factures   │
├──────────────────────┬──────────────────────────────┤
│  Pipeline par etape  │  CA mensuel (12 mois)        │
│  ████████ Prospect   │  ─────────/\──────           │
│  ██████ Qualif       │         /    \  /\           │
│  ████ Proposition    │  ──────/      \/  \───       │
│  ██ Negociation      │                               │
├──────────────────────┼──────────────────────────────┤
│  Top 5 affaires      │  Taches urgentes              │
│  1. RATP - 35k€      │  ☐ Relancer devis Sanofi (H) │
│  2. Sanofi - 22k€    │  ☐ Envoyer facture GSK (M)   │
│  3. GSK - 18k€       │  ☐ Preparer demo RATP (H)    │
│  ...                 │  ...                          │
├──────────────────────┴──────────────────────────────┤
│  ⚠ Alertes                                          │
│  - 2 devis expires non traites                       │
│  - 1 facture en retard > 30 jours                   │
│  - 3 affaires sans activite depuis 30j              │
└─────────────────────────────────────────────────────┘
```

### 7.3 Ecran Affaires - Vue Kanban

```
┌─────────────────────────────────────────────────────────────────┐
│  Affaires   [Vue Kanban ▼]  [+ Nouvelle affaire]  [Filtres]    │
├───────────┬───────────┬───────────┬───────────┬───────────┬─────┤
│ PROSPECT  │ QUALIF.   │ PROPOSIT. │ NEGOCIAT. │ GAGNE     │PERDU│
│  (45k€)   │  (22k€)   │  (35k€)   │  (18k€)   │  (65k€)   │     │
│┌─────────┐│┌─────────┐│┌─────────┐│┌─────────┐│┌─────────┐│     │
││ RATP    │││ Sanofi  │││ GSK     │││ Vinci   │││ RATP    ││     │
││ 35k€    │││ 12k€    │││ 20k€    │││ 18k€    │││ 35k€    ││     │
││ 10%     │││ 25%     │││ 50%     │││ 75%     │││ 100%    ││     │
││ [Malt]  │││[Linked] │││[Recom.] │││[Linked] │││[Malt]   ││     │
│└─────────┘│└─────────┘│└─────────┘│└─────────┘│└─────────┘│     │
│┌─────────┐│           │┌─────────┐│           │           │     │
││ GSK     ││           ││ Sanofi  ││           │           │     │
││ 10k€    ││           ││ 15k€    ││           │           │     │
│└─────────┘│           │└─────────┘│           │           │     │
└───────────┴───────────┴───────────┴───────────┴───────────┴─────┘
```

### 7.4 Ecran Devis - Formulaire

```
┌─────────────────────────────────────────────────────┐
│  Devis DEV-2026-003    Statut : [Brouillon ▼]      │
│                                                      │
│  Affaire : [RATP - Mission Power BI ▼]              │
│  Contact : [Jean Dupont ▼]                          │
│  Date emission : [20/03/2026]  Validite : [30 jours]│
├─────────────────────────────────────────────────────┤
│  LIGNES DE PRESTATION                    [+ Ligne]  │
│┌───┬──────────────────┬─────┬────────┬─────┬───────┐│
││ # │ Designation      │ Qte │ PU HT  │ TVA │ Total ││
│├───┼──────────────────┼─────┼────────┼─────┼───────┤│
││ 1 │ Consulting PA    │  5  │  800€  │ 20% │ 4000€ ││
││ 2 │ Formation PBI    │  2  │ 1200€  │ 20% │ 2400€ ││
││ 3 │ Support mensuel  │  3  │  500€  │ 20% │ 1500€ ││
│└───┴──────────────────┴─────┴────────┴─────┴───────┘│
│                                                      │
│  Remise globale : [0] %     Total HT :   7 900,00 € │
│                              TVA 20% :   1 580,00 € │
│                              Total TTC :  9 480,00 € │
├─────────────────────────────────────────────────────┤
│  Conditions : [_________________________________]    │
│  Notes internes : [_____________________________]    │
├─────────────────────────────────────────────────────┤
│  [Sauvegarder]  [Apercu PDF]  [Envoyer]  [Dupliquer]│
└─────────────────────────────────────────────────────┘
```

### 7.5 Ecran Facture - Detail

```
┌─────────────────────────────────────────────────────┐
│  Facture FAC-2026-002   Statut : [Emise]            │
│  Commande : CMD-2026-002                            │
│  Entreprise : Sanofi    Contact : Marie Martin      │
│  Emise le : 15/03/2026  Echeance : 14/04/2026      │
├─────────────────────────────────────────────────────┤
│  [Lignes de facture - tableau identique au devis]   │
│                              Total TTC :  9 480,00 € │
├─────────────────────────────────────────────────────┤
│  SUIVI DE PAIEMENT                                   │
│┌────────────┬──────────┬────────────┬───────────────┐│
││ Date       │ Montant  │ Mode       │ Reference     ││
│├────────────┼──────────┼────────────┼───────────────┤│
││ 20/03/2026 │ 5 000€   │ Virement   │ VIR-42789    ││
│├────────────┼──────────┼────────────┼───────────────┤│
││            │          │            │               ││
│└────────────┴──────────┴────────────┴───────────────┘│
│  [+ Enregistrer un paiement]                         │
│                                                      │
│  Paye : 5 000,00 €    Reste du : 4 480,00 €         │
├─────────────────────────────────────────────────────┤
│  [Telecharger PDF]  [Envoyer par email]  [Avoir]    │
└─────────────────────────────────────────────────────┘
```

### 7.6 Ecran Vue 360° Client

```
┌─────────────────────────────────────────────────────┐
│  [Logo]  RATP                    Score : ★★★★☆ 85   │
│  Secteur : Transport  Taille : GE                    │
│  [Modifier]  [+ Activite]  [+ Affaire]              │
├──────────────────────┬──────────────────────────────┤
│  KPIs CLIENT         │  CONTACTS                     │
│  CA total : 65 000€  │  👤 Jean Dupont - DSI ★       │
│  CA en cours : 35k€  │  👤 Marie Martin - Chef projet│
│  Pipeline : 22k€     │  👤 Paul Durand - Acheteur    │
│  Conversion : 75%    │  [+ Contact]                  │
│  Delai paie : 28j    │                               │
├──────────────────────┴──────────────────────────────┤
│  [Affaires] [Devis] [Commandes] [Factures]          │
│┌─────────┬────────────┬──────────┬─────────────────┐│
││ Titre   │ Statut     │ Montant  │ Date            ││
│├─────────┼────────────┼──────────┼─────────────────┤│
││ PBI V2  │ Negociation│ 18 000€  │ 15/04/2026     ││
││ PA Form │ Gagne      │ 35 000€  │ 01/02/2026     ││
│└─────────┴────────────┴──────────┴─────────────────┘│
├─────────────────────────────────────────────────────┤
│  HISTORIQUE                                          │
│  📞 20/03 - Appel Jean Dupont - Point projet PBI    │
│  📧 18/03 - Email devis envoye FAC-2026-002        │
│  📋 15/03 - Facture emise FAC-2026-002              │
│  🤝 10/03 - Reunion kick-off PA Forms               │
│  ...                                                 │
└─────────────────────────────────────────────────────┘
```

---

## 8. Roadmap de developpement

### Phase 1 : Fondations (Semaine 1-2) - 10 jours

| Tache                                                                   | Estimation |
| ----------------------------------------------------------------------- | ---------- |
| Scaffold projet (template starter)                                      | 0.5j       |
| Configuration Dataverse : creation des 14 tables + colonnes + relations | 2j         |
| Service layer : DataverseService (Mock + Production + Proxy)            | 1.5j       |
| Auth Provider (window.**POWER_APPS_CONTEXT**)                           | 0.5j       |
| Layout principal (sidebar, header, routing)                             | 1j         |
| Composants partages (DataTable, SearchBar, StatusBadge, etc.)           | 1.5j       |
| Service de numerotation automatique                                     | 0.5j       |
| Service de parametres (cds_settings)                                    | 0.5j       |
| Tests Mock data + navigation complete                                   | 1j         |
| Premier deploiement `pac code push` + validation runtime                | 1j         |

### Phase 2 : Modules principaux (Semaine 3-5) - 15 jours

| Tache                                                           | Estimation |
| --------------------------------------------------------------- | ---------- |
| Module Entreprises : CRUD + liste + recherche + filtres         | 2j         |
| Module Contacts : CRUD + rattachement entreprise + liste        | 1.5j       |
| Module Affaires : CRUD + Kanban + liste + regles metier         | 3j         |
| Module Activites : CRUD + timeline + rattachement polymorphique | 2j         |
| Module Taches : CRUD + liste triee + badges priorite            | 1j         |
| Vue 360° Client : page composee + KPIs                          | 2j         |
| Tests integration + corrections                                 | 2j         |
| Deploiement intermediaire                                       | 0.5j       |
| Buffer imprevus                                                 | 1j         |

### Phase 3 : Cycle commercial (Semaine 6-8) - 15 jours

| Tache                                                                  | Estimation |
| ---------------------------------------------------------------------- | ---------- |
| Module Devis : formulaire + lignes editables + calculs                 | 3j         |
| Module Commandes : conversion devis + CRUD + PJ                        | 1.5j       |
| Module Factures : generation + CRUD + suivi paiement                   | 3j         |
| Generation PDF devis (react-pdf template)                              | 2j         |
| Generation PDF facture (react-pdf template)                            | 1.5j       |
| Flux Power Automate : envoi email devis + facture                      | 1j         |
| Duplication devis + conversion devis > commande > facture              | 1j         |
| Tests cycle complet : prospect > devis > commande > facture > paiement | 1.5j       |
| Buffer imprevus                                                        | 0.5j       |

### Phase 4 : Dashboard & Polish (Semaine 9-10) - 10 jours

| Tache                                                        | Estimation |
| ------------------------------------------------------------ | ---------- |
| Dashboard : KPIs + 4 graphiques Recharts                     | 2.5j       |
| Alertes dashboard (devis expires, factures retard, etc.)     | 1j         |
| Recherche globale multi-entite                               | 1j         |
| Optimisation performances (pagination, cache Tanstack Query) | 1.5j       |
| Responsive / polish UI                                       | 1.5j       |
| Tests end-to-end complet                                     | 1.5j       |
| Documentation utilisateur                                    | 0.5j       |
| Deploiement final + validation production                    | 0.5j       |

### Phase 5 : Features avancees (Semaine 11-14) - 20 jours

| Tache                                                             | Estimation |
| ----------------------------------------------------------------- | ---------- |
| Email Templates : types + service + page + editeur + dialog envoi | 3j         |
| Email Tracking : logs + historique + integration devis/factures   | 1.5j       |
| Automatisations : types + service + page + editeur visuel + cards | 3j         |
| Objectifs : types + service + page + barres progression           | 2j         |
| Gamification : achievements + cards + conditions + summary        | 2j         |
| Import CSV : parser + preview + validation + rapport erreurs      | 2j         |
| Export CSV : 4 entites + export complet + BOM Excel FR            | 1j         |
| Import LinkedIn : parser profil + formulaire pre-rempli           | 1j         |
| Audit Trail : types + service + timeline + detail changements     | 2.5j       |
| Audit Stats : compteurs + graphique barres 7 jours                | 1j         |
| Integration + tests + corrections                                 | 1j         |

### Resume

| Phase                        | Duree           | Jours        |
| ---------------------------- | --------------- | ------------ |
| Phase 1 : Fondations         | Semaine 1-2     | 10j          |
| Phase 2 : Modules principaux | Semaine 3-5     | 15j          |
| Phase 3 : Cycle commercial   | Semaine 6-8     | 15j          |
| Phase 4 : Dashboard & Polish | Semaine 9-10    | 10j          |
| Phase 5 : Features avancees  | Semaine 11-14   | 20j          |
| **Total**                    | **14 semaines** | **70 jours** |

---

## 9. Points d'attention techniques

### 9.1 Pieges Power Apps Code Apps connus

| Piege                                                                      | Impact                                                                      | Solution                                                                                         |
| -------------------------------------------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| SDK `@microsoft/power-apps` n'a pas de root export                         | Import en erreur au build                                                   | Toujours importer `@microsoft/power-apps/data` et `@microsoft/power-apps/app`                    |
| `verbatimModuleSyntax` actif par defaut                                    | Erreurs TS sur les imports de types                                         | Utiliser `import type { ... }` pour tous les types                                               |
| CSP bloque eval() et new Function()                                        | Crash runtime en production PA                                              | Ne JAMAIS utiliser `require()`, `eval()`, `new Function()`. Verifier les deps.                   |
| Champs Dataverse en PascalCase                                             | Mapping systematique necessaire                                             | Creer des fonctions mapToEntity / mapFromEntity pour chaque table                                |
| Enums sans accents dans les types TS                                       | Incoherence affichage/stockage                                              | Types TS sans accents + labels UI avec accents (dictionnaire)                                    |
| React Router BASENAME Power Apps                                           | 404 si mauvais basename                                                     | NE PAS TOUCHER le basename configure par le template starter                                     |
| Dark mode OS qui s'applique                                                | UI illisible dans Power Apps                                                | Forcer `<ThemeProvider defaultTheme="light">`                                                    |
| import.meta.env.DEV                                                        | Mauvaise detection environnement                                            | Utiliser `import.meta.env.DEV` (Vite), jamais `process.env`                                      |
| File columns Dataverse                                                     | Upload/download specifique                                                  | Utiliser l'API Dataverse file management pour les PJ                                             |
| Recharts onClick handlers types incompatibles                              | Build Vite échoue alors que tsc passe                                       | Caster les handlers onClick en `unknown` ou utiliser des wrappers typés                          |
| Zod v4 + zodResolver incompatible                                          | Types `unknown` au lieu de `number` dans les formulaires                    | Utiliser `standardSchemaResolver` de `@hookform/resolvers/standard-schema`                       |
| `tsc --noEmit` passe mais `npm run build` échoue                           | Vite est plus strict sur les generic types                                  | TOUJOURS valider avec `npm run build` avant `pac code push`, pas juste `tsc`                     |
| Utiliser getClient() manuellement au lieu des services générés             | Données mock en production (fallback silencieux)                            | TOUJOURS utiliser les services dans src/generated/services/ générés par pac code add-data-source |
| PowerShell `Compress-Archive` pour ZIP solution avec `[Content_Types].xml` | Le fichier avec crochets est ignoré = ZIP invalide = import solution échoue | Utiliser Python `zipfile` ou 7-Zip pour créer le ZIP de solution                                 |
| `[Content_Types].xml` doit être nommé AVEC les crochets                    | Sans ce fichier le ZIP n'est pas reconnu comme solution valide              | Ne JAMAIS renommer ce fichier, vérifier sa présence dans le ZIP avant import                     |
| `@ts-expect-error` sur les imports SDK quand le SDK est installé           | Le commentaire masque de vraies erreurs de type = bugs silencieux           | Supprimer `@ts-expect-error` une fois le SDK installé et les types résolus                       |
| `createServiceProxy<T>` sans type generic explicite                        | Mock pas assignable à Production = erreur TS build                          | Toujours spécifier le generic : `createServiceProxy<IAccountService>(...)`                       |
| `retrieveMultipleRecords()` n'existe pas dans le SDK Code Apps             | Méthode inventée, crash runtime                                             | Utiliser `getAll()` du service généré (Cds_xxxService)                                           |
| `power.config.json` ignoré comme source de vérité                          | Les noms de tables/data sources sont dans ce fichier                        | Consulter `power.config.json > databaseReferences` pour les noms exacts des tables               |
| `pac solution init` non utilisé pour structurer la solution                | Structure ZIP artisanale = erreurs de format                                | Utiliser `pac solution init` pour créer une structure de solution valide avec les bons fichiers  |
| Choice/Picklist envoyés comme strings au lieu d'entiers                    | Erreur silencieuse Dataverse, fallback Mock                                 | Mapping bidirectionnel string↔int via `enum-mappings.ts` (ex: 'Actif'→144950000)                 |
| Proxy createServiceProxy avec fallback sticky (useMock=true permanent)     | UNE erreur bascule TOUT sur Mock définitivement                             | Fallback par appel uniquement + console.error pour diagnostic                                    |

### 9.1bis Règle d'auto-amélioration continue

Chaque erreur technique rencontrée doit être documentée dans ce CDC (section 9.1) ET dans le COWORK (section A8) pour éviter de la reproduire. Format : `| Piège | Impact | Solution |`

**En cas de doute ou d'échec technique :**

1. STOPPER l'improvisation
2. Consulter la doc officielle Microsoft via Context7 (`/websites/learn_microsoft_en-us_power-apps`)
3. Appliquer la solution documentée
4. Ajouter le piège dans la table section 9.1

### 9.2 Decisions architecturales cles

**Numerotation** : la table `cds_numbering` evite les conflits de numerotation. L'increment est fait cote client avec optimistic locking (verifier le numero avant de sauver, reessayer en cas de conflit). En usage mono-utilisateur, le risque de collision est negligeable.

**Calculs financiers** : tous les calculs HT/TVA/TTC sont faits cote client (React) et stockes dans Dataverse. Les montants calcules (`cds_line_total_ht`, etc.) sont persistes pour performance et coherence. En cas de modification d'une ligne, tous les totaux du document sont recalcules et sauves.

**PDF** : la generation PDF se fait entierement cote client via react-pdf/renderer. Le PDF est converti en base64 et envoye a Power Automate pour l'email. Pas de stockage PDF cote serveur (regenere a la demande).

**Recherche globale** : requete Dataverse sur les tables Account (name), Contact (first_name, last_name, email), Deal (name) avec Tanstack Query et debounce 300ms. Resultats groupes par type.

**Cache** : Tanstack Query avec staleTime de 5 minutes pour les listes, 1 minute pour les details. Invalidation selective apres chaque mutation (invalidateQueries par cle).

### 9.3 Limites et evolutions futures

| Limitation actuelle           | Evolution possible                                       |
| ----------------------------- | -------------------------------------------------------- |
| Mono-utilisateur              | Ajouter table cds_user + filtres par proprietaire        |
| Pas de multi-devise           | Ajouter colonne devise + taux de change                  |
| PDF template fixe             | Template PDF configurable (Markdown > PDF ou HTML > PDF) |
| Pas d'import/export CSV       | Module import contacts/entreprises depuis CSV            |
| Pas de previsionnel           | Module forecast avec projections CA                      |
| Relances manuelles            | Automatisation relances a J+7, J+15, J+30 via PA         |
| Pas de rapports avances       | Power BI embedded pour reporting avance                  |
| Pas de signature electronique | Integration DocuSign ou Yousign                          |

### 9.4 Exigences d'implementation par module

Chaque module fonctionnel DOIT etre livre avec l'ensemble des couches suivantes, **entierement fonctionnelles** (pas de squelettes, pas de pages vides, pas de valeurs hardcodees) :

| Couche           | Fichier(s)                                                | Description                                                      |
| ---------------- | --------------------------------------------------------- | ---------------------------------------------------------------- |
| Types            | `src/lib/types/<entity>.ts`                               | Types TS + Input + Filters                                       |
| Mock data        | `src/lib/services/mock-data*.ts`                          | Donnees realistes (min 5 enregistrements avec relations)         |
| Service          | `src/lib/services/<entity>-service.ts`                    | Interface + MockService + ProductionService + createServiceProxy |
| Hooks            | `src/lib/hooks/use-<entities>.ts`                         | TanStack Query queries + mutations + toast + cache invalidation  |
| Schema           | `src/lib/schemas/<entity>.ts`                             | Validation Zod v4 + type FormValues exporte                      |
| Colonnes         | `src/components/<entities>/<entity>-columns.tsx`          | Definitions TanStack Table avec formatage, badges, actions       |
| Formulaire       | `src/components/<entities>/<entity>-form.tsx`             | Champs react-hook-form avec labels francais                      |
| Page liste       | `src/pages/<entities>/<entity>-list.tsx`                  | DataTable + SearchBar + FilterPanel + bouton Nouveau + actions   |
| Page detail/form | `src/pages/<entities>/<entity>-form-page.tsx` (si lignes) | Formulaire pleine page avec editeur de lignes si applicable      |
| Routes           | `src/router.tsx`                                          | Lazy-loaded avec Suspense                                        |

**Regles :**

- Aucune page ne doit afficher uniquement un titre avec "Gestion des..." sans contenu
- Les boutons "Nouveau" doivent etre presents et fonctionnels des la livraison
- Les donnees mock doivent avoir des relations coherentes entre entites
- Les calculs financiers doivent utiliser roundTo2() et les fonctions de utils.ts
- Les formulaires doivent utiliser les labels francais (enum-labels.ts)
- Le dashboard doit etre connecte aux donnees reelles de tous les services
- Les services doivent implementer toutes les regles metier du CDC (section 4)
- Chaque module avec lignes (devis, commandes, factures) doit inclure un editeur de lignes inline avec calculs temps reel HT/TVA/TTC

---

## Annexe A : Enums (Choice fields) - Reference complete

### Deal Stage

`Prospect` | `Qualification` | `Proposition` | `Negociation` | `Gagne` | `Perdu`

### Deal Source

`Malt` | `LinkedIn` | `Recommandation` | `AppelEntrant` | `SiteWeb` | `Salon` | `Autre`

### Deal Loss Reason

`Prix` | `Timing` | `Concurrent` | `Budget` | `PasDeReponse` | `Autre`

### Quote Status

`Brouillon` | `Envoye` | `Accepte` | `Refuse` | `Expire`

### Order Status

`EnAttente` | `EnCours` | `Livre` | `Annule`

### Invoice Status

`Brouillon` | `Emise` | `Payee` | `EnRetard` | `Avoir`

### Activity Type

`Appel` | `Email` | `Reunion` | `Relance` | `Note`

### Activity Outcome

`Positif` | `Neutre` | `Negatif` | `SansReponse`

### Task Priority

`Haute` | `Moyenne` | `Basse`

### Task Status

`AFaire` | `EnCours` | `Terminee` | `Annulee`

### Line Unit

`Jour` | `Heure` | `Unite` | `Forfait`

### Company Size

`TPE` | `PME` | `ETI` | `GE`

### Company Sector

`Pharma` | `IT` | `Industrie` | `BTP` | `Services` | `Transport` | `Energie` | `Autre`

### Account Status

`Actif` | `Inactif` | `Prospect`

### Contact Status

`Actif` | `Inactif`

### Contact Preference

`Email` | `Telephone` | `LinkedIn` | `Teams`

### Payment Method

`Virement` | `Cheque` | `CB` | `Autre`

### Email Template Category

`Relance` | `Facturation` | `Commercial` | `Autre`

### Email Log Status

`Envoye` | `Erreur` | `Brouillon`

### Workflow Execution Result

`Succes` | `Erreur` | `Ignore`

---

## Annexe B : Conventions de nommage

| Element                       | Convention                  | Exemple                                  |
| ----------------------------- | --------------------------- | ---------------------------------------- |
| Table Dataverse               | `cds_` + snake_case anglais | `cds_account`, `cds_quote_line`          |
| Colonne Dataverse             | `cds_` + snake_case anglais | `cds_first_name`, `cds_total_ht`         |
| Type TypeScript               | PascalCase anglais          | `Account`, `QuoteLine`, `DealStage`      |
| Propriete TypeScript          | camelCase anglais           | `firstName`, `totalHt`, `unitPrice`      |
| Composant React               | PascalCase anglais          | `AccountCard`, `QuoteLineEditor`         |
| Hook React                    | camelCase prefixe `use`     | `useAccounts`, `useDealKanban`           |
| Service                       | camelCase suffixe `Service` | `accountService`, `pdfService`           |
| Route                         | kebab-case                  | `/accounts`, `/quotes/new`, `/deals/:id` |
| Fichier                       | kebab-case                  | `account-card.tsx`, `quote-service.ts`   |
| Enum value (Choice Dataverse) | PascalCase sans accent      | `EnAttente`, `Accepte`, `Negociation`    |
| Label UI (affichage)          | Francais avec accents       | `En attente`, `Accepte`, `Negociation`   |

---

## Annexe C : Deploiement Dataverse - Creation des tables

> **PREREQUIS OBLIGATOIRE** : L'application doit etre **validee en localhost avec un dataset de test** AVANT tout deploiement. Une fois la validation terminee, le dataset de test est remplace par les vraies bases Dataverse, puis on publie. L'ordre est strict et non negociable :
>
> 1. **Validation localhost** : lancer `npm run dev`, tester TOUS les modules avec le MockService (dataset de test) — verifier navigation, formulaires, graphiques, filtres, CRUD complet (Etape 0)
> 2. Creer les tables Dataverse (Etape 1 ou script Web API)
> 3. Verifier les tables (Etape 2)
> 4. Initialiser la Code App et lier les data sources Dataverse (Etape 3 : `pac code add-data-source`)
> 5. **Remplacer le dataset de test** par les vraies bases Dataverse : brancher les ProductionService sur les services generes, supprimer/desactiver le MockService du build production (Etape 3bis)
> 6. Build et deploiement de la Code App (Etape 4 : `npm run build` + `pac code push`)
> 7. Inserer les donnees initiales (Etape 5)
> 8. Creer la solution managee pour publication (Etape 6)
>
> **NE JAMAIS publier (`pac code push`) sans avoir :**
>
> - **Valide en localhost** sur le dataset de test (MockService)
> - **Cree et lie les tables Dataverse** au prealable
> - **Branche les ProductionService** sur les vraies donnees Dataverse

### Etape 0 : Validation en localhost (OBLIGATOIRE avant deploiement)

**Objectif** : valider l'integralite de l'application sur le dataset de test (MockService) AVANT de toucher a Dataverse ou de deployer.

**Procedure :**

```bash
# Lancer le serveur de developpement local
npm run dev
```

**Checklist de validation** (chaque point doit etre OK) :

| Module      | Points a verifier                                                                                   |
| ----------- | --------------------------------------------------------------------------------------------------- |
| Dashboard   | KPIs dynamiques affiches, graphique Pipeline par etape (BarChart), graphique CA mensuel (LineChart) |
| Entreprises | Liste table/cards, creation, edition, suppression, recherche, filtres statut/taille/secteur         |
| Contacts    | Liste table/cards, creation avec ComboboxLookup entreprise, edition, suppression, filtre decideur   |
| Affaires    | Vue Kanban drag & drop, vue table, vue cards, creation avec regles metier (Gagne/Perdu), filtres    |
| Activites   | Timeline groupee par jour/semaine, creation avec 3 lookups optionnels, filtres par type             |
| Taches      | Liste par sections (A faire, En cours, Terminee), checkbox toggle statut, tri par priorite          |
| Vue 360°    | Detail entreprise avec KPIs, contacts, affaires DataTable, timeline activites                       |
| Navigation  | Sidebar, routing, breadcrumbs, retour arriere                                                       |
| Formulaires | Validation Zod, messages d'erreur, champs obligatoires (\*), soumission, annulation                 |
| Responsive  | Verification sur differentes largeurs d'ecran                                                       |

**Criteres de validation :**

- Zero erreur console (pas de warning React, pas de 404, pas de crash)
- Tous les CRUD fonctionnent (Create, Read, Update, Delete)
- Les graphiques Recharts s'affichent avec des donnees
- Les filtres et la recherche fonctionnent
- Le drag & drop Kanban deplace les affaires entre etapes
- Les formulaires valident correctement (champs requis, formats)

**Si un point echoue** : corriger le bug, relancer `npm run dev`, re-tester. NE PAS passer a l'etape suivante tant que la validation n'est pas complete.

---

### Etape 1 : Importer la solution non managee

La solution `CRMFreelance_Unmanaged.zip` contient les 21 tables Dataverse avec toutes les colonnes, relations et choice fields. Elle est de type **non managee** (unmanaged) pour permettre les modifications apres import.

**Procedure d'import :**

1. Aller sur **make.powerapps.com**
2. Selectionner l'environnement cible (ex: Production)
3. Menu lateral > **Solutions**
4. Cliquer **Importer une solution**
5. Cliquer **Parcourir** et selectionner `CRMFreelance_Unmanaged.zip`
6. Cliquer **Suivant** puis **Importer**
7. Attendre la fin de l'import (peut prendre 2-5 minutes)
8. Verifier que la solution "CRMFreelance" apparait dans la liste

### Etape 2 : Verifier les tables creees

Apres import, verifier dans **make.powerapps.com > Tables** que les 21 tables existent :

| Table               | Nom logique            | Colonnes | Relations                                                         |
| ------------------- | ---------------------- | -------- | ----------------------------------------------------------------- |
| Entreprises         | cds_account            | 17       | -                                                                 |
| Contacts            | cds_contact            | 13       | N-1 vers cds_account                                              |
| Affaires            | cds_deal               | 15       | N-1 vers cds_account, cds_contact                                 |
| Devis               | cds_quote              | 19       | N-1 vers cds_deal, cds_account, cds_contact                       |
| Lignes devis        | cds_quote_line         | 11       | N-1 vers cds_quote                                                |
| Commandes           | cds_order              | 15       | N-1 vers cds_quote, cds_deal, cds_account, cds_contact            |
| Lignes commande     | cds_order_line         | 11       | N-1 vers cds_order                                                |
| Factures            | cds_invoice            | 24       | N-1 vers cds_order, cds_quote, cds_deal, cds_account, cds_contact |
| Lignes facture      | cds_invoice_line       | 11       | N-1 vers cds_invoice                                              |
| Paiements           | cds_payment            | 6        | N-1 vers cds_invoice                                              |
| Activites           | cds_activity           | 11       | N-1 vers cds_account, cds_contact, cds_deal                       |
| Taches              | cds_task               | 9        | N-1 vers cds_account, cds_contact, cds_deal, cds_activity         |
| Numerotation        | cds_numbering          | 3        | -                                                                 |
| Parametres          | cds_settings           | 2        | -                                                                 |
| Templates email     | cds_email_template     | 5        | -                                                                 |
| Logs email          | cds_email_log          | 12       | N-1 vers cds_email_template, cds_account, cds_contact             |
| Regles workflow     | cds_workflow_rule      | 9        | -                                                                 |
| Executions workflow | cds_workflow_execution | 8        | N-1 vers cds_workflow_rule                                        |
| Objectifs           | cds_goal               | 8        | -                                                                 |
| Trophees            | cds_achievement        | 9        | -                                                                 |
| Audit               | cds_audit_entry        | 9        | -                                                                 |

### Etape 3 : Initialiser la Code App

```bash
# Se placer dans le dossier du projet
cd crm-freelance

# Initialiser la Code App (premiere fois uniquement)
pac code init --displayName "CRM Freelance" --description "CRM suivi affaires" --buildPath "dist" --fileEntryPoint "index.html"

# Ajouter les data sources Dataverse (une par table)
pac code add-data-source -a dataverse -t cds_account
pac code add-data-source -a dataverse -t cds_contact
pac code add-data-source -a dataverse -t cds_deal
pac code add-data-source -a dataverse -t cds_quote
pac code add-data-source -a dataverse -t cds_quote_line
pac code add-data-source -a dataverse -t cds_order
pac code add-data-source -a dataverse -t cds_order_line
pac code add-data-source -a dataverse -t cds_invoice
pac code add-data-source -a dataverse -t cds_invoice_line
pac code add-data-source -a dataverse -t cds_payment
pac code add-data-source -a dataverse -t cds_activity
pac code add-data-source -a dataverse -t cds_task
pac code add-data-source -a dataverse -t cds_numbering
pac code add-data-source -a dataverse -t cds_settings
pac code add-data-source -a dataverse -t cds_email_template
pac code add-data-source -a dataverse -t cds_email_log
pac code add-data-source -a dataverse -t cds_workflow_rule
pac code add-data-source -a dataverse -t cds_workflow_execution
pac code add-data-source -a dataverse -t cds_goal
pac code add-data-source -a dataverse -t cds_achievement
pac code add-data-source -a dataverse -t cds_audit_entry
```

### Etape 3bis : Remplacer le dataset de test par les vraies bases Dataverse

**Objectif** : une fois la validation localhost terminee (Etape 0) et les tables Dataverse creees et liees (Etapes 1-3), supprimer le dataset de test (MockService) du build production et brancher les ProductionService sur les services generes par `pac code add-data-source`.

**Procedure :**

1. **Verifier que `src/generated/services/` existe** et contient les services generes pour chaque table
2. **Implementer chaque ProductionService** dans `src/lib/services/*/production-service.ts` :
   - Utiliser les services generes dans `src/generated/services/`
   - Mapper les noms Dataverse (`cds_first_name`) vers camelCase TypeScript (`firstName`)
   - Mapper les Choice fields (entiers Dataverse) vers les enums TypeScript (strings)
   - Ne pas oublier les colonnes de denormalisation (`cds_account_name`, etc.)
3. **Modifier le proxy de chaque service** dans `src/lib/services/*/index.ts` :
   - En dev (`import.meta.env.DEV`) : utiliser MockService (pour continuer le dev local)
   - En prod (`!import.meta.env.DEV`) : utiliser ProductionService avec fallback sur MockService en cas d'erreur
4. **Valider le build production** :

```bash
npm run build
```

5. **Verifier qu'aucun import MockService ne fuit dans le bundle prod** (optionnel mais recommande)

**Important** :

- NE JAMAIS supprimer les MockService du code source — ils restent necessaires pour le developpement local
- Le proxy gere automatiquement le basculement dev/prod
- Les ProductionService doivent gerer les erreurs Dataverse (timeout, 401, 404) et retourner des `ServiceResult` coherents

---

### Etape 4 : Build et deploiement

```bash
# Build le projet
npm run build

# Deployer sur Power Apps
pac code push

# L'application apparait dans make.powerapps.com > Mes applications
# Cliquer "Lire" (Play) pour lancer, PAS "Modifier"
```

### Etape 5 : Donnees initiales

Apres deploiement, inserer les parametres par defaut dans la table `cds_settings` :

| Cle                      | Valeur                                                      |
| ------------------------ | ----------------------------------------------------------- |
| company_name             | {{NOM_ENTREPRISE}}                                            |
| company_siren            | {{SIREN}}                                                     |
| company_address          | {{ADRESSE}}                                                   |
| company_email            | {{EMAIL}}                                                     |
| company_phone            | {{TELEPHONE}}                                                 |
| company_logo_url         | {{URL_LOGO}}                                                  |
| company_website          | {{SITE_WEB}}                                                  |
| vat_rate_default         | 20.00                                                       |
| quote_validity_days      | 30                                                          |
| payment_terms_days       | 30                                                          |
| invoice_legal_mentions   | Micro-entreprise - TVA non applicable, art. 293 B du CGI... |
| invoice_bank_details     | {{IBAN}} / {{BIC}}                                              |
| power_automate_email_url | (URL du flow HTTP trigger)                                  |

### Etape 6 : Creer la solution managee pour publication

Une fois l'application fonctionnelle avec les tables Dataverse liees, creer une **solution managee** pour la publication et la distribution.

**Pourquoi une solution managee ?**

- Les composants sont **proteges** : les utilisateurs ne peuvent pas modifier les tables, colonnes ou relations
- Permet un **deploiement propre** sur d'autres environnements (DEV → RECETTE → PROD)
- Facilite la **mise a jour** : importer une nouvelle version remplace l'ancienne
- Garantit la **coherence** : tous les composants sont deployes ensemble

**Procedure :**

1. Aller sur **make.powerapps.com** > **Solutions**
2. Ouvrir la solution "CRMFreelance" (non managee)
3. Verifier que **tous les composants** sont inclus :
   - Les 21 tables Dataverse (cds_account, cds_contact, ... cds_audit_entry)
   - La Code App "CRM"
   - Les flux Power Automate (si configures)
4. Cliquer **Exporter** dans la barre d'actions
5. Selectionner **Managed** (managee)
6. Attendre la generation du fichier `CRMFreelance_managed.zip`
7. Telecharger le ZIP

**Deploiement sur un autre environnement :**

```bash
# Via pac CLI
pac solution import --path CRMFreelance_managed.zip --environment https://{{URL_DATAVERSE}}

# Ou via l'interface make.powerapps.com > Solutions > Importer
```

**Bonnes pratiques solution managee :**

| Regle                                                         | Pourquoi                                |
| ------------------------------------------------------------- | --------------------------------------- |
| Incrementer le numero de version a chaque export              | Permet le suivi des versions deployees  |
| Toujours tester l'import en environnement DEV d'abord         | Detecte les erreurs avant la production |
| Conserver la solution non managee dans l'environnement de dev | Permet les modifications futures        |
| Ne JAMAIS importer une solution non managee en production     | Risque de modifications non controlees  |
| Versionner le ZIP managee dans git ou un storage              | Tracabilite et rollback possible        |

### Notes importantes

- **Ordre de deploiement** : Validation localhost (Etape 0) → Tables Dataverse (Etapes 1-2) → `pac code add-data-source` (Etape 3) → Remplacement MockService par ProductionService (Etape 3bis) → `npm run build` + `pac code push` (Etape 4) → Donnees initiales (Etape 5) → Solution managee (Etape 6). **NE JAMAIS inverser cet ordre.**
- **Validation localhost OBLIGATOIRE** : toujours tester avec `npm run dev` et le MockService (dataset de test) AVANT de deployer. Un deploiement sans validation locale est interdit.
- **Solution non managee** : utilisee uniquement en environnement de developpement pour permettre les modifications
- **Solution managee** : utilisee pour la publication et le deploiement en production
- **Prefixe `cds_`** : toutes les tables et colonnes utilisent le prefixe publisher "cds"
- **Choice fields** : les valeurs commencent a 144950000 (prefixe publisher 14495)
- **pac CLI** : utiliser la version standalone (winget install Microsoft.PowerAppsCLI), PAS la version npm
- **Node.js** : la version npm de pac est incompatible avec Node v24+, utiliser le chemin direct de la version standalone : `%LOCALAPPDATA%\Microsoft\PowerAppsCLI\pac.cmd`

---

## 10. Solution Dataverse - Contrôle de cohérence

### 10.1 Matrice de cohérence Code ↔ Dataverse

Chaque service TypeScript dans `src/lib/services/` référence des noms de tables et colonnes Dataverse. Cette matrice doit être vérifiée à chaque modification du modèle de données.

**Règle** : tout nom de colonne Dataverse dans un `ProductionService` DOIT exister dans la solution XML ET dans la table Dataverse correspondante.

| Service TypeScript  | Table Dataverse                             | Colonnes dénormalisées                                                                | Relations                                |
| ------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------- |
| account-service.ts  | cds_accounts                                | -                                                                                     | -                                        |
| contact-service.ts  | cds_contacts                                | cds_account_name                                                                      | N-1 account                              |
| deal-service.ts     | cds_deals                                   | cds_account_name, cds_contact_name                                                    | N-1 account, contact                     |
| quote-service.ts    | cds_quotes                                  | cds_deal_name, cds_account_name, cds_contact_name                                     | N-1 deal, account, contact               |
| order-service.ts    | cds_orders                                  | cds_deal_name, cds_account_name, cds_contact_name                                     | N-1 quote, deal, account, contact        |
| invoice-service.ts  | cds_invoices                                | cds_deal_name, cds_account_name, cds_contact_name, cds_order_number, cds_quote_number | N-1 order, quote, deal, account, contact |
| activity-service.ts | cds_activities                              | -                                                                                     | N-1 account, contact, deal               |
| email-service.ts    | cds_email_templates, cds_email_logs         | -                                                                                     | N-1 template, account, contact           |
| workflow-service.ts | cds_workflow_rules, cds_workflow_executions | cds_rule_name                                                                         | N-1 rule                                 |
| goals-service.ts    | cds_goals, cds_achievements                 | -                                                                                     | -                                        |
| audit-service.ts    | cds_audit_entries                           | -                                                                                     | -                                        |

### 10.2 Procédure de contrôle avant déploiement

**Checklist obligatoire** avant d'importer la solution ou de déployer la Code App :

0. **Vérifier la langue de l'environnement Dataverse** :
   - L'API Dataverse rejette les labels avec un code langue non installé
   - Environnement FR = LanguageCode **1036** (pas 1033 anglais)
   - Vérifier via `GET /api/data/v9.2/RetrieveInstalledLanguagePacks` ou dans make.powerapps.com > Paramètres > Langues
   - Le script `deploy_dataverse_tables.py` utilise 1036 par défaut

1. **Vérifier que la solution ZIP est à jour** :
   - Ouvrir `CRMFreelance/src/Other/Solution.xml` : vérifier que les 21 RootComponents sont présents
   - Ouvrir `CRMFreelance/src/Other/Customizations.xml` : vérifier les 21 Entity blocks

2. **Vérifier la cohérence colonnes** :
   - Pour chaque `ProductionService`, lister toutes les colonnes Dataverse référencées
   - Vérifier que chaque colonne existe dans `Customizations.xml`
   - Vérifier les types (nvarchar, money, int, datetime, lookup, picklist, bit)

3. **Vérifier les relations** :
   - Chaque lookup dans Customizations.xml doit avoir une EntityRelationship correspondante
   - Les CascadeDelete doivent être cohérents avec le comportement applicatif

4. **Vérifier les Choice fields** :
   - Les valeurs OptionSet dans le XML (144950000, 144950001...) doivent correspondre aux valeurs dans les enums TypeScript
   - Attention : Dataverse stocke des entiers, le code TypeScript utilise des strings

5. **Vérifier les colonnes de dénormalisation** :
   - Les colonnes `cds_account_name`, `cds_contact_name`, etc. doivent être peuplées par l'application lors des create/update
   - Si une colonne dénormalisée est vide, l'affichage sera dégradé mais pas bloquant

### 10.3 Bonnes pratiques solution Dataverse

| Règle                                                                                 | Pourquoi                                                                                       |
| ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Solution **non managée** uniquement                                                   | Permet de modifier les tables après import                                                     |
| Préfixe publisher `cds_` cohérent                                                     | Évite les conflits avec d'autres solutions                                                     |
| OptionValuePrefix `14495` pour tous les Choice                                        | Garantit l'unicité des valeurs                                                                 |
| Ne JAMAIS modifier les fichiers générés par `pac code add-data-source`                | Ils sont régénérés à chaque ajout                                                              |
| Toujours tester l'import dans un environnement DEV d'abord                            | Évite de casser la production                                                                  |
| Versionner la solution XML dans git                                                   | Traçabilité des modifications schema                                                           |
| Après modification du schema : ré-exporter la solution depuis make.powerapps.com      | Garantit la synchronisation                                                                    |
| NE JAMAIS créer de XML Customizations.xml artisanal                                   | Le format n'est pas documenté publiquement, l'import échoue systématiquement                   |
| Utiliser le Web API `POST /EntityDefinitions` pour créer les tables                   | Méthode officielle documentée, fiable et reproductible                                         |
| Vérifier la langue de l'environnement AVANT tout déploiement                          | LanguageCode 1036 (FR) vs 1033 (EN) - les labels sont rejetés si la langue n'est pas installée |
| Format lookups : `@odata.type: OneToManyRelationshipMetadata` + `ReferencedAttribute` | Sans ces champs l'API retourne "Invalid property ReferencingEntity"                            |
| Script de déploiement idempotent                                                      | Doit supporter le re-run : si table/colonne existe déjà, continuer sans erreur                 |
| En cas de doute ou d'échec : consulter la doc officielle Microsoft                    | Ne JAMAIS improviser un format XML ou JSON pour Dataverse                                      |
| `pac solution init` crée la structure de solution valide                              | Évite les erreurs de structure ZIP (Solution.xml, [Content_Types].xml)                         |
| NE JAMAIS utiliser PowerShell `Compress-Archive` pour zipper une solution             | `Compress-Archive` ignore les fichiers avec crochets (`[Content_Types].xml`) = ZIP invalide    |
| Utiliser Python `zipfile` ou 7-Zip pour créer le ZIP de solution                      | Ces outils gèrent correctement les noms de fichiers avec crochets                              |
| `power.config.json` est la source de vérité pour les noms de tables                   | Contient `databaseReferences` avec les entitySetNames exacts après `pac code add-data-source`  |

### 10.4 Colonnes de dénormalisation : pourquoi et comment

Les tables `cds_deal`, `cds_quote`, `cds_order`, `cds_invoice` contiennent des colonnes dénormalisées (`cds_account_name`, `cds_contact_name`, `cds_deal_name`) en plus des lookups.

**Pourquoi** : le SDK Power Apps Code Apps ne supporte pas facilement le `$expand` OData pour récupérer les noms des entités liées. Stocker le nom directement dans la table permet un affichage instantané sans requête supplémentaire.

**Comment** : lors de chaque `create` ou `update`, le service TypeScript doit peupler ces colonnes avec le nom actuel de l'entité liée. Si le nom de l'entité source change (ex: renommage d'un compte), les colonnes dénormalisées ne sont PAS mises à jour automatiquement - c'est un compromis acceptable pour un CRM mono-utilisateur.

### 10.5 Script de déploiement Web API (méthode recommandée)

Le fichier `deploy_dataverse_tables.py` à la racine du projet crée les 21 tables via le Web API Dataverse. C'est la **seule méthode fiable** pour créer des tables programmatiquement.

**Prérequis :**

- Python 3 + packages `msal` et `requests` (`pip install msal requests`)
- pac CLI authentifié (`pac auth create --environment {id}`)

**Utilisation :**

```bash
# 1. Authentification (device code flow)
python -c "
import msal
app = msal.PublicClientApplication('{{MSAL_CLIENT_ID}}', authority='https://login.microsoftonline.com/organizations')
flow = app.initiate_device_flow(scopes=['https://{{URL_DATAVERSE}}/.default'])
print(flow['user_code'])  # Entrer ce code sur https://microsoft.com/devicelogin
result = app.acquire_token_by_device_flow(flow)
open('.dataverse_token', 'w').write(result['access_token'])
"

# 2. Déploiement des tables
python deploy_dataverse_tables.py
```

**Ce que fait le script :**

1. Teste la connexion via `GET /WhoAmI`
2. Crée chaque table via `POST /api/data/v9.2/EntityDefinitions` avec header `MSCRM.SolutionUniqueName`
3. Ajoute les colonnes via `POST /EntityDefinitions(LogicalName='table')/Attributes`
4. Crée les relations via `POST /api/data/v9.2/RelationshipDefinitions` avec `@odata.type: OneToManyRelationshipMetadata`

**Erreurs apprises et corrigées :**

| Erreur                                           | Cause                                    | Solution                                                                     |
| ------------------------------------------------ | ---------------------------------------- | ---------------------------------------------------------------------------- |
| `The language code 1033 is not a valid language` | Environnement FR, pas EN                 | Utiliser LanguageCode 1036                                                   |
| `PrimaryName attribute not found`                | XML Customizations.xml artisanal         | Abandonner l'approche XML, utiliser le Web API                               |
| `Invalid property 'ReferencingEntity'`           | Format JSON lookup incomplet             | Ajouter `@odata.type: OneToManyRelationshipMetadata` + `ReferencedAttribute` |
| `schema name already exists`                     | Table déjà créée lors d'un run précédent | Script idempotent : ignorer et continuer avec les colonnes                   |

### 10.6 Méthodes de création de tables Dataverse (par ordre de fiabilité)

| Méthode                                 | Fiabilité  | Quand l'utiliser                                                 |
| --------------------------------------- | ---------- | ---------------------------------------------------------------- |
| **Web API** (`POST /EntityDefinitions`) | Haute      | Déploiement automatisé, CI/CD, scripts reproductibles            |
| **make.powerapps.com** (UI)             | Haute      | Prototypage rapide, ajustements manuels                          |
| **pac solution init + export**          | Moyenne    | Gestion ALM avec SolutionPackager                                |
| **XML Customizations.xml artisanal**    | Très basse | NE PAS UTILISER - format non documenté, échec quasi-systématique |

_Document genere le 20 mars 2026, mis a jour le 21 mars 2026 - {{NOM_ENTREPRISE}}_
_Mise a jour deploiement : prerequis tables Dataverse + solution managee ajoutee_
_Ce cahier des charges sert de brief de developpement pour la Code App CRM._
