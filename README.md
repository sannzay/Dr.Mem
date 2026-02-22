# Dr. Mem — AI-Powered Clinical Companion

<p align="center">
<img src="DrMemCompanionApp/Assets.xcassets/AppIcon.appiconset/icon.png" width="120" alt="Dr. Mem App Icon" />
</p>

<p align="center">
<strong>Capture. Organize. Remember. Everything that matters in clinical practice.</strong>
</p>

<p align="center">
<img src="https://img.shields.io/badge/iOS-18.0+-black?style=flat-square&logo=apple" />
<img src="https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift" />
<img src="https://img.shields.io/badge/SwiftUI-5-blue?style=flat-square" />
<img src="https://img.shields.io/badge/SwiftData-Enabled-green?style=flat-square" />
<img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" />
</p>

---

## Overview

**Dr. Mem** is a native iOS companion app built for clinicians and medical students. It captures conversations, lectures, and patient visits — then uses AI to extract structured notes, clinical memories, and action items automatically.

Think of it as a second brain that lives in your pocket: always listening (when you want it to), always organizing, always ready to answer questions grounded in what you've actually seen and heard.

> Built with SwiftUI, SwiftData, OpenRouter LLM integration, Omi BLE wearable support, and Apple on-device Speech Recognition.

---

## Features

### 🎙️ Capture Modes

| Mode | Description |
|------|-------------|
| **Education** | Teaching rounds, supervisor feedback, clinical pearls |
| **Brain Dump** | Personal productivity, quick notes → tasks |
| **Patient Encounter** | Structured clinical documentation with patient safety guardrails |

### 🤖 AI Pipeline

- **Session Summarization** — Auto-summarize any recording
- **Memory Extraction** — Pull clinical pearls, decisions, and plans into a searchable memory bank
- **Task Extraction** — Detect action items from conversation and auto-create tasks
- **Clinician Draft Generation** — SOAP / H&P structured note drafts
- **Patient AVS Generation** — Plain-language After Visit Summaries for patients
- **RAG-Grounded Chat** — Ask questions; get answers grounded in your own memories with citations

### 📋 Encounters

A first-class module for patient visits:
- Consent gate with audit trail before any recording starts
- Clinician-facing structured note (SOAP/H&P)
- Patient-facing After Visit Summary (AVS)
- Exportable as plain text or PDF
- Default `noteOnly` retention — audio deleted after transcription

### 🧠 Memories

- Searchable, filterable memory bank sourced from all sessions and journal entries
- Types: Learning Pearl, Feedback, Decision, Plan, Task Candidate, Reference
- Pin important memories; link directly to Encounters
- Deep-link back to source session or journal entry

### ✅ Tasks

- Auto-extracted from recordings and journal entries
- Sections: Today / Upcoming / Done
- Local notifications for due dates
- Filter by encounter, priority, or status

### 📓 Journal

- Text, voice, and image entries
- Auto memory + task extraction on save
- Clean, Notes-like minimal UI

### 💬 AI Chat (Dr. Mem identity)

- Claude-like minimal chat interface powered by your chosen model
- Retrieval-Augmented Generation (RAG) over your own memories
- Citation chips showing which memories grounded each answer
- Quick actions: Save as Memory, Make Task, Add to Journal

### 📡 Omi Wearable Integration

