import AudioToolbox
import PluginUI
import SwiftUI
import UIKit

public final class AudioUnitViewController: UIViewController, AUAudioUnitFactory {
    private let store = PatternStore()
    private var hostingController: UIHostingController<NestChordEditorView>?
    nonisolated(unsafe) private var audioUnit: NestChordAudioUnit?

    public override func viewDidLoad() {
        super.viewDidLoad()

        connectStoreToAudioUnitIfNeeded()
        let editor = NestChordEditorView(store: store)
        let host = UIHostingController(rootView: editor)
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        hostingController = host
    }

    nonisolated public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let audioUnit = try NestChordAudioUnit(componentDescription: componentDescription)
        self.audioUnit = audioUnit

        audioUnit.patternDidChange = { [weak self] pattern in
            Task { @MainActor in
                self?.store.replacePatternFromExternalState(pattern)
            }
        }
        audioUnit.diagnosticsDidChange = { [weak self] diagnostics, events in
            Task { @MainActor in
                self?.store.replaceHostDiagnostics(diagnostics, recentEvents: events)
            }
        }

        Task { @MainActor in
            self.connectStoreToAudioUnitIfNeeded()
        }

        return audioUnit
    }

    private func connectStoreToAudioUnitIfNeeded() {
        guard let audioUnit else { return }

        store.replacePatternFromExternalState(audioUnit.currentPattern())
        store.patternDidChange = { [weak audioUnit] pattern in
            audioUnit?.setPatternFromUI(pattern)
        }
    }
}
