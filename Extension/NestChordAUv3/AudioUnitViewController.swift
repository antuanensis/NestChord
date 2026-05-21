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

        NestChordLog.auv3.info("AudioUnitViewController.viewDidLoad")
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
        NestChordLog.auv3.info(
            "createAudioUnit type=\(componentDescription.componentType, privacy: .public) subtype=\(componentDescription.componentSubType, privacy: .public) manufacturer=\(componentDescription.componentManufacturer, privacy: .public)"
        )
        let audioUnit = try NestChordAudioUnit(componentDescription: componentDescription)
        self.audioUnit = audioUnit
        NestChordLog.auv3.info("createAudioUnit completed")

        audioUnit.patternDidChange = { [weak self] pattern in
            Task { @MainActor in
                NestChordLog.state.info("Host restored pattern; updating visible store")
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

        NestChordLog.auv3.info("Connecting PatternStore to AU instance")
        store.replacePatternFromExternalState(audioUnit.currentPattern())
        store.patternDidChange = { [weak audioUnit] pattern in
            NestChordLog.state.info("UI pattern edit published to AU instance")
            audioUnit?.setPatternFromUI(pattern)
        }
    }
}
