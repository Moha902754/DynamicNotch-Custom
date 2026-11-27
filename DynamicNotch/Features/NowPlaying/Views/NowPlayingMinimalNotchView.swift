//
//  NowPlayingMinimalNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct NowPlayingMinimalNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isNotchlessScreen) var isNotchlessScreen
    
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var settings: MediaAndFilesSettingsStore
    
    private var resolvedSnapshot: NowPlayingSnapshot {
        nowPlayingViewModel.snapshot ?? NowPlayingSnapshot(
            title: "Nothing Playing",
            artist: "Nothing artists",
            album: "",
            duration: 0,
            elapsedTime: 0,
            playbackRate: 0,
            artworkData: nil,
            refreshedAt: .now
        )
    }
    
    var body: some View {
        let snapshot = resolvedSnapshot
        HStack {
            ArtworkView(
                nowPlayingViewModel: nowPlayingViewModel,
                width: isNotchlessScreen ? 14 : 22,
                height: isNotchlessScreen ? 14 : 22,
                cornerRadius: isNotchlessScreen ? 7 : 5,
                usesFlipAnimation: true
            )
            
            Spacer()
            
            LightweightNowPlayingEqualizerView(
                isPlaying: snapshot.isPlaying,
                colors: [
                    nowPlayingViewModel.artworkPalette.equalizerHighlightColor,
                    nowPlayingViewModel.artworkPalette.equalizerBaseColor
                ],
                barHeight: isNotchlessScreen ? 12 : 18,
                barWidth: isNotchlessScreen ? 1.8 : 2.1
            )
            .frame(width: isNotchlessScreen ? 15 : 18, height: isNotchlessScreen ? 12 : 18)
        }
        .padding(.leading, isNotchlessScreen ? 3.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 8.scaled(by: scale) : 16.scaled(by: scale))
    }
}
