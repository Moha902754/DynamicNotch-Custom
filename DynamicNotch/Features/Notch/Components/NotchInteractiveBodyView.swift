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
