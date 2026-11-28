internal import EventKit
import SwiftUI
internal import AppKit

struct NotchInteractiveBodyView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        NotchSurfaceContainerView(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel
        )
        .opacity(isVisiblyHiddenInFullscreen ? 0 : 1)
        .frame(
            width: notchViewModel.presentedNotchSize.width,
            height: notchViewModel.presentedNotchSize.height
        )
        .customNotchPressable(
            notchViewModel: notchViewModel,
            isPressed: $notchViewModel.isPressed,
            baseSize: notchViewModel.presentedNotchSize
        )
        .customNotchMouseSwipeable(
            notchViewModel: notchViewModel,
            isEnabled: shouldEnableNotchSwipeGestures
        )
        .customNotchSwipeDismissable(
            notchViewModel: notchViewModel,
            isEnabled: shouldEnableNotchSwipeGestures
        )
        .offset(y: notchViewModel.isDynamicIsland ? 6.5 : 1)
        .overlay(alignment: .topTrailing) {
            NotchDotView(notchViewModel: notchViewModel)
        }
        .contextMenu {
            NotchContextMenu(settingsViewModel: settingsViewModel)
        }
        .environment(\.colorScheme, .dark)
        .animation(notchViewModel.animations.strokeVisibility, value: notchViewModel.shouldRenderStroke)
        .animation(notchViewModel.animations.strokeVisibility, value: settingsViewModel.isShowNotchStrokeEnabled)
    }
    
    private var isVisiblyHiddenInFullscreen: Bool {
        guard notchViewModel.isDynamicIsland else { return false }
        guard settingsViewModel.application.isDynamicIslandHiddenInFullscreenEnabled else { return false }
        guard let screen = NSScreen.preferredNotchScreen(for: settingsViewModel) ?? NSScreen.main else { return false }
        return SkyLightOperator.shared.isFullscreenSpaceActive(on: screen) && !notchViewModel.hasDisplayedContent
    }
    
    private var shouldEnableNotchSwipeGestures: Bool {
        !(
            notchViewModel.isDisplayingExpandedLiveActivity &&
            notchViewModel.displayedContent?.id == NotchContentRegistry.DragAndDrop.trayActive.id
        )
    }
}

/// Small round bubble beside the pill that shows a background activity.
struct NotchDotView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    private static let gap: CGFloat = 8

    private var activeDotContent: NotchContentProtocol? {
        guard !notchViewModel.isDisplayingExpandedLiveActivity else { return nil }
        return notchViewModel.dotContent
    }

    var body: some View {
        let size = notchViewModel.notchModel.baseHeight
        ZStack {
            if let content = activeDotContent {
                dotBubble(for: content, size: size)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.68, blendDuration: 0.2), value: activeDotContent?.id)
        .offset(x: size + Self.gap, y: notchViewModel.isDynamicIsland ? 6.5 : 1)
    }

    @MainActor
    @ViewBuilder
    private func dotBubble(for content: NotchContentProtocol, size: CGFloat) -> some View {
        content.dotView()
            .frame(width: size, height: size)
            .background(Circle().fill(Color.black))
            .overlay {
                if notchViewModel.shouldRenderStroke {
                    Circle().stroke(content.strokeColor.opacity(0.6), lineWidth: 1.5)
                }
            }
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                if let link = content.windowLink {
                    link()
                }
            }
            .onLongPressGesture(minimumDuration: 0.35) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    notchViewModel.setPreferredLiveActivity(id: content.id)
                    notchViewModel.expandActiveLiveActivity()
                }
            }
            .id(content.id)
            .transition(.scale(scale: 0.15, anchor: .leading).combined(with: .opacity))
    }
}

struct DownloadDotIndicatorView: View {
    @ObservedObject var downloadViewModel: DownloadViewModel
    var body: some View {
        DownloadProgressIndicatorView(
            progress: downloadViewModel.primaryDownload?.progress ?? 0.08,
            indicatorStyle: .circle, barWidth: 34, barHeight: 4, circleSize: 16, circleLineWidth: 2.6, percentFontSize: 14
        )
    }
}

struct DownloadDotRingView: View {
    @ObservedObject var downloadViewModel: DownloadViewModel
    var notchViewModel: NotchViewModel? = nil
    @State private var showThumbnail = false
    @State private var isHovered = false
    @State private var pulseScale: CGFloat = 1.0

    private let ringSize: CGFloat = 17
    private let lineWidth: CGFloat = 2.6

    private var isFinished: Bool { downloadViewModel.isShowingCompletion && !downloadViewModel.didFailRecently }
    private var isFailed: Bool { downloadViewModel.isShowingCompletion && downloadViewModel.didFailRecently }
    private var progress: Double { downloadViewModel.combinedProgress }
    // Only show spinner if we ACTUALLY have active downloads, otherwise hide the ring completely
    private var isIndeterminate: Bool {
        !downloadViewModel.isShowingCompletion && 
        downloadViewModel.hasActiveDownloads && 
        progress < 0.01
    }

