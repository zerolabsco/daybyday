//
//  SpeechSynthesizer.swift
//  DayByDay
//

import AVFoundation
import UIKit

/// Wrapper around AVSpeechSynthesizer that selects the highest-quality
/// en-US neural voice available on the device. Falls back gracefully if
/// premium/enhanced voices haven't been downloaded yet.
final class SpeechSynthesizer {
    static let shared = SpeechSynthesizer()

    private let synthesizer = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice?
    private let haptics = UIImpactFeedbackGenerator(style: .rigid)

    private init() {
        self.voice = Self.bestAvailableVoice()
    }

    /// Speaks a pre-configured utterance directly. Used for warmup at launch.
    func speakUtterance(_ utterance: AVSpeechUtterance) {
        synthesizer.speak(utterance)
    }

    func speak(_ text: String) {
        // Every speak() call is a card tap, so give a gentle tactile bump
        // alongside the audio. Prepared just before firing for lowest latency.
        haptics.prepare()
        haptics.impactOccurred()

        // Ensure speech plays through the speaker even when the silent switch is on.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0
        synthesizer.speak(utterance)
    }

    /// Picks the best en-US voice on the device.
    /// Filters for en-US, excludes novelty voices, then sorts by quality
    /// descending so premium (3) > enhanced (2) > default (1).
    private static func bestAvailableVoice() -> AVSpeechSynthesisVoice? {
        let best = AVSpeechSynthesisVoice.speechVoices()
            .filter { voice in
                voice.language.hasPrefix("en-US")
                && !voice.voiceTraits.contains(.isNoveltyVoice)
            }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
            .first

        let selected = best ?? AVSpeechSynthesisVoice(language: "en-US")
        print("[DayByDay] Selected voice: \(selected?.name ?? "nil"), quality: \(selected?.quality.rawValue ?? -1)")
        return selected
    }
}
