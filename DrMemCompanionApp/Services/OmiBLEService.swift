import Foundation
import CoreBluetooth

@Observable
class OmiBLEService: NSObject {
    var isScanning: Bool = false
    var isConnected: Bool = false
    var discoveredDeviceName: String?
    var statusMessage: String = "Not connected"
    var signalStrength: Int = 0

    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var scanTimeoutTask: Task<Void, Never>?

    private let audioServiceUUID = CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214")
    private let audioCharUUID = CBUUID(string: "19B10001-E8F2-537E-4F6C-D104768A1214")
    private let codecCharUUID = CBUUID(string: "19B10002-E8F2-537E-4F6C-D104768A1214")

    var onAudioData: ((Data) -> Void)?

    func startScan() {
        guard !isScanning else { return }
        isScanning = true
        statusMessage = "Initializing Bluetooth..."

        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: .main)
        } else if centralManager?.state == .poweredOn {
            beginScanning()
        }

        scanTimeoutTask?.cancel()
        scanTimeoutTask = Task {
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled else { return }
            if isScanning && !isConnected {
                stopScan()
                statusMessage = "No Omi device found. Make sure it's nearby and powered on."
            }
        }
    }

    func stopScan() {
        isScanning = false
        centralManager?.stopScan()
        scanTimeoutTask?.cancel()
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        isConnected = false
        discoveredDeviceName = nil
        statusMessage = "Disconnected"
    }

    private func beginScanning() {
        statusMessage = "Scanning for Omi device..."
        centralManager?.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }
}

extension OmiBLEService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                if isScanning {
                    beginScanning()
                }
            case .poweredOff:
                isScanning = false
                isConnected = false
                statusMessage = "Bluetooth is turned off"
            case .unauthorized:
                isScanning = false
                statusMessage = "Bluetooth permission denied"
            case .unsupported:
                isScanning = false
                statusMessage = "Bluetooth not supported on this device"
            default:
                statusMessage = "Bluetooth unavailable"
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
        let isOmi = name.lowercased().contains("omi") ||
                     name.lowercased().contains("friend") ||
                     name.lowercased().contains("based")

        guard isOmi else { return }

        Task { @MainActor in
            stopScan()
            discoveredDeviceName = name
            statusMessage = "Found \(name), connecting..."
            connectedPeripheral = peripheral
            peripheral.delegate = self
            central.connect(peripheral, options: nil)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            isConnected = true
            statusMessage = "Connected to \(peripheral.name ?? "Omi")"
            peripheral.discoverServices([audioServiceUUID])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            isConnected = false
            statusMessage = "Connection failed: \(error?.localizedDescription ?? "Unknown error")"
            connectedPeripheral = nil
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            isConnected = false
            connectedPeripheral = nil
            statusMessage = "Disconnected from \(peripheral.name ?? "Omi")"

            Task {
                try? await Task.sleep(for: .seconds(2))
                if !isConnected {
                    startScan()
                }
            }
        }
    }
}

extension OmiBLEService: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        Task { @MainActor in
            for service in services {
                if service.uuid == audioServiceUUID {
                    peripheral.discoverCharacteristics([audioCharUUID, codecCharUUID], for: service)
                }
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        Task { @MainActor in
            for characteristic in characteristics {
                if characteristic.uuid == audioCharUUID {
                    peripheral.setNotifyValue(true, for: characteristic)
                    statusMessage = "Connected — streaming audio"
                }
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == audioCharUUID, let data = characteristic.value else { return }
        Task { @MainActor in
            onAudioData?(data)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        Task { @MainActor in
            signalStrength = RSSI.intValue
        }
    }
}
