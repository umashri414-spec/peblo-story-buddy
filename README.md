# Peblo Story Buddy

An AI Story Buddy & Quiz mini-feature built for the Peblo Mobile App Developer Challenge.

## Framework Choice
Built using **Flutter**, chosen for its cross-platform capability (testing on Android device and web), declarative widget-based UI (similar concepts to React-based development I'm familiar with), and strong community package support (flutter_tts, confetti).

## State Transition: Audio → Quiz
The app uses a `StoryState` enum (`idle`, `loading`, `playing`, `finished`, `error`) managed in `StatefulWidget` state. When `flutter_tts`'s `setCompletionHandler` callback fires (audio finished), the state updates to `finished` and `showQuiz` becomes `true`, triggering the quiz UI to render. This ensures the quiz only appears after narration completes, not before.

## Data-Driven Quiz Rendering
The quiz is rendered from a `QuizData` model parsed from a JSON object (`quizJson`), not hardcoded. The `_buildQuiz()` method loops over `quizData.options` using `.map()` to dynamically generate a button for each option — meaning if the backend sends 3, 4, or 5 options, or entirely different question text, the UI adapts automatically without any code changes.

## Caching Approach
Currently, the story text is static and bundled with the app (no remote fetch needed for this prototype). For a production version with remote audio (e.g., ElevenLabs API), I would cache downloaded audio files locally using `path_provider` + a hash of the text content as the filename, checking the local cache before making a new API call to avoid redundant downloads and reduce latency on repeat plays.

## Audio Loading & Failure Handling
- **Loading state:** Button shows a spinner + "Reading..." text while TTS initializes and plays.
- **Failure state:** If `flutter_tts.speak()` returns a non-success result or throws an error (via `setErrorHandler`), the UI shows a friendly "Oops! Couldn't read the story" message with a "Try Again" button — preventing the app from hanging or crashing.

## Performance Optimization for Mid-Range Devices
- Used `AnimatedContainer` and `AnimatedBuilder` (not full widget rebuilds) for the buddy state changes and shake animation, minimizing unnecessary re-renders.
- Shake animation driven by a single `AnimationController` with a math-based sine wave transform rather than multiple chained animations.
- Confetti uses the lightweight `confetti` package with a bounded duration (2 seconds) and limited particle count (30) to avoid frame drops on lower-end GPUs.

## AI Usage & Judgment
I used Claude (Anthropic) as a coding assistant throughout this challenge, given this was my first Flutter project after primarily working in React Native.
- **What AI helped with:** Generating the initial widget structure, the data-driven quiz rendering pattern, and the TTS state management logic.
- **A suggestion I rejected:** AI initially suggested embedding the quiz JSON as a hardcoded `Map` directly in the build method. I asked for it to be refactored into a proper `QuizData` model class with a `fromJson` factory constructor instead, since the assignment explicitly required a structure that could handle backend-driven changes without code edits — a hardcoded inline map would not have satisfied that data-driven requirement.
- **What didn't work initially:** Web platform testing (Edge browser) showed intermittent TTS failures due to browser speechSynthesis API limitations — this is a documented browser-level constraint, not an app bug. I resolved this by confirming the error-handling path (the "Try Again" UI) works correctly, and noted that native Android/iOS TTS engines (used via `flutter_tts`) are more reliable for production use than browser-based TTS.

## Tech Stack
- Flutter (Dart
