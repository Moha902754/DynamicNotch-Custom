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

/// Small round bubble beside the pill that shows a background activity (download ring, timer icon).
struct NotchDotView: View {
    @ObservedObject var notchViewModel: NotchViewModel

    private static let gap: CGFloat = 8

    var body: some View {
        let size = notchViewModel.notchModel.baseHeight

        ZStack {
            if let content = notchViewModel.dotContent {
                dotBubble(for: content, size: size)
            }
        }
        .animation(
            .spring(response: 0.45, dampingFraction: 0.62, blendDuration: 0.2),
            value: notchViewModel.dotContent?.id
        )
        .offset(
            x: size + Self.gap,
            y: notchViewModel.isDynamicIsland ? 6.5 : 1
        )
        .allowsHitTesting(false)
    }

    @MainActor
    @ViewBuilder
    private func dotBubble(for content: NotchContentProtocol, size: CGFloat) -> some View {
        content.dotView()
            .frame(width: size, height: size)
            .background(Circle().fill(Color.black))
            .clipShape(Circle())
            .id(content.id)
            .transition(
                .scale(scale: 0.15, anchor: .leading)
                    .combined(with: .opacity)
            )
    }
}

struct DownloadDotIndicatorView: View {
    @ObservedObject var downloadViewModel: DownloadViewModel

    var body: some View {
        DownloadProgressIndicatorView(
            progress: downloadViewModel.primaryDownload?.progress ?? 0.08,
            indicatorStyle: .circle,
            barWidth: 34,
            barHeight: 4,
            circleSize: 16,
            circleLineWidth: 2.6,
            percentFontSize: 14
        )
    }
}

/// Download dot: white progress ring with a down arrow, a spinner while progress is unknown,
/// and a green ring with a checkmark when the download finishes.
struct DownloadDotRingView: View {
    @ObservedObject var downloadViewModel: DownloadViewModel

    private let ringSize: CGFloat = 17
    private let lineWidth: CGFloat = 2.6

    private var isFinished: Bool { downloadViewModel.isShowingCompletion }
    private var progress: Double { downloadViewModel.combinedProgress }
    private var isIndeterminate: Bool { !isFinished && progress < 0.01 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.22), lineWidth: lineWidth)

            if isIndeterminate {
                DownloadSpinningArc(lineWidth: lineWidth)
            } else {
                Circle()
                    .trim(from: 0, to: isFinished ? 1 : CGFloat(min(max(progress, 0.03), 1)))
                    .stroke(
                        isFinished ? Color.green : Color.white,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }

            if isFinished {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(Color.green)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            } else {
                Image(systemName: "arrow.down")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundStyle(Color.white)
                    .transition(.opacity)
            }
        }
        .frame(width: ringSize, height: ringSize)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isFinished)
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