- Connects to [Omi](https://www.omi.me) BLE wearable via CoreBluetooth
- Live transcription streamed directly from device audio
- Automatic reconnect on disconnect
- Supports Omi, Friend, and Based hardware namespaces

---

## Architecture

```
DrMemCompanionApp/
├── Models/
│   ├── Session.swift              # Recording sessions + encounter metadata
│   ├── Memory.swift               # Extracted memories / clinical pearls
│   ├── TaskItem.swift             # Action items
│   ├── JournalEntry.swift         # Journal entries (text / voice / image)
│   ├── ChatThread.swift           # Chat conversation threads
│   ├── TranscriptSegment.swift    # Per-segment transcript data
│   └── AppEnums.swift             # All app-wide enumerations
│
├── Services/
│   ├── OpenRouterService.swift    # LLM calls + SSE streaming
│   ├── AIPipelineService.swift    # Summarization, extraction, generation
│   ├── SpeechRecognitionService.swift  # Apple on-device STT
│   ├── OmiBLEService.swift        # Omi wearable CoreBluetooth integration
│   ├── RAGService.swift           # Local keyword + recency retrieval
│   ├── BiometricService.swift     # Face ID / Touch ID app lock
│   └── KeychainService.swift      # Secure API key storage
│
├── ViewModels/
│   ├── SessionViewModel.swift
│   └── ChatViewModel.swift
│
├── Views/
│   ├── ContentView.swift          # Root navigation + drawer
│   ├── DrawerView.swift           # Slide-out navigation drawer
│   ├── ListeningView.swift        # Omi + mic recording UI
│   ├── EncountersView.swift       # Encounter timeline
│   ├── EncounterDetailView.swift  # Tabbed encounter detail
│   ├── MemoriesView.swift
│   ├── TasksView.swift
│   ├── JournalView.swift
│   ├── ChatView.swift
│   ├── ChatsListView.swift
│   ├── ConsentGateView.swift      # Patient consent workflow
│   ├── ModePickerSheet.swift
│   ├── LockScreenView.swift
│   └── SettingsView.swift
│
└── Utilities/
  ├── GlassComponents.swift      # Reusable liquid glass UI components
  └── Theme.swift                # Colors, typography, spacing tokens
```

**Pattern:** MVVM with `@Observable` view models, SwiftData for on-device persistence, and a service layer for all external integrations.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI 5 |
| Minimum Target | iOS 18.0 |
| Language | Swift 6 (strict concurrency) |
| State Management | `@Observable`, `@State`, `@Binding` |
| Persistence | SwiftData (`@Model`, `@Query`) |
| LLM Gateway | [OpenRouter](https://openrouter.ai) (streaming SSE) |
| Speech-to-Text | Apple `SFSpeechRecognizer` (on-device) |
| BLE Wearable | CoreBluetooth — Omi device protocol |
| Security | Keychain (API keys), LocalAuthentication (biometrics) |
| Notifications | `UserNotifications` framework |

---

## Getting Started

### Prerequisites

- Xcode 16 or later
- iOS 18.0+ device *(recommended)* or simulator
- [OpenRouter](https://openrouter.ai) API key — free tier available
- *(Optional)* Omi wearable device for BLE audio capture

### Installation

```bash
git clone https://github.com/your-username/dr-mem.git
cd dr-mem
open DrMemCompanionApp.xcodeproj
```

Build and run on your device or simulator. All Swift Package Manager dependencies resolve automatically on first build.

### Configuration

1. Launch the app and open the **drawer** (hamburger icon, top-left)
2. Go to **Settings**
3. Enter your **OpenRouter API Key** and tap **Save Key**
4. Select your preferred **LLM model** (default: `anthropic/claude-sonnet-4`)
5. *(Optional)* Enable **App Lock** for Face ID / Touch ID protection

> API keys are stored exclusively in the iOS Keychain and never written to disk.

---

## Omi Wearable Setup

1. Power on your Omi device (red light = awaiting connection)
2. Navigate to **Listening** from the drawer
3. Tap **Scan for Device** — the app discovers and connects automatically
4. Once connected, tap **Start Session** and choose a capture mode
5. Live transcription appears in real time via Apple on-device speech recognition

> Bluetooth Low Energy requires a **physical iPhone**. BLE is not available on the iOS Simulator.

---

## Patient Encounter Workflow

Dr. Mem enforces a structured, privacy-first workflow for patient visits:

```
1. Select "Patient Encounter" mode
       ↓
2. Consent Gate
 • Script for clinician to read to patient
 • Clinician checkbox attestation (required)
 • Optional: patient alias + visit type
 • Timestamp recorded automatically (audit trail)
       ↓
3. Recording
 • Prominent "Recording ON" banner
 • Live rolling transcript
       ↓
4. Review & Approve  ← required before any export
 • Editable Clinician Draft (SOAP/H&P)
 • Editable Patient AVS (plain language)
 • Redaction suggestion tools
 • "Reviewed for accuracy" checkbox
       ↓
5. Store + Export
 • Clinician Draft → Copy to clipboard / Share sheet (EHR paste)
 • Patient AVS → PDF generation + Share sheet
 • Audio deleted by default (noteOnly retention policy)
```

---

## Privacy & Security

| Feature | Default |
|---------|---------|
| Audio retention after transcription | **Deleted (OFF)** |
| Patient encounter transcript storage | **Note Only** |
| Clinician review required before export | **ON** |
| API key storage | **Keychain only** |
| App Lock (Face ID / Touch ID) | Configurable in Settings |
| Speech recognition | **On-device (Apple STT)** |

All patient data stays **on-device**. The only external network call is the LLM prompt sent to OpenRouter for AI features — which you configure and control.

---

## Supported AI Models

Dr. Mem uses [OpenRouter](https://openrouter.ai) as a unified LLM gateway:

| Model | ID |
|-------|----|
| Claude Sonnet 4 *(default)* | `anthropic/claude-sonnet-4` |
| Claude 3 Haiku | `anthropic/claude-3-haiku` |
| GPT-4o | `openai/gpt-4o` |
| GPT-4o Mini | `openai/gpt-4o-mini` |
| Gemini Pro | `google/gemini-pro` |

Switch models anytime in **Settings → Model**. Any model available on OpenRouter can be used.

---

## Design System

The UI is built on a **Liquid Glass** design language — blurred translucent surfaces, warm gradients, and subtle specular highlights — following Apple Human Interface Guidelines.

### Core Components

| Component | Description |
|-----------|-------------|
| `GlassCard` | `.ultraThinMaterial` blur + thin border + gradient highlight |
| `GlassButton` | Pill-shaped frosted action buttons with haptic feedback |
| `GlassInputBar` | Frosted glass input bar for chat and search |
| `GlassSheet` | Modal bottom sheet with glass background |

### Visual Language

- **Background:** Warm ivory / off-white
- **Accent:** Warm terracotta / brown
- **Surfaces:** `.ultraThinMaterial` + soft inner glow
- **Typography:** SF Pro with editorial weight hierarchy
- **Motion:** Spring animations, sensory haptic feedback on key actions

---

## Roadmap

- [ ] iCloud sync across devices
- [ ] HealthKit integration (vitals tagging in encounters)
- [ ] PDF branding for Patient AVS export
- [ ] Home screen widget — Today's tasks + recent memory
- [ ] Siri Shortcuts for quick voice capture
- [ ] FHIR export for EHR integration
- [ ] Semantic search with local embeddings (RAG v2)
- [ ] watchOS companion for quick memory review

---

## Contributing

Contributions are welcome. Please open an issue first to discuss your idea.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## License

This project is licensed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

---

## Acknowledgements

- [Omi / Based Hardware](https://www.omi.me) — open wearable BLE protocol
- [OpenRouter](https://openrouter.ai) — unified LLM API gateway
- Apple — SwiftUI, SwiftData, SFSpeechRecognizer, LocalAuthentication

---

<p align="center">
Built with ❤️ for clinicians who deserve better tools.
</p>
