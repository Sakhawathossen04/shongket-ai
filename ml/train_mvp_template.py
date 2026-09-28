"""
Shongket AI — MVP training pipeline (Kaggle-friendly).

Pipeline (run on Kaggle with BdSLW60/BdSLW401 attached):
  1. Extract MediaPipe pose landmarks per frame from each sign video.
  2. Build 30-frame windows with the SAME normalisation as the app
     (nose-centred, shoulder-scaled, temporal derivatives).
  3. Train a compact temporal classifier (GRU over frames).
  4. Export labels + per-feature mean/std + linearised class weights
     into assets/models/bdsl_mvp.json for the on-device classifier.

Reference science: BdSLW401 / RQE (Rubaiyeat et al., 2025).
"""

import json
import os
from collections import Counter

import cv2
import mediapipe as mp
import numpy as np

WINDOW = 30
STRIDE = 5
KEYPOINT_INDICES = [
    0, 2, 5, 7, 8, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
]
OUT_JSON = "bdsl_mvp.json"

# ---------------------------------------------------------------- landmarks
_mp_pose = mp.solutions.pose


def extract_landmarks(video_path: str):
    """Returns list of frames, each a dict of landmark x,y in [0,1]."""
    cap = cv2.VideoCapture(video_path)
    frames = []
    with _mp_pose.Pose(static_image_mode=False, model_complexity=1) as pose:
        while True:
            ok, frame = cap.read()
            if not ok:
                break
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            res = pose.process(rgb)
            if res.pose_landmarks is None:
                frames.append(None)
                continue
            pts = []
            for lm in res.pose_landmarks.landmark:
                pts.append((lm.x, lm.y))
            frames.append(pts)
    cap.release()
    return frames


def extract_features(frames):
    """Same normalisation as the app: nose-centred, shoulder-scaled,
    temporal derivatives. Returns (N, 34) arrays (17 pts x 2)."""
    norm = []
    for pts in frames:
        if pts is None:
            norm.append(np.zeros(len(KEYPOINT_INDICES) * 2, dtype=np.float32))
            continue
        nose = np.array(pts[0])
        ls, rs = np.array(pts[11]), np.array(pts[12])
        ref = (ls + rs) / 2 if pts[11] and pts[12] else nose
        scale = max(1e-4, np.linalg.norm(rs - ls))
        row = []
        for i in KEYPOINT_INDICES:
            x, y = pts[i]
            row.extend([(x - ref[0]) / scale, (y - ref[1]) / scale])
        norm.append(np.array(row, dtype=np.float32))

    out = []
    for i, row in enumerate(norm):
        prev = norm[i - 1] if i > 0 else row
        out.append(np.concatenate([row, row - prev]))
    return np.stack(out)


def build_windows(feats, label_idx):
    """Sliding windows matching the app's inference window."""
    X, y = [], []
    if len(feats) < WINDOW:
        feats = np.pad(feats, ((0, WINDOW - len(feats)), (0, 0)))
    for start in range(0, len(feats) - WINDOW + 1, STRIDE):
        X.append(feats[start : start + WINDOW])
        y.append(label_idx)
    return X, y


def train(X, y, n_classes, epochs=12):
    """GRU classifier over frames. Returns (model, scaler_mean, scaler_std)."""
    import torch
    import torch.nn as nn

    X = np.stack(X).astype(np.float32)  # (N, WINDOW, F)
    y = np.array(y)

    mean = X.reshape(-1, X.shape[-1]).mean(axis=0)
    std = X.reshape(-1, X.shape[-1]).std(axis=0) + 1e-6
    Xn = (X - mean) / std

    class SignGRU(nn.Module):
        def __init__(self, f_dim, n_cls, hidden=64):
            super().__init__()
            self.gru = nn.GRU(f_dim, hidden, batch_first=True)
            self.fc = nn.Linear(hidden, n_cls)

        def forward(self, x):
            _, h = self.gru(x)
            return self.fc(h[-1])

    model = SignGRU(X.shape[-1], n_classes)
    opt = torch.optim.Adam(model.parameters(), lr=1e-3)
    lossf = nn.CrossEntropyLoss()
    xt = torch.tensor(Xn)
    yt = torch.tensor(y)

    for ep in range(epochs):
        model.train()
        opt.zero_grad()
        out = model(xt)
        loss = lossf(out, yt)
        loss.backward()
        opt.step()
        print(f"epoch {ep+1}/{epochs} loss={loss.item():.4f}")
    return model, mean, std


def linearise_and_export(model, labels, mean, std, out_path=OUT_JSON):
    """Flatten GRU into per-feature linear weights: average GRU input-gate
    contributions so the app-side linear template classifier can run it.
    (MVP approximation — full GRU runs server-side in Track B.)"""
    import torch

    model.eval()
    with torch.no_grad():
        gru_w_ih = model.gru.weight_ih_l0.numpy()  # (3*H, F)
        gru_w_hh = model.gru.weight_hh_l0.numpy()
        fc_w = model.fc.weight.numpy()  # (C, H)
        fc_b = model.fc.bias.numpy()

        H = fc_w.shape[1]
        F = gru_w_ih.shape[1]
        # Average input + hidden contributions across the sequence: a cheap
        # linear surrogate. Real fix: export GRU and run in TFLite (Track B).
        w_ih = gru_w_ih.reshape(3, H, F).mean(axis=0)
        w_hh = gru_w_hh.reshape(3, H, F).mean(axis=0)
        eff = fc_w @ (w_ih + w_hh)  # (C, F)

        payload = {
            "version": "bdsl-mvp-gru-linearised",
            "labels": labels,
            "window_frames": WINDOW,
            "stride": STRIDE,
            "mean": mean.tolist(),
            "std": std.tolist(),
            "weights": eff.tolist(),
            "bias": fc_b.tolist(),
        }
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(payload, f)
    print(f"exported {out_path} ({os.path.getsize(out_path)/1e6:.1f} MB)")


def main():
    # Kaggle: /kaggle/input/bdslw401 (or bdslw60). Adjust as needed.
    data_root = "/kaggle/input/bdslw401"
    classes = sorted(
        d for d in os.listdir(data_root)
        if os.path.isdir(os.path.join(data_root, d))
    )
    print(f"found {len(classes)} classes: {classes[:5]}...")

    X, y, counts = [], [], Counter()
    for ci, cls in enumerate(classes):
        cdir = os.path.join(data_root, cls)
        vids = [
            os.path.join(cdir, v) for v in os.listdir(cdir)
            if v.lower().endswith((".mp4", ".avi", ".mov"))
        ][:12]  # cap per class for MVP speed
        for v in vids:
            frames = extract_landmarks(v)
            if not frames:
                continue
            feats = extract_features(frames)
            wx, wy = build_windows(feats, ci)
            X.extend(wx)
            y.extend(wy)
            counts[cls] += 1
        print(f"{cls}: {counts[cls]} videos processed")

    labels = classes + ["unknown"]
    n_cls = len(labels)
    model, mean, std = train(X, y, n_cls)
    linearise_and_export(model, labels, mean, std)


if __name__ == "__main__":
    main()
