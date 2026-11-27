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
            let wasShownAsDot = notchViewModel.dotContent?.id == downloadID
            let looksFinished = downloadViewModel.lastCombinedProgress >= 0.5

            guard wasShownAsDot, looksFinished else {
                notchViewModel.send(.hideLiveActivity(id: downloadID))
                return
            }

            downloadViewModel.beginCompletionHold()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
                guard let self else { return }
                if !self.downloadViewModel.hasActiveDownloads {
                    self.notchViewModel.send(.hideLiveActivity(id: downloadID))
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.downloadViewModel.endCompletionHold()
                }
            }
        }
    }
}

