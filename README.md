# ⚡ ZeroSync-DB

> **Universal Local-First, Zero-Knowledge SQLite CRDT Sync Engine in Rust & Dart.**

`ZeroSync-DB` allows developers to build local-first applications where user data stays 100% encrypted on-device, while syncing seamlessly across multiple devices (mobile, desktop, web) via WebSockets, WebRTC, or Cloudflare R2 / S3 storage using **Client-Side AES-256-GCM E2EE** and **Hybrid Logical Clock (HLC) CRDTs**.

---

## 🏗️ Architecture Overview

```
                      ┌──────────────────────────────────────┐
                      │   Your App (Flutter, React, Python) │
                      └──────────────────┬───────────────────┘
                                         │
                      ┌──────────────────▼───────────────────┐
                      │    ZeroSync Client-Side E2EE Engine  │
                      │   (AES-256-GCM + HLC CRDT Tracking)  │
                      └──────────────────┬───────────────────┘
                                         │ (Only Encrypted Ciphertext)
                      ┌──────────────────▼───────────────────┐
                      │ Serverless Sync / Edge Storage (R2)  │
                      └──────────────────────────────────────┘
```

The repository includes both a **Universal Rust Core Engine (`zerosync_core`)** with C-FFI exports and a **Dart/Flutter SDK (`zerosync_db`)**:

- 🦀 **`zerosync_core/`**: High-performance Rust engine exposing C-FFI bindings (`zerosync_encrypt`, `zerosync_decrypt`, `zerosync_hlc_now`) for Flutter, Python, Node.js, Swift, and C++.
- 🎯 **`zerosync_db/`**: Clean Dart/Flutter SDK wrapper for instant integration into Flutter apps.

---

## ✨ Features

- 🏠 **100% Local-First Speed**: Instant 0ms reads and writes via local SQLite. Works completely offline.
- 🔐 **Zero-Knowledge E2EE**: All payloads encrypted on-device with AES-256-GCM before transmission. Cloud servers see only opaque ciphertext.
- ⏱️ **CRDT Conflict Resolution**: Uses Hybrid Logical Clocks (HLC) for deterministic multi-device data convergence without central server locks.
- 🦀 **Universal Engine**: Core logic written in Rust with C-FFI bindings for maximum portability.
- 🚀 **Zero Server Lock-In**: Works without hosting expensive database servers or PostgreSQL extensions.

---

## 🚀 Quick Start (Flutter / Dart)

Add `zerosync_db` to your `pubspec.yaml`:

```dart
import 'package:zerosync_db/zerosync_db.dart';

void main() async {
  // 1. Open local SQLite database with secret passphrase
  final db = await ZeroSyncDatabase.open(
    path: 'app_data.db',
    secretKey: 'user-secret-encryption-passphrase',
  );

  // 2. Instant offline write & CRDT audit log
  db.execute("INSERT INTO notes VALUES ('101', 'Private Note');");
  db.logChange(
    tableName: 'notes',
    rowId: '101',
    jsonPayload: '{"id":"101","title":"Private Note"}',
  );

  // 3. Connect real-time Zero-Knowledge background sync
  final client = ZeroSyncClient(
    db: db,
    syncUrl: 'wss://sync.example.com/stream',
  );
  await client.connect();
}
```

---

## 🦀 Building Rust Core (`zerosync_core`)

```bash
cd zerosync_core
cargo test
cargo build --release
```

Produces native static/dynamic C-FFI libraries (`libzerosync_core.so`, `.dylib`, `.dll`, `.a`) for cross-platform binding.

---

## 🧪 Running Tests

```bash
# Test Dart SDK
dart test

# Test Rust Core Engine
cd zerosync_core && cargo test
```

---

## 📜 License

MIT License. Developed for the open-source community by Cancellls.
