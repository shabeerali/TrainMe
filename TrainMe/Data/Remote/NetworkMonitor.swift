import Foundation
import Network

protocol ConnectivityChecking: Sendable {
    var isConnected: Bool { get }
    /// Emits whenever connectivity flips (true = online).
    func updates() -> AsyncStream<Bool>
}

final class NetworkMonitor: ConnectivityChecking, @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "trainme.network-monitor")
    private let lock = NSLock()
    private var connected = true
    private var subscribers: [UUID: AsyncStream<Bool>.Continuation] = [:]

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.update(path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }

    var isConnected: Bool {
        lock.lock(); defer { lock.unlock() }
        return connected
    }

    func updates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let id = UUID()
            self.lock.lock()
            self.subscribers[id] = continuation
            self.lock.unlock()
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.lock.lock()
                self.subscribers[id] = nil
                self.lock.unlock()
            }
        }
    }

    private func update(_ isConnected: Bool) {
        lock.lock()
        guard connected != isConnected else { lock.unlock(); return }
        connected = isConnected
        let current = Array(subscribers.values)
        lock.unlock()
        current.forEach { $0.yield(isConnected) }
    }
}
