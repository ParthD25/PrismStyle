# Apple AI Integration Plan (PrismStyle)

Date: 2025-12-21

This document describes how to make PrismStyle “truly AI” using **Apple-provided, on-device** technologies.

The current app already has:
- A strong rule-based recommender and learning layer (see PrismStyle/EnhancedStyleBrain.swift and PrismStyle/StyleMemory.swift).
- Camera capture and multi-photo flow (PrismStyle/EnhancedCameraBurstView.swift + PrismStyle/EnhancedStyleFlowView.swift).

The main gap is that photo analysis is mostly heuristic (image quality + text matching) rather than semantic understanding of clothing. Apple’s AI stack can fill that gap.

---

## Goals

1. On-device image understanding:
   - Detect “is this a full outfit photo?” reliably.
   - Identify clothing categories (top/bottom/shoes/outerwear) and coarse attributes (dominant colors, patterns) from images.

2. Better recommendations without changing UX:
   - Keep the existing UI steps and screens.
   - Upgrade the *engine behind* the existing “Analyze outfit” and “Recommend from closet” flows.

3. Optional (future): Apple Intelligence text generation
   - Improve the wording/justification of suggestions and extract structured constraints from free text.
   - Must be gated by OS availability.

---

## Constraints to decide up front (you choose)

### Minimum iOS version
- Current project target is iOS 17.0.
- Apple Intelligence / Foundation Models frameworks are only available on newer iOS versions (per Apple docs; see links below). If you want to keep iOS 17 support, the LLM portion must be optional and guarded by availability.

### On-device only vs cloud
- This plan assumes on-device processing (Core ML + Vision + NaturalLanguage) for privacy and App Store simplicity.
- If you want cloud AI later, treat it as a separate track.

---

## What “Apple AI” means for this app

### 1) Vision + Core ML (core upgrade)
Use Vision to run Core ML models and do image pre/post-processing:
- Person/foreground segmentation (focus on clothing).
- Object detection / classification via custom models (garment category, pattern, maybe material).

Result: when a user uploads a photo or takes a burst, PrismStyle can extract structured signals instead of guessing.

### 2) NaturalLanguage (text understanding)
Use NaturalLanguage to:
- Parse user input like occasion/vibe (“smart casual”, “warm colors”, “no logos”).
- Normalize item notes (“linen”, “oversized”) into your internal tags.

Result: the engine can reliably interpret free text and consistently apply constraints.

### 3) App Intents (system integration)
You already have AppIntents imported in PrismStyle/PrismStyleApp.swift.
Extend this for:
- “Recommend an outfit” Shortcut.
- “Log today’s outfit” Shortcut.

Result: the app feels like a real “assistant” inside iOS without inventing new screens.

### 4) Foundation Models (optional, OS-gated)
If you decide to support newer iOS versions, you can use Apple’s on-device LLM for:
- High-quality explanation text.
- Structured extraction: turn a free prompt into a typed recommendation request.
- Tool calling to query your closet / StyleMemory.

Result: recommendations become more natural-language and personalized while still staying on-device.

---

## Recommended architecture (fits your current code)

### A. Add a dedicated on-device “Photo Understanding” module
Create a small module (new folder/group) such as:
- PrismStyle/AI/VisionFeatureExtractor.swift
- PrismStyle/AI/PhotoUnderstandingTypes.swift

Define an output type like:
- OutfitPhotoFeatures
  - isOutfitPhotoConfidence
  - detectedGarments: [GarmentFeature]
  - dominantColors: [String] (hex)
  - imageQuality: Double (you already compute this)

Implementation:
- Input: UIImage
- Output: OutfitPhotoFeatures

### B. Feed those features into existing flows
1) Multiple-outfit photo comparison (EnhancedStyleFlowView)
- Today you pick “best” by ImageScoring.sharpnessScore.
- Upgrade to rank by: image quality + “outfit photo confidence” + presence of key garments.

2) Photo analysis of looks (EnhancedStyleBrain.analyzeSingleOutfitPhoto)
- Replace/augment heuristics with:
  - garment completeness score (has top + bottom + shoes)
  - color palette compatibility vs user preferences
  - pattern/contrast balance

3) Closet item enrichment (EnhancedAddClothingItemView)
- Optional step (behind existing UI): when user adds an item photo, extract:
  - primary color hex
  - category suggestion
  - pattern tag

Store those into ClothingItem fields so recommendation quality improves over time.

### C. Keep StyleMemory as the “learning” layer
- Continue to learn from user choices, but use better feature signals (colors/categories/pattern tags) rather than only names/notes.

---

## Model strategy (practical)

### Phase 1 (fast, no custom training)
- Use Vision primitives (segmentation/person rectangle) + your existing color extraction logic.
- This already improves robustness and avoids “fake AI” perception.

### Phase 2 (custom Core ML models)
- Train a garment classifier/detector using datasets you already referenced (e.g., DeepFashion2).
- Export to .mlmodel / .mlpackage.
- Integrate with Vision requests.

Deliverables:
- A small on-device model for garment category and basic attributes.

Notes:
- Training happens outside the iOS app (Mac tooling / ML pipeline). The app only runs the model.

---

## Milestones (recommended order)

### Milestone 1: Clean “AI plumbing” (1–2 days)
- Add `OutfitPhotoFeatures` types.
- Add `VisionFeatureExtractor` that at minimum returns:
  - `imageQuality` (already computed)
  - `isOutfitPhotoConfidence` (initially use your current heuristic + optional Vision person detection)
  - `dominantColors` (reuse existing color helpers)
- Wire into multiple-photo flow ranking.

Success criteria:
- Multi-photo selection chooses better outfit photos (less blur, more full-body, consistent lighting).

### Milestone 2: Improve photo analysis explanations (1–2 days)
- Use extracted features inside EnhancedStyleBrain photo analysis.
- Update confidence/breakdown based on measurable signals (presence of full outfit, color palette).

Success criteria:
- The app’s “Style breakdown” becomes consistent and data-driven.

### Milestone 3: Closet item auto-tagging (2–4 days)
- When adding a clothing item (photo), auto-suggest:
  - category
  - primary color
  - pattern
- Persist into SwiftData.

Success criteria:
- New items become more useful immediately without manual typing.

### Milestone 4: Custom Core ML garment model (multi-week, parallelizable)
- Build/training pipeline for detection/classification.
- Convert and evaluate performance on a test set.
- Integrate into `VisionFeatureExtractor`.

Success criteria:
- Category detection accuracy is “good enough” for consumer use.

### Milestone 5 (optional): Apple Intelligence / Foundation Models (newer iOS only)
- Add an availability-gated “Narrator” layer:
  - If supported, generate the `why` and `detailedSuggestion` text from structured features + the outfit recommendation result.
  - Otherwise fall back to current templated text.

Success criteria:
- Text quality improves without changing UI.

---

## Risks / gotchas

- OS availability: Foundation Models / Visual Intelligence require newer iOS versions.
- Dataset licensing: ensure your training data is used legally and matches your distribution model.
- App Store review: be explicit about on-device processing and request camera/photo permissions only when needed.

---

## Apple documentation (starting points)

- Vision: https://developer.apple.com/documentation/vision
- Core ML: https://developer.apple.com/documentation/coreml
- NaturalLanguage: https://developer.apple.com/documentation/naturallanguage
- Create ML: https://developer.apple.com/documentation/createml
- App Intents: https://developer.apple.com/documentation/appintents
- Foundation Models: https://developer.apple.com/documentation/foundationmodels
- Visual Intelligence: https://developer.apple.com/documentation/visualintelligence
- Camera authorization: https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media
