# ClientFlow CRM

**ClientFlow CRM** is a modern, desktop-oriented business management application built with **Flutter** and **Firebase**, designed specifically for small software development agencies that build websites, mobile apps, and custom digital products.

---

## 🚀 Overview

Small software development agencies often struggle with scattered spreadsheets, WhatsApp messages, and forgotten client follow-ups. ClientFlow CRM provides a centralized, multi-tenant workspace to organize sales opportunities, track leads, schedule follow-ups, and generate branded quotations.

---

## ✨ Key Features

- **Google Authentication Only**: Secure login using Google accounts with session persistence and role validation.
- **Multi-Tenant Agency Workspaces**:
  - Create a private agency workspace or join with a 6-character Invite Code.
  - Complete data isolation between agencies in Firestore.
  - Role-based permissions (`Owner`, `Admin`, `Employee`) with access deactivation support.
- **Real-Time Sales Dashboard**:
  - Live metric cards: Total leads, active deals, won deals, open pipeline value, won revenue, and due/overdue follow-ups.
  - Visual **Sales Pipeline Distribution** bar chart and **Lead Sources** pie chart.
  - Instant overdue task warning banner.
- **Lead Management**:
  - Filter by status (`New`, `Contacted`, `Qualified`, `Unqualified`), source, and service.
  - **Duplicate Detection**: Real-time warnings if a lead with matching email or phone already exists.
  - Quick **Convert to Deal** workflow.
- **Visual Sales Pipeline & Kanban Board**:
  - 7 customizable stages: `New Lead`, `Contacted`, `Qualified`, `Proposal Sent`, `Negotiation`, `Won`, `Lost`.
  - Drag-and-drop deals across stages.
  - Quick **Mark as Won 🎉** and **Mark as Lost** (with lost reason prompt) actions.
  - Full stage transition history and audit logs.
- **Contacts & Companies Directory**:
  - Maintain client accounts, technical decision makers, and linked project opportunities.
- **Tasks & Follow-ups**:
  - Categorized tabs: All, Today, Overdue, Upcoming, Completed.
  - Priority badges and prominent overdue indicators.
  - Direct links to associated leads, contacts, or deals.
- **Activity History & Timeline**:
  - Chronological audit log of calls, meetings, emails, notes, and stage transitions.
- **Quotations & Branded PDF Generation**:
  - Dynamic line items (service deliverable, quantity, unit price, total).
  - Configurable tax % and discounts.
  - One-click **Download & Print PDF** quotation.
- **Reports & Analytics**:
  - Sales conversion rates, pipeline volume by stage, and employee performance table.
  - **Export Leads to CSV** & **Export Deals to CSV**.

---

## 🛠 Tech Stack

- **Frontend**: Flutter (Web, Android, Desktop)
- **Backend**: Firebase Authentication (Google Sign-In), Cloud Firestore
- **State Management**: Provider
- **Charts**: `fl_chart`
- **PDF Generation**: `pdf`, `printing`
- **Data Export**: `csv`

---

## ⚙️ Firebase Setup

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/) and create a project.
   - Enable **Google Sign-In** under **Build > Authentication > Sign-in method**.
   - Enable **Cloud Firestore** under **Build > Firestore Database** (start in production mode).

2. **Add Android Configuration**:
   - Register Android app with package name: `com.example.fluttercrm`.
   - Add your debug SHA-1 / SHA-256 fingerprint.
   - Download `google-services.json` and place it in:
     ```text
     android/app/google-services.json
     ```
   *(Note: `google-services.json` is ignored by git to protect private keys).*

---

## 🛡️ Cloud Firestore Security Rules

*(Copy and paste these rules into **Firebase Console > Firestore Database > Rules** tab, then click **Publish**)*:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isUser(uid) {
      return isAuthenticated() && request.auth.uid == uid;
    }

    function isAgencyMember(agencyId) {
      return isAuthenticated() && 
        exists(/databases/$(database)/documents/agencies/$(agencyId)/members/$(request.auth.uid));
    }

    function getAgencyMemberData(agencyId) {
      return get(/databases/$(database)/documents/agencies/$(agencyId)/members/$(request.auth.uid)).data;
    }

    function isAgencyActive(agencyId) {
      return isAgencyMember(agencyId) && getAgencyMemberData(agencyId).isActive == true;
    }

    function isAgencyAdmin(agencyId) {
      return isAgencyMember(agencyId) && 
        (getAgencyMemberData(agencyId).role == 'admin' || getAgencyMemberData(agencyId).role == 'owner');
    }

    function isAgencyOwner(agencyId) {
      return isAgencyMember(agencyId) && getAgencyMemberData(agencyId).role == 'owner';
    }

    // User profiles
    match /users/{uid} {
      allow read, write: if isUser(uid);
    }

    // Agencies collection
    match /agencies/{agencyId} {
      // Query by invite code for joining or reading if authenticated
      allow read: if isAuthenticated();
      // Allow authenticated user to create a new agency
      allow create: if isAuthenticated() && request.resource.data.ownerId == request.auth.uid;
      // Allow only owner/admin to update agency profile
      allow update: if isAgencyAdmin(agencyId);
      // Allow only owner to delete the agency
      allow delete: if isAgencyOwner(agencyId);

      // Members subcollection
      match /members/{memberUid} {
        allow read: if isAgencyMember(agencyId);
        
        // Creating member: either creator is owner, or joining user creates their own employee record
        allow create: if isAuthenticated() && (
          isUser(memberUid) || isAgencyAdmin(agencyId)
        );

        // Updating member: only admin/owner can change roles or active state
        allow update: if isAgencyAdmin(agencyId) && (
          resource.data.role != 'owner' || isAgencyOwner(agencyId)
        );

        allow delete: if isAgencyOwner(agencyId) && request.auth.uid != memberUid;
      }

      // Leads subcollection
      match /leads/{leadId} {
        allow read, create, update: if isAgencyActive(agencyId);
        allow delete: if isAgencyAdmin(agencyId);
      }

      // Deals subcollection
      match /deals/{dealId} {
        allow read, create, update: if isAgencyActive(agencyId);
        allow delete: if isAgencyAdmin(agencyId);
      }

      // Contacts subcollection
      match /contacts/{contactId} {
        allow read, create, update: if isAgencyActive(agencyId);
        allow delete: if isAgencyAdmin(agencyId);
      }

      // Companies subcollection
      match /companies/{companyId} {
        allow read, create, update: if isAgencyActive(agencyId);
        allow delete: if isAgencyAdmin(agencyId);
      }

      // Tasks subcollection
      match /tasks/{taskId} {
        allow read, create, update: if isAgencyActive(agencyId);
        allow delete: if isAgencyAdmin(agencyId);
      }

      // Activities subcollection
      match /activities/{activityId} {
        allow read, create: if isAgencyActive(agencyId);
        allow update, delete: if isAgencyAdmin(agencyId);
      }

      // Quotations subcollection
      match /quotations/{quotationId} {
        allow read, create, update: if isAgencyActive(agencyId);
        allow delete: if isAgencyAdmin(agencyId);
      }
    }
  }
}
```

---

## 📦 Running the Project

```bash
# 1. Fetch packages
flutter pub get

# 2. Run on Chrome (Web)
flutter run -d chrome

# 3. Or run on an Android Device / Emulator
flutter run
```
