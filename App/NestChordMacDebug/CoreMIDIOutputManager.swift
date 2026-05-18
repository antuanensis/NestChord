import CoreMIDI
import Foundation
import SequencerCore

struct MIDIDestination: Identifiable, Hashable {
    var id: MIDIUniqueID
    var endpoint: MIDIEndpointRef
    var name: String
}

final class CoreMIDIOutputManager: ObservableObject, MIDIOutputSink {
    @Published private(set) var destinations: [MIDIDestination] = []
    @Published var selectedDestinationID: MIDIUniqueID?
    @Published private(set) var statusMessage = "CoreMIDI ready"

    private var client = MIDIClientRef()
    private var outputPort = MIDIPortRef()
    private var virtualSource = MIDIEndpointRef()

    init() {
        setupCoreMIDI()
        refreshDestinations()
    }

    deinit {
        if virtualSource != 0 {
            MIDIEndpointDispose(virtualSource)
        }
        if outputPort != 0 {
            MIDIPortDispose(outputPort)
        }
        if client != 0 {
            MIDIClientDispose(client)
        }
    }

    var selectedDestinationName: String {
        if let selectedDestination {
            selectedDestination.name
        } else {
            "NestChord Debug Source"
        }
    }

    func useVirtualSource() {
        selectedDestinationID = nil
        statusMessage = "Sending to virtual source"
    }

    func selectDestination(_ destination: MIDIDestination) {
        selectedDestinationID = destination.id
        statusMessage = "Sending to \(destination.name)"
    }

    func refreshDestinations() {
        var refreshed: [MIDIDestination] = []

        for index in 0..<MIDIGetNumberOfDestinations() {
            let endpoint = MIDIGetDestination(index)
            guard endpoint != 0,
                  let uniqueID = endpointUniqueID(endpoint) else {
                continue
            }

            refreshed.append(MIDIDestination(
                id: uniqueID,
                endpoint: endpoint,
                name: endpointDisplayName(endpoint)
            ))
        }

        destinations = refreshed.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if let selectedDestinationID,
           !destinations.contains(where: { $0.id == selectedDestinationID }) {
            self.selectedDestinationID = nil
        }
    }

    func send(_ events: [MIDINoteEvent]) {
        for event in events {
            send(event)
        }
    }

    private var selectedDestination: MIDIDestination? {
        guard let selectedDestinationID else { return nil }
        return destinations.first { $0.id == selectedDestinationID }
    }

    private func setupCoreMIDI() {
        let clientStatus = MIDIClientCreate("NestChord Debug" as CFString, nil, nil, &client)
        guard clientStatus == noErr else {
            statusMessage = "MIDI client error \(clientStatus)"
            return
        }

        let portStatus = MIDIOutputPortCreate(client, "NestChord Output" as CFString, &outputPort)
        guard portStatus == noErr else {
            statusMessage = "MIDI output port error \(portStatus)"
            return
        }

        let sourceStatus = MIDISourceCreate(client, "NestChord Debug Source" as CFString, &virtualSource)
        guard sourceStatus == noErr else {
            statusMessage = "MIDI virtual source error \(sourceStatus)"
            return
        }

        statusMessage = "Sending to virtual source"
    }

    private func send(_ event: MIDINoteEvent) {
        let statusBase: UInt8 = event.kind == .noteOn ? 0x90 : 0x80
        let channel = UInt8(max(0, min(15, Int(event.channel) - 1)))
        let status = statusBase | channel
        let velocity = event.kind == .noteOn ? event.velocity : 0
        let bytes = [status, event.noteNumber, velocity]

        withPacketList(bytes: bytes) { packetListPointer in
            if let selectedDestination {
                let sendStatus = MIDISend(outputPort, selectedDestination.endpoint, packetListPointer)
                if sendStatus != noErr {
                    statusMessage = "MIDI send error \(sendStatus)"
                }
            } else if virtualSource != 0 {
                MIDIReceived(virtualSource, packetListPointer)
            }
        }
    }

    private func withPacketList(bytes: [UInt8], _ body: (UnsafePointer<MIDIPacketList>) -> Void) {
        var packetList = MIDIPacketList()
        withUnsafeMutablePointer(to: &packetList) { packetListPointer in
            var packet = MIDIPacketListInit(packetListPointer)
            bytes.withUnsafeBufferPointer { buffer in
                guard let baseAddress = buffer.baseAddress else { return }
                packet = MIDIPacketListAdd(
                    packetListPointer,
                    MemoryLayout<MIDIPacketList>.size,
                    packet,
                    0,
                    bytes.count,
                    baseAddress
                )
            }
            body(UnsafePointer(packetListPointer))
        }
    }

    private func endpointDisplayName(_ endpoint: MIDIEndpointRef) -> String {
        var unmanagedName: Unmanaged<CFString>?
        MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &unmanagedName)

        if let unmanagedName {
            return unmanagedName.takeRetainedValue() as String
        }

        return "MIDI Destination \(endpoint)"
    }

    private func endpointUniqueID(_ endpoint: MIDIEndpointRef) -> MIDIUniqueID? {
        var uniqueID = MIDIUniqueID()
        let status = MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &uniqueID)
        return status == noErr ? uniqueID : nil
    }
}
