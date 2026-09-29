import AppKit
import Combine
import ServiceManagement

@MainActor final class AppModel: ObservableObject {
    @Published var usage: UsageResponse?
    @Published var updated: Date?
    @Published var error: String?
    @Published var refreshing = false
    @Published var now = Date()
    @Published var selection = 0
    let client = UsageClient()
    private var timer: Timer?
    private var lastAttempt = Date.distantPast
    private var failures = 0
    var entries: [(String, LimitWindow)] {
        usage?.buckets.flatMap { key, bucket in
            bucket.windows.map { ((bucket.limitName ?? key) == "codex" ? $0.label : "\(bucket.limitName ?? key) · \($0.label)", $0) }
        } ?? []
    }
    var window: LimitWindow? { entries.indices.contains(selection) ? entries[selection].1 : entries.first?.1 }
    var credits: Int? { usage?.rateLimitResetCredits?.availableCount }
    var stale: Bool { error != nil || updated.map { now.timeIntervalSince($0) > 150 } == true }
    func start(demo: Bool = false) {
        guard timer == nil else { return }
        if demo { usage = .demo; updated = Date() } else { refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.now = Date()
                if !demo, self.now.timeIntervalSince(self.lastAttempt) >= RefreshPolicy.interval(failures:self.failures) { self.refresh() }
            }
        }
        timer?.tolerance = 5
    }
    func refresh() {
        guard !refreshing else { return }
        lastAttempt = Date()
        refreshing = true
        Task {
            defer { refreshing = false }
            do {
                let result = try await client.read()
                if usage != result { usage = result }
                updated = Date(); now = Date(); error = nil; failures = 0
                if selection >= entries.count { selection = 0 }
            } catch {
                failures = min(failures + 1, 4)
                self.error = error.localizedDescription
            }
        }
    }
}

@MainActor final class LoginModel: ObservableObject {
    @Published var enabled = SMAppService.mainApp.status == .enabled
    @Published var message: String?
    func set(_ value: Bool) {
        do {
            if value { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            enabled = SMAppService.mainApp.status == .enabled
            message = SMAppService.mainApp.status == .requiresApproval ? L("请在系统设置 → 通用 → 登录项中允许启动。", "Allow launch at login in System Settings → General → Login Items.") : nil
        } catch { message = L("无法更新开机启动：\(error.localizedDescription)", "Could not change launch at login: \(error.localizedDescription)") }
    }
}
