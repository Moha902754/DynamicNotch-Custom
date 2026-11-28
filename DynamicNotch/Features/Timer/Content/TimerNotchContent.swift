internal import AppKit
import SwiftUI

struct TimerNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id: String
    let source: TimerSource
    let settingsViewModel: SettingsViewModel?
    let notchViewModel: NotchViewModel?

    var priority: Int {
        switch source {
        case .system:
            return NotchContentRegistry.Media.timer.priority
        case .local:
            return NotchContentRegistry.Media.localTimer.priority
        }
    }
    
    var strokeColor: Color {
        .orange.opacity(0.3)
    }

    var isExpandable: Bool { true }

    var supportsDot: Bool { true }

    @MainActor
    func dotView() -> AnyView {
        AnyView(TimerCompactIndicatorView(source: source, size: 16, lineWidth: 2.2))
    }

    var windowLink: (@MainActor () -> Void)? {
        switch source {
        case .system:
            return {
                Self.openClockApp()
            }
        case .local:
            return nil
        }
    }

    @MainActor
    static func openClockApp() {
        if let runningTimerURL = URL(string: "clock-timer-running:"), NSWorkspace.shared.open(runningTimerURL) {
            return
        }
        ApplicationActivator.shared.openOrActivate(bundleIdentifier: "com.apple.clock")
    }

    init(source: TimerSource, settingsViewModel: SettingsViewModel? = nil, notchViewModel: NotchViewModel? = nil) {
        self.source = source
        self.settingsViewModel = settingsViewModel
        self.notchViewModel = notchViewModel
        switch source {
        case .system:
            self.id = NotchContentRegistry.Media.timer.id
        case .local:
            self.id = NotchContentRegistry.Media.localTimer.id
        }
    }

    init(timerViewModel: TimerViewModel, settingsViewModel: SettingsViewModel, notchViewModel: NotchViewModel? = nil) {
        self.source = .system(timerViewModel)
        self.settingsViewModel = settingsViewModel
        self.notchViewModel = notchViewModel
        self.id = NotchContentRegistry.Media.timer.id
    }

    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + minimalTimerSize, height: baseHeight)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + minimalTimerSize - 10, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 170, height: baseHeight + 60)
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 250, height: baseHeight + 50)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 38)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }

    @MainActor
    func compactView() -> AnyView {
        AnyView(TimerNotchView(source: source))
    }

    @MainActor
    func expandedView() -> AnyView {
        AnyView(TimerExpandedNotchView(source: source, notchViewModel: notchViewModel))
    }
}

extension TimerNotchContent {
    var minimalTimerSize: CGFloat {
        switch source.formattedTime(at: .now) {
        case let value where value.contains("h"):
            return 150
        case let value where value.contains(":") || value.hasSuffix("m"):
            return 110
        default:
            return 170
        }
    }
}