    private var isStalled: Bool {
        guard !downloadViewModel.isShowingCompletion, let primary = downloadViewModel.primaryDownload else { return false }
        return primary.bytesPerSecond == 0 && Date().timeIntervalSince(primary.lastUpdatedAt) > 4.0
    }

    private var ringColor: Color {
        if isFailed { return .red }
        if isFinished { return .green }
        if isStalled { return .orange }
        return Color.accentColor
    }

    private var displayPercent: String {
        if isFinished { return "100" }
        return "\(Int(progress * 100))"
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            ZStack {
                if isFinished, showThumbnail, let url = downloadViewModel.lastCompletedURL {
                    DownloadFileThumbnailView(url: url, size: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                } else if isHovered {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                        Text("\(displayPercent)%")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .overlay(Capsule().stroke(ringColor.opacity(0.6), lineWidth: 1))
                    // Increased width to 54 to fit "100%"
                    .frame(width: 54, height: 22)
                    .offset(x: 6)
                } else {
                    ringContent
                }

                // (Badge removed for cleaner UI)
            }
            .frame(width: isHovered ? 64 : ringSize + 4, height: isHovered ? 24 : ringSize + 4)
            .scaleEffect(pulseScale)
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            if downloadViewModel.isPersistent {
                // Instantly clear state and signal the notch to hide the dot
                downloadViewModel.dismissPersistentDot()
                if let notchVM = notchViewModel {
                    notchVM.send(.hideLiveActivity(id: NotchContentRegistry.Media.download.id))
                }
            }
        }
        .onChange(of: isFinished) { _, finished in
            if finished {
                showThumbnail = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                    if downloadViewModel.isShowingCompletion && !downloadViewModel.didFailRecently {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { showThumbnail = true }
                    }
                }
            } else {
                showThumbnail = false
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isFinished)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isFailed)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isHovered)
        .onChange(of: isStalled) { _, stalled in
            if stalled {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.15
                }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    pulseScale = 1.0
                }
            }
        }
    }

    @ViewBuilder
    private var ringContent: some View {
        ZStack {
            Circle().stroke(ringColor.opacity(0.24), lineWidth: lineWidth)
            if isIndeterminate {
                DownloadSpinningArc(lineWidth: lineWidth)
            } else {
                Circle()
                    .trim(from: 0, to: (isFinished || isFailed) ? 1 : CGFloat(min(max(progress, 0.03), 1)))
                    .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }

            if isFailed {
                Image(systemName: "exclamationmark").font(.system(size: 8.5, weight: .heavy)).foregroundStyle(Color.red)
            } else if isFinished {
                Image(systemName: "checkmark").font(.system(size: 8, weight: .heavy)).foregroundStyle(Color.green)
            } else {
                Image(systemName: "arrow.down").font(.system(size: 7.5, weight: .bold)).foregroundStyle(ringColor)
            }
        }
        .frame(width: ringSize, height: ringSize)
    }
}

private struct DownloadSpinningArc: View {
    let lineWidth: CGFloat
    @State private var spin = false
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.28)
            .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(spin ? 360 : 0))
            .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: spin)
            .onAppear { spin = true }
    }
}

struct ScreenRecordingDotView: View {
    @ObservedObject var viewModel: ScreenRecordingViewModel
    @State private var pulse = false
    var body: some View {
        ZStack {
            Circle().fill(Color.red.opacity(0.3)).frame(width: 15, height: 15).scaleEffect(pulse ? 1.25 : 0.85)
            Circle().fill(Color.red).frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

struct BluetoothDotView: View {
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    var body: some View {
        ZStack {
            BluetoothBatteryIndicatorView(batteryLevel: bluetoothViewModel.batteryLevel, circleSize: 17, circleLineWidth: 2.2, usesTintedTrackStroke: true)
            Image(systemName: bluetoothViewModel.deviceType.sfSymbol).font(.system(size: 7.5, weight: .semibold)).foregroundStyle(.white)
        }
    }
}

struct CalendarDotView: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    private var progress: CGFloat {
        guard let event = calendarViewModel.nextEvent else { return 0.5 }
        let remaining = max(0, event.startDate.timeIntervalSinceNow)
        return CGFloat(min(max(1.0 - (remaining / 900.0), 0.08), 1.0))
    }
    var body: some View {
        ZStack {
            Circle().stroke(Color.red.opacity(0.28), lineWidth: 2.2)
            Circle().trim(from: 0, to: progress).stroke(Color.red, style: StrokeStyle(lineWidth: 2.2, lineCap: .round)).rotationEffect(.degrees(-90))
            Image(systemName: "calendar").font(.system(size: 7.5, weight: .bold)).foregroundStyle(.white)
        }
        .frame(width: 17, height: 17)
    }
}
