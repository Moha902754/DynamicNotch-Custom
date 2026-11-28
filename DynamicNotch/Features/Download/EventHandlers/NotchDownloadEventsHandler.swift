//
//  NotchDownloadEventsHandler.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/14/26.
//

import SwiftUI

@MainActor
final class NotchDownloadEventsHandler {
    private let notchViewModel: NotchViewModel
    private let downloadViewModel: DownloadViewModel
    private let settingsViewModel: SettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        downloadViewModel: DownloadViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.downloadViewModel = downloadViewModel
        self.settingsViewModel = settingsViewModel
    }

    func handleDownload(_ event: DownloadEvent) {
        switch event {
        case .started:
            guard settingsViewModel.isLiveActivityEnabled(.downloads) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    DownloadNotchContent(
                        downloadViewModel: downloadViewModel,
                        settingsViewModel: settingsViewModel
                    )
                )
            )

        case .stopped:
            let downloadID = NotchContentRegistry.Media.download.id
            let wasShownAsDot = notchViewModel.dotContent?.id == downloadID || (notchViewModel.displayedContent?.id == NotchContentRegistry.Media.nowPlaying.id && downloadViewModel.lastCombinedProgress > 0)
            let looksFinished = downloadViewModel.lastCombinedProgress >= 0.5

            guard wasShownAsDot else {
                notchViewModel.send(.hideLiveActivity(id: downloadID))
                return
            }

            if looksFinished {
                // SUCCESS: show green checkmark, then make it persistent until clicked
                downloadViewModel.beginCompletionHold(failed: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
                    guard let self else { return }
                    if !self.downloadViewModel.hasActiveDownloads {
                        self.downloadViewModel.isPersistent = true
                    }
                }
            } else {
                // CANCELLED (< 50%): flash red briefly, then vanish silently
                downloadViewModel.beginCompletionHold(failed: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                    guard let self else { return }
                    self.downloadViewModel.endCompletionHold()
                    if !self.downloadViewModel.hasActiveDownloads {
                        self.notchViewModel.send(.hideLiveActivity(id: downloadID))
                    }
                }
            }
        }
    }
}

