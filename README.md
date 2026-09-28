# Shongket AI 🤟

**Offline, confidence-aware two-way Bangla Sign Language (BdSL) communication companion** — Deaf ↔ Hearing, essential public services context (hospital, emergency, government), সম্পূর্ণ on-device।

> Built for ZRF. Architecture pattern inspired by [KawanIsyarat](https://github.com/haipradana/KawanIsyarat) (MIT).
> BdSL research foundation: [BdSLW401 / RQE](https://github.com/hasanssl/RQE) (Rubaiyeat et al., 2025).

---

## 📱 APK কীভাবে পাবেন

1. এই repo-টা GitHub-এ push করুন (`main` branch)।
2. **Actions** tab → **Build APK** workflow স্বয়ংক্রিয়ভাবে চলবে (push-এ trigger হয়, অথবা **Run workflow** চাপুন)।
3. প্রায় ৮–১২ মিনিটে:
   - **Artifacts** সেকশনে `shongket-ai-apk` ডাউনলোড করুন, অথবা
   - **Releases** সেকশনে `shongket-ai-v*.apk` পাবেন।
4. Android 7.0+ ফোনে install করুন (unknown sources allow করতে হবে)।

## 🏗️ পাইপলাইন

```
Deaf → Hearing:
  Camera → ML Kit Pose (33 landmarks) → 76-float normalised features
  → 30-frame sliding window → sign classifier → gloss sequence
  → confidence-aware বাংলা বাক্য → TTS (bn-BD)

Hearing → Deaf:
  Mic → platform speech recognizer (bn-BD) → বড় করে পাঠ্য প্রদর্শন
```

### Confidence-aware (আমাদের core feature)

কোনো sign-এর confidence **60%**-এর নিচে হলে অ্যাপ ভুল বাক্য বলবে না —
পরিবর্তে বলবে: *“শেষ sign-টি আমি নিশ্চিতভাবে বুঝতে পারিনি। আবার দেখান।”*
Emergency mode-এ আরও সতর্ক বার্তা। Top-3 candidates UI-তে দেখা যায়।

## 🧠 Model

- `assets/models/bdsl_mvp.json` — placeholder (uniform probabilities)।
- **প্রকৃত model:** Kaggle-এ `ml/train_mvp_template.py` চালান
  ([BdSLW401 dataset](https://www.kaggle.com/datasets/hasanssl/bdslw401) attach করে)।
  এটা `bdsl_mvp.json` তৈরি করবে — সেটা `assets/models/`-এ replace করে push করলেই
  অ্যাপে trained model চলে আসবে (next Actions build-এ নতুন APK)।
- App ও training pipeline একই feature normalisation ব্যবহার করে
  (nose-centred, shoulder-scaled, temporal derivatives) — তাই training/app
  consistent থাকে।

## 🗂 Vocabulary

`assets/vocab/bdsl_vocab.json` — ৬০টা BdSL sign, service-category ভাগ করা:
hospital / emergency / government / general + ৬টা emergency phrase।
নতুন sign যোগ করতে JSON-এ entry যোগ করুন; model labels-এও যোগ হতে হবে।

## ✅ Test

```bash
flutter test
```

## 📄 License

MIT — [LICENSE](LICENSE) দেখুন। KawanIsyarat-এর MIT attribution সংরক্ষিত।
