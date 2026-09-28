# Shongket AI — Roadmap

> **An Offline, Confidence-Aware Bangla Sign Communication System for Essential Public Services**
> ZRF submission deadline: **৩০ সেপ্টেম্বর ২০২৬** — আজ থেকে ২ দিন।
> তাই roadmap-এর দুইটা track: **[A] 48-Hour MVP** (submission-এর জন্য) এবং **[B] Post-hackathon** (full version)।

---

## 0. Positioning (কী বলব না, কী বলব)

❌ বলব না: "KawanIsyarat-এর Bangla clone" / "full sign language translator"
✅ বলব: **"Prototype supports a defined BdSL vocabulary (~60 signs) and demonstrates continuous, confidence-aware communication within essential-service scenarios (hospital, emergency, government form) — fully offline."**

**Novelty stack (ZRF originality-র ভিত্তি):**
1. BdSL dataset (BdSLW401/BdSLW60) — Bangladesh-এর নিজস্ব research dataset ব্যবহার
2. Confidence-aware translation — uncertain sign-এ ভুল বলবে না, আবার দেখাতে বলবে
3. Essential-service modes — Hospital / Emergency / Government (BdSL-specific vocabulary)
4. Offline-first — camera → recognition → Bangla sentence → TTS, কোনো cloud নেই

---

## 1. Track A — 48-Hour MVP Plan

### MVP scope (finalize করা definition)
- **Vocabulary:** ৫০–৬০টা BdSL sign (hospital/emergency/government relevant গুলো আগে বাছব)
- **Input:** camera → MediaPipe landmarks → 30-frame window → classifier
- **Output:** gloss → Bangla sentence → Bangla TTS
- **Confidence:** top-3 probability + threshold-এর নিচে হলে "আবার দেখান" fallback
- **Emergency card:** ৬টা one-tap phrase (TTS + screen text)
- **Reverse (minimal):** hearing user-এর speech → text display (কোনো fancy LLM ছাড়াই যথেষ্ট)

### Hour-by-hour (Team-এ ভাগ করা কাজ)

**Phase 0 — Setup & Freeze (Hour 0–4)**
- [ ] Kaggle-এ BdSLW401 dataset attach (dataset license + Kaggle terms চেক) — অথবা সহজপাত BdSLW60 (60 signs, ছোট)
- [ ] MVP vocabulary বাছাই: index list (JSON) — hospital/emergency/govt sign-গুলো আগে
- [ ] Repo scaffold: `app/` (Flutter) + `ml/` (Kaggle notebooks) + `docs/`
- [ ] KawanIsyarat থেকে reference: MIT license notice preserve করে app architecture pattern (Riverpod, Cactus FFI service, MediaPipe service structure)
- [ ] ⚠️ RQE repo **GPL v2** — code copy নয়, শুধু paper-এর method reference

**Phase 1 — ML Training on Kaggle (Hour 4–16, parallel-এ চলবে)**
- [ ] Landmark extraction: MediaPipe Holistic (pose upper-body + 2 hand) → per-frame feature vector
- [ ] সব selected sign-এর ভিডিও pre-process করে `.npz` cache (Kaggle-এ একবার, তারপর training দ্রুত)
- [ ] Model: 1D CNN / small GRU over 30-frame windows → N sign + 1 "no-sign/unknown" class
- [ ] Baseline metric: confusion matrix + per-sign accuracy (demo-তে honest numbers দেখাব)
- [ ] Export: **TFLite INT8** (phone-এ দ্রুত চলার জন্য)
- [ ] Output artifact: `model/bdsl_mvp.tflite` + `model/labels.json` → GitHub release-এ push
- [ ] GitHub Actions: শুধু CI (analyze/test) — training কোনোভাবেই Actions-এ নয় (free runner-এ GPU নেই), training সব Kaggle-এ

