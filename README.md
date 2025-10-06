# LeafLens

> **AI plant health companion** — diagnose diseases, nutrient deficiencies, and pests from a single leaf photo, on-device and privacy-first.

[![CI](https://img.shields.io/github/actions/workflow/status/makalin/leaflens/ci.yml)](#) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](#) [![Made with Rust](https://img.shields.io/badge/backend-Rust-informational)](#) [![Mobile](https://img.shields.io/badge/mobile-Flutter-blue)](#) [![Models](https://img.shields.io/badge/models-TFLite%20%2F%20ONNX-orange)](#)

---

## Why LeafLens?

* **Fast & private**: On-device inference (no photo leaves your phone by default).
* **Practical**: Clear diagnosis + confidence + action steps.
* **Context-aware**: Considers crop type, local climate, and recent outbreaks.
* **Extensible**: Plugin system for new crops, regions, or expert rules.

---

## Features

* 📸 **One-tap Diagnose**: Photo → multi-label predictions (disease, deficiency, pest).
* 🧩 **Symptom Assistant**: Textual Q&A when a photo isn’t possible.
* 🗺️ **Outbreak Map** (opt-in): Anonymous reports to visualize regional issues.
* 🔍 **Leaf Segmentation**: Auto-crops the leaf; removes noisy backgrounds.
* 📚 **Care Playbooks**: Step-by-step remedies with safety & organic options.
* 🔌 **Plugin SDK**: Ship crop packs (e.g., “Tomato Pro”, “Citrus Pack”).
* 🔒 **Privacy Modes**: Offline, Pseudonymous, or Cloud-Assist.

---

## Architecture

```
mobile/Flutter  ──► on-device model (TFLite/ONNX)
        │              ├─ leaf segmentation (U-Net-lite)
        │              └─ classifier (EfficientNet-Lite / MobileViT)
        │
        └─► optional backend (Rust/Axum)
                     ├─ tips & playbooks API
                     ├─ retrieval (Qdrant) for symptom text → remedy
                     ├─ telemetry (opt-in, anonymized)
                     └─ admin console (policies, content, model rolls)
```

---

## Tech Stack

* **Mobile**: Flutter (Dart), camera + ML inference plugins
* **Models**: PyTorch training → export to ONNX → convert to TFLite/Core ML
* **Backend (optional)**: Rust (Axum), PostgreSQL (+PostGIS), Qdrant (vector)
* **Infra**: Docker, GitHub Actions, Sentry, OpenAPI, Terraform (optional)

---

## Models & Data

* **Classifier**: EfficientNet-Lite / MobileViT, multi-label (disease/deficiency/pest).
* **Segmentation**: U-Net-lite for leaf masks to reduce background noise.
* **Training Sources**:

  * PlantVillage (diseases)
  * IP102 (insect pests)
  * Curated nutrient deficiency sets (public ag extensions)
  * Synthetic augmentation (color jitter, speckle, cutout, weathering)
* **Evaluation**: Top-1/Top-3, mAP, per-crop F1; calibrated confidence via temperature scaling.

> Replace/augment datasets per license; keep provenance in `data/cards/`.

---

## Screenshots

* `docs/ui-diagnose.png` — Diagnose view
* `docs/ui-result.png` — Result with confidence + steps
* `docs/ui-map.png` — Outbreak heatmap
* `docs/ui-symptoms.png` — Symptom Q&A

---

## Quick Start

### 1) Mobile app

```bash
# prerequisites: Flutter SDK, Android Studio or Xcode
git clone https://github.com/yourname/leaflens.git
cd leaflens/app
flutter pub get
# download lightweight models (see below)
flutter run
```

### 2) Backend (optional)

```bash
cd ../server
cp .env.example .env   # set DB_URL, QDRANT_URL, JWT_SECRET
docker compose up -d   # postgres, qdrant
cargo run
```

### 3) Models

```bash
# get prebuilt minimal models (~15–25MB total)
./tools/fetch_models.sh
# or build from source datasets
cd research
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python train_classifier.py --cfg configs/tomato.yaml
python export_onnx.py --weights runs/best.pt --out models/leaflens.onnx
python onnx_to_tflite.py models/leaflens.onnx models/leaflens.tflite
```

---

## API (Optional Backend)

**Base URL**: `/v1`

* `POST /diagnose`
  Body: `{ "image_base64": "...", "crop":"tomato", "geo": {"lat":..,"lon":..} }`
  Returns: predictions, confidence, top remedies.

* `POST /symptoms`
  Body: `{ "crop":"citrus", "symptoms":["yellowing","interveinal chlorosis"] }`
  Returns: ranked causes + care steps.

* `GET /playbooks/:code`
  Returns actionable, localized treatment instructions.

OpenAPI spec in `server/openapi.yaml`.

---

## Plugin SDK

Create a crop pack:

```
plugins/
  tomato-pro/
    labels.yaml         # classes, synonyms, metadata
    playbooks/*.md      # treatments with safety notes
    rules/*.toml        # expert system overrides
    thresholds.json     # alert thresholds
```

Register via `plugins.toml` or admin console. Hot-reload supported in dev.

---

## Repo Structure

```
leaflens/
├─ app/                # Flutter app
├─ server/             # Rust Axum backend
├─ models/             # Exported TFLite/ONNX models
├─ research/           # Training code (PyTorch)
├─ plugins/            # Crop packs (community & pro)
├─ docs/               # Images, guides
└─ tools/              # scripts: fetch_models, export, eval
```

---

## Development

```bash
# lint & tests
( cd app && flutter analyze && flutter test )
( cd server && cargo fmt --all && cargo clippy && cargo test )

# seed DB & vector store
./tools/seed.sh
```

**Environment**

* `APP_PRIVACY_MODE` = `offline|pseudonymous|cloud`
* `REGION_CODE` (e.g., `TR`, `EU`) for localized playbooks and regulations
* `MODEL_VERSION` for A/B or staged rollouts

---

## Privacy

* **Offline by default**: Inference runs on device.
* **No account required**; opt-in for cloud features.
* **Telemetry sandboxed**, never stores raw images.
* **Data deletion**: One-tap purge from settings.

See `PRIVACY.md`.

---

## Roadmap

* [ ] Few-shot “unknown disease” handling with visual similarity
* [ ] Multi-image & time-series tracking per plant
* [ ] Soil test integration + sensor bridges (BLE)
* [ ] AR overlay: highlight likely infected regions
* [ ] Human-in-the-loop expert marketplace

---

## Contributing

Issues and PRs welcome! Please read `CONTRIBUTING.md` and follow the commit convention. For model PRs, include a short model card and eval report.

---

## License

MIT © Mehmet T. AKALIN. See `LICENSE`.

---

## Acknowledgements

Thanks to open datasets (PlantVillage, IP102) and ag-extension literature. Always verify treatments with local regulations and certified agronomists.
