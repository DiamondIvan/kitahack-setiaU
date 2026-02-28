# 🤖 SetiaU: The Agentic Secretary
**KitaHack 2026 Submission | Theme: The Agentic Secretary**

> Bridging the gap between conversation and action. SetiaU listens to meetings, reasons through constraints, and executes administrative tasks in Google Workspace.

---

## 1. Repository & Team Introduction

| Info | Details |
| :--- | :--- |
| **Team Name** | Hokkien Mee no have color |
| **Member** | Ivan Fong |
| **Member** | Ivan Mak |
| **Member** | Xian Jie |
| **Member** | Yi Yu |

---

## 2. Project Overview

**The Problem:** Student leaders waste 70% of their time on admin work (minutes, scheduling, follow-ups) and only 30% on strategic impact. This causes administrative paralysis and burnout.<br>
**The Solution:** SetiaU acts as an active agent during meetings. It interprets goals, validates constraints, and executes multi-step workflows directly into Google Workspace.<br>
**SDG Alignment:** Goal 16 (Peace, Justice, and Strong Institutions) by increasing accountability, transparency, and preserving decision history.

---

## 3. Key Features

* **🎙️ Live Meeting Intelligence:** Extracts tasks, attributes speakers, and detects deadlines from real-time audio.
* **🧠 Constraint Detection:** Automatically checks public holidays, budgets, and member availability before creating tasks.
* **🏛️ Institutional Memory:** Stores past decisions and meeting contexts securely in Firebase.
* **⚙️ 1-Click Execution:** Drafts Google Workspace actions (Calendar, Docs, Sheets) and waits for human approval to execute.

---

## 4. Technologies Used

**Google Technologies:**
* **Gemini 3.0 Pro:** Core reasoning engine for transcript processing and tool-calling.
* **Google Workspace APIs:** For executing Calendar, Docs, Sheets, and Gmail actions.
* **Firebase:** Auth, Firestore (database), and Cloud Functions (secure middleware).

**Other Tools:**
* **Flutter:** Cross-platform frontend app.
* **Node.js:** Backend environment for Cloud Functions.

---

## 5. Implementation Details & Workflow

1. **Discussion:** The meeting happens live on the Flutter app.
2. **Extraction:** Gemini 3.0 Pro converts speech into structured tasks and checks for conflicts.
3. **Approval:** The AI proposes an action; the human user clicks "Approve".
4. **Execution:** Firebase Cloud Functions securely trigger Google Workspace APIs to create events, update budgets, and send emails.
5. **Memory Log:** The action is permanently saved in Firestore.

---

## 6. Challenges Faced

* **AI Hallucinations:** Required heavy prompt engineering to make Gemini 3.0 Pro output strictly formatted JSON for tool calls.
* **Real-Time Audio:** Keeping the Flutter app smooth while streaming live audio to the transcript engine.
* **OAuth Security:** Securely passing Google Workspace permissions from the frontend to the backend middleware.

---

## 7. Installation & Setup

**Prerequisites:** Flutter SDK, Node.js, Firebase CLI, and a Google Cloud/Firebase project.

**1. Clone the repository**
```bash
git clone <repo-url>
cd kitahack_setiau
```

**2. Configure local Gemini key (required for the app UI)**

This app loads `GEMINI_API_KEY` from a local `.env` file (see `lib/main.dart`).

- Create `.env` at the project root (it is already git-ignored)
- Add:
	- `GEMINI_API_KEY=YOUR_GEMINI_API_KEY`

Tip: there is an `.env.example` you can copy from.

**3. Setup Firebase Cloud Functions (optional; for Calendar/Email/Docs/Sheets execution)**

Cloud Functions in this repo use a Firebase Secret named `GOOGLE_SERVICE_ACCOUNT_KEY` (the *entire service account JSON* as a string).

```bash
cd functions
npm install
cd ..

# set the Firebase project (this repo does not commit .firebaserc)
firebase use --add

# set secret (paste the full service account JSON when prompted)
firebase functions:secrets:set GOOGLE_SERVICE_ACCOUNT_KEY

# deploy
firebase deploy --only functions
```

**4. Run the App**
After creating `.env`, run:
```bash
flutter pub get
flutter run
```

---

## 8. Future Roadmap

* **Full Auto-Generation:** Instantly generating comprehensive PDF minutes and AGM proposals.
* **Complex Budget Sync:** Two-way sync with advanced Google Sheets accounting templates.
* **AI Role Recommendations:** Suggesting the best team member for a task based on past success rates.



