# Apna — Personal & Shared Family Workspace

> **"One Account • All Devices • Always in Sync"**  
> An enterprise-grade, offline-first personal & family workspace application built with Flutter, Riverpod, SQLite, and Supabase.

---

## 🌟 Overview

**Apna** helps individuals and families organize, secure, and access their life essentials across all devices (Android, macOS, Web, iOS):
- **Identity & KYC Vault:** Encrypted storage for Aadhaar, Passports, PAN cards, Driving Licenses, Voter IDs.
- **Utility Bills & Reminders:** Recurring electricity, water, internet, and mobile bill tracking with manual PDF/image upload and zero-fee **UPI Intent** payment launcher (Google Pay, PhonePe, Paytm, BHIM).
- **Warranty Tracker:** Product invoices, serial numbers, customer support contacts, and automated expiry countdowns.
- **Tasks & Checklist:** Family task assignments, recurring chores, and completion tracking.
- **Expenses & Split:** Shared household expense logs and settlement records.
- **Indian Legal Compliance:** Built-in compliance with India's **Digital Personal Data Protection Act, 2023 (DPDP Act)** and **IT Rules, 2011**, featuring explicit purpose notices, consent tracking ledgers, and data principal rights.

---

## 🏗 Architecture Highlights

- **Modular Monolith:** Feature-first modular architecture where each domain feature (`documents`, `bills`, `tasks`, `warranties`) is completely self-contained.
- **Offline-First Resilience:** Transactional Local Outbox pattern backed by SQLite ensures instant writes and reliable sync when connectivity resumes.
- **Multi-Tenant Workspaces:** Seamless switching between private **Personal** workspace and shared **Family** workspaces.
- **Zero-Cost First:** 100% free infrastructure leveraging Supabase Free Tier (PostgreSQL, Auth, Storage, Realtime) and device-native capabilities.

---

## 📱 Multi-Platform Exports

| Target Platform | Export Artifact | Deployment Target |
| :--- | :--- | :--- |
| **Android** | `.apk` (Release) / `.aab` | Direct sideload / Google Play Store |
| **macOS** | `.dmg` / `.app` | macOS Universal Binary |
| **Web / Extension** | Standalone SPA / Chrome Extension | Web browsers, Chrome extension side-panel |
| **iOS** | `.ipa` / Runner archive | TestFlight & App Store |

---

## 📜 Documentation

Detailed architectural and compliance documentation can be found in the `docs/` folder:
- [Architecture Blueprint](file:///Users/shubham.sharma/personal-usage/apna/docs/ARCHITECTURE.md)
- [Database Schema & Migrations](file:///Users/shubham.sharma/personal-usage/apna/docs/DATABASE_SCHEMA.md)
- [DPDP Act 2023 & India Legal Compliance](file:///Users/shubham.sharma/personal-usage/apna/docs/LEGAL_COMPLIANCE_INDIA.md)
- [Terms of Service](file:///Users/shubham.sharma/personal-usage/apna/docs/TERMS_OF_SERVICE.md)
- [Privacy Policy](file:///Users/shubham.sharma/personal-usage/apna/docs/PRIVACY_POLICY.md)
- [Security & Encryption](file:///Users/shubham.sharma/personal-usage/apna/docs/SECURITY.md)
- [Offline Sync Strategy](file:///Users/shubham.sharma/personal-usage/apna/docs/SYNC_STRATEGY.md)
- [Integrations & Cost Analysis](file:///Users/shubham.sharma/personal-usage/apna/docs/INTEGRATIONS.md)
- [Feature Guidelines](file:///Users/shubham.sharma/personal-usage/apna/docs/FEATURE_GUIDELINES.md)
- [Coding Standards](file:///Users/shubham.sharma/personal-usage/apna/docs/CODING_STANDARDS.md)
- [Architecture Decision Records (ADRs)](file:///Users/shubham.sharma/personal-usage/apna/docs/decisions/)
