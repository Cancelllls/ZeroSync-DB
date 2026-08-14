# ⚡ ZeroSync-DB

> **Local-First, Zero-Knowledge SQLite CRDT Sync Engine for Flutter, Dart, and Cross-Platform Apps.**

`zerosync_db` allows developers to build local-first apps where user data stays 100% encrypted on the device, while syncing seamlessly across devices via WebSockets, WebRTC, or Cloudflare R2 / S3 storage using **Client-Side AES-256-GCM E2EE** and **Hybrid Logical Clock (HLC) CRDTs**.

---

## ✨ Features

- 🏠 **Local-First**: Instant offline reads & writes via local SQLite.
- 🔐 **Zero-Knowledge E2EE**: All payloads encrypted on-device with AES-256-GCM before leaving the client. Cloud servers see only opaque ciphertext.
- 🔄 **CRDT Conflict Resolution**: Uses Hybrid Logical Clocks (HLC) for deterministic multi-device data convergence without central server locks.
- ⚡ **Transport Agnostic**: Sync over WebSockets, WebRTC, or serverless Cloudflare R2 / AWS S3 buckets.
- 🚀 **Zero Dependency Lock-In**: Works without hosting expensive database servers or PostgreSQL extensions.

---

## 🚀 Quick Start

```dart
import 'package:zerosync_db/zerosync_db.dart';

void main() async {
  // 1. Initialize ZeroSync DB with your local secret key
  final db = await ZeroSyncDatabase.open(
    path: 'app_data.db',
    secretKey: 'user-secret-encryption-passphrase',
  );

  // 2. Insert data locally (instant offline write)
  await db.execute(
    'INSERT INTO notes (id, title, body) VALUES (?, ?, ?)',
    ['note_101', 'My Private Note', 'Zero-Knowledge content'],
  );

  // 3. Connect ZeroSync Engine for real-time E2EE background sync
  final client = ZeroSyncClient(
    db: db,
    syncUrl: 'wss://sync.example.com/stream',
  );
  await client.connect();
}
```

---

## 📜 License

MIT License. Developed for the open-source community by Cancellls.
