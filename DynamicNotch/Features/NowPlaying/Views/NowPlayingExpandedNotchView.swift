import SwiftUI
internal import AppKit

struct NowPlayingExpandedNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isNotchlessScreen) var isNotchlessScreen
    @Environment(\.locale) private var locale
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var settings: MediaAndFilesSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    let onOpenPlaybackSource: @MainActor () -> Void
    @State private var scrubProgress: CGFloat?
    private let detailedPresentationSource = "nowPlaying.notch.expanded"

    private var resolvedSnapshot: NowPlayingSnapshot {
        nowPlayingViewModel.snapshot ?? NowPlayingSnapshot(
            title: locale.dn("notch.nowPlaying.nothingPlaying", fallback: "Nothing Playing"),
            artist: locale.dn("notch.nowPlaying.startPlayback", fallback: "Start playback to see live metadata"),
            album: "Nothing Playing", duration: 0, elapsedTime: 0, playbackRate: 0, artworkData: nil, refreshedAt: .now
        )
    }

    var body: some View {
        let snapshot = resolvedSnapshot
        return TimelineView(.periodic(from: .now, by: snapshot.isPlaying ? 0.25 : 30.0)) { context in
            timelineContent(snapshot: snapshot, at: context.date)
        }
        .onAppear { nowPlayingViewModel.setDetailedPresentationActive(true, source: detailedPresentationSource) }
        .onDisappear { nowPlayingViewModel.setDetailedPresentationActive(false, source: detailedPresentationSource) }
    }

    private func timelineContent(snapshot: NowPlayingSnapshot, at date: Date) -> some View {
        let elapsedTime = nowPlayingViewModel.snapshot != nil ? nowPlayingViewModel.elapsedTime(at: date) : snapshot.elapsedTime
        let progress = snapshot.duration > 0 ? min(max(CGFloat(elapsedTime / snapshot.duration), 0), 1) : 0
        let displayedProgress = min(max(scrubProgress ?? progress, 0), 1)
        let displayedElapsedTime = snapshot.duration > 0 ? TimeInterval(displayedProgress) * snapshot.duration : elapsedTime
        let appearance = settings.nowPlayingAppearanceOptions
        let artSize: CGFloat = isNotchlessScreen ? 80 : 84

        return HStack(alignment: .center, spacing: 14) {
            Button(action: { openPlaybackSource() }) {
                ZStack(alignment: .bottomTrailing) {
                    ArtworkView(nowPlayingViewModel: nowPlayingViewModel, width: artSize, height: artSize, cornerRadius: 8, usesFlipAnimation: true)
                        .overlay { RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1) }
                    if let bundleID = snapshot.playbackSource?.preferredBundleIdentifier,
                       let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                            .resizable().frame(width: 18, height: 18)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                            .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                            .offset(x: 3, y: 3)
                    }
                }.contentShape(Rectangle())
            }.buttonStyle(PlaybackSourceButtonStyle()).disabled(!nowPlayingViewModel.canOpenPlaybackSource)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top, spacing: 8) {
                    Button(action: { openPlaybackSource() }) {
                        VStack(alignment: .leading, spacing: 2) {
                            MarqueeText(.constant(snapshot.title.trimmed.isEmpty ? locale.dn("notch.nowPlaying.unknownTrack", fallback: "Unknown Track") : snapshot.title),
                                font: .system(size: 14.5, weight: .semibold), nsFont: .headline, textColor: .white, backgroundColor: .clear, minDuration: 2.0, frameWidth: 185)
                            MarqueeText(.constant(snapshot.artist.trimmed.isEmpty ? locale.dn("notch.nowPlaying.unknownArtist", fallback: "Unknown Artist") : snapshot.artist),
                                font: .system(size: 12, weight: .regular), nsFont: .subheadline, textColor: .white.opacity(0.55), backgroundColor: .clear, minDuration: 3.0, frameWidth: 185)
                        }.contentShape(Rectangle())
                    }.buttonStyle(PlaybackSourceButtonStyle()).disabled(!nowPlayingViewModel.canOpenPlaybackSource)
                    Spacer(minLength: 4)
                    LightweightNowPlayingEqualizerView(isPlaying: snapshot.isPlaying, colors: [nowPlayingViewModel.artworkPalette.equalizerHighlightColor, nowPlayingViewModel.artworkPalette.equalizerBaseColor], barHeight: 16, barWidth: 2.3)
                        .frame(width: 22, height: 16)
                }

                PlayerProgressBar(progress: displayedProgress, displayedElapsedTime: displayedElapsedTime, duration: snapshot.duration, isInteractive: snapshot.duration > 0,
                    onScrubChanged: { scrubProgress = $0 },
                    onScrubEnded: { nowPlayingViewModel.seek(to: snapshot.duration * TimeInterval($0)); scrubProgress = nil })

                HStack(spacing: 0) {
                    if appearance.showsFavoriteButton { FavoriteTrackButton(nowPlayingViewModel: nowPlayingViewModel, width: 28, height: 28, fontSize: 14) }
                    Spacer(minLength: 6)
                    HStack(spacing: 20) {
                        PlayerControlButton(systemImage: "backward.fill", fontSize: 16, width: 30, height: 30, feedbackStyle: .backward) { nowPlayingViewModel.previousTrack() }
                        PlayerControlButton(systemImage: snapshot.isPlaying ? "pause.fill" : "play.fill", fontSize: 21, width: 32, height: 32, feedbackStyle: .playPause) { nowPlayingViewModel.togglePlayPause() }
                        PlayerControlButton(systemImage: "forward.fill", fontSize: 16, width: 30, height: 30, feedbackStyle: .forward) { nowPlayingViewModel.nextTrack() }
                    }
                    Spacer(minLength: 6)
                    if appearance.showsOutputDeviceButton { AudioOutputRoutePickerButton(nowPlayingViewModel: nowPlayingViewModel, width: 28, height: 28, fontSize: 14) }
                }.padding(.top, 1)
            }.frame(maxWidth: .infinity)
        }
        .padding(.top, isNotchlessScreen ? 14 : 26).padding(.bottom, 14)
        .padding(.leading, isNotchlessScreen ? 16 : 36).padding(.trailing, isNotchlessScreen ? 18 : 38)
    }

    private func openPlaybackSource() {
        guard nowPlayingViewModel.canOpenPlaybackSource else { return }
        nowPlayingViewModel.openPlaybackSource()
        if !applicationSettings.isCloseAtFocusLiveActivityEnabled { onOpenPlaybackSource() }
    }
}
