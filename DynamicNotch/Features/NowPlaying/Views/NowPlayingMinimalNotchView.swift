//
//  NowPlayingMinimalNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct NowPlayingMinimalNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isNotchless) var isNotchless
    
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
                width: isNotchless ? 14 : 22,
                height: isNotchless ? 14 : 22,
                cornerRadius: isNotchless ? 7 : 5,
                usesFlipAnimation: true
            )
            
            Spacer()
            
            LightweightNowPlayingEqualizerView(
                isPlaying: snapshot.isPlaying,
                colors: [
                    nowPlayingViewModel.artworkPalette.equalizerHighlightColor,
                    nowPlayingViewModel.artworkPalette.equalizerBaseColor
                ],
                barHeight: isNotchless ? 12 : 18,
                barWidth: isNotchless ? 1.8 : 2.1
            )
            .frame(width: isNotchless ? 15 : 18, height: isNotchless ? 12 : 18)
        }
        .padding(.leading, isNotchless ? 3.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isNotchless ? 8.scaled(by: scale) : 16.scaled(by: scale))
    }
}