**Phase 2 — Flutter App (Hour 8–32, Phase 1-এর সমান্তরালে)**
- [ ] Flutter + Riverpod + GoRouter (KawanIsyarat pattern)
- [ ] Camera + MediaPipe live landmark stream
- [ ] 30-frame sliding window → TFLite inference → gloss
- [ ] Bangla sentence assembly: **MVP-তে template-based** (gloss → "আমি / ব্যথা / পেট" → "আমার পেটে ব্যথা")
- [ ] Gemma via Cactus (E2B INT4): sentence polish — **stretch goal**, template কাজ করলে ছাড়াই যাবে
- [ ] `flutter_tts` — Bangla (bn-BD) voice
- [ ] Confidence UI: top-3 bar + "নিশ্চিত নই — আবার দেখান" state
- [ ] Mode selector: Hospital / Emergency / Government (vocabulary priority reorder)
- [ ] Emergency card: ৬টা phrase, one tap → TTS
- [ ] Speech-to-text (hearing→deaf): `speech_to_text` package → text display

**Phase 3 — Integration & Honest Testing (Hour 32–42)**
- [ ] Android (mid/high-range) device-এ full E2E টেস্ট
- [ ] Latency budget: inference < 200ms/frame, TTS তাৎক্ষণিক
- [ ] ৩ জন ভিন্ন মানুষ দিয়ে sign টেস্ট → real accuracy number বের করা
- [ ] Failure mode নথিভুক্ত: কোন sign ভুল হয়, confidence কত দেখায়

**Phase 4 — Demo & Submission (Hour 42–48)**
- [ ] Demo video: real phone screen-recording + narration (BdSL demo দেখাতে হবে)
- [ ] Landing page: README + GitHub Pages (architecture diagram, honest accuracy)
- [ ] ZRF writeup: novelty stack (Section 0) + limitations disclosure
- [ ] ২–৩ ঘণ্টা buffer রাখা — hard stop ৪৫ তম ঘণ্টায়

### MVP-তে যা থাকবে না (explicitly out of scope)
- Continuous full-sentence SLR (sign boundary segmentation) → Track B
- ৪০১ sign full coverage → Track B
- Gemma-powered natural conversation polish → stretch goal
- Facial expression / non-manual marker recognition → Track B

---

## 2. Track B — Post-hackathon Full Roadmap (ক্রমানুসারে)

**B1. Continuous recognition (সবচেয়ে বড় upgrade)**
- Sliding-window classifier → sign boundary detection (energy/peak-based) → sign sequence
- BdSLW401 full 401-class training (Kaggle, multi-GPU)
- Delimiter sign / rest-pose modeling দিয়ে sentence segmentation

**B2. Uncertainty-aware sequence decoding**
- Per-sign confidence + CTC-style alignment
- Low-confidence segment বাদ দিয়ে "আংশিক বুঝেছি" sentence তৈরি

**B3. Two-way full loop**
- Bangla speech → STT (on-device Whisper-INT8) → simple Bangla → gloss → sign animation/avatar
- sign video reference: BdSLW401 sample clips দিয়ে playback learning mode

**B4. Real-world hardening**
- Signer-independent evaluation (leave-one-signer-out, like the paper)
- Front + lateral view robustness (dataset-এ দুটো view আছে)
- Low-light / front-camera টেস্ট

**B5. Bangladesh public-service integration (vision)**
- হাসপাতাল রেজিস্ট্রেশন kiosk mode
- সরকারি ফর্ম helper (NID/জন্ম নিবন্ধন vocabulary)

---

## 3. Risks & Mitigation

| Risk | Likelihood | Mitigation |
|---|---|---|
| Kaggle GPU quota শেষ | মাঝারি | ছোট dataset subset (BdSLW60), শুধু landmark cache-এ train — T4-এ ১–২ ঘণ্টায় হয় |
| Phone-এ Gemma ধীর/OOM | মাঝারি | Template-based Bangla sentence হলো default; Gemma শুধু settings toggle |
| ভুল translation embarrass করবে | উচ্চ | Confidence threshold + unknown class — এটাই আমাদের core feature |
| ২ দিনে Flutter app শেষ হবে না | মাঝারি | Phase 2-এর প্রতিটা item-এর cut-order আগেই ঠিক: emergency card + sign recognition প্রথম |
| Dataset access/license সমস্যা | কম | Kaggle dataset page-এর terms আগে পড়া; ব্যর্থ হলে নিজেরা ২০–৩০ sign রেকর্ড করা fallback |

---

## 4. Next Step (Track A Phase 0)

1. Repo scaffold তৈরি (`app/`, `ml/`, `docs/`)
2. Kaggle-এ BdSLW60/BdSLW401 attach + MVP sign list JSON
3. Landmark-extraction notebook (Kaggle) লেখা — এটা critical path-এর প্রথম block
