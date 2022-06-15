//
//  SiriShortcutContentView.swift
//  Msea
//
//  Created by tzqiang on 2022/6/15.
//  Copyright © 2022 eternal.just. All rights reserved.
//

import SwiftUI
import Intents

/// Siri 捷径
struct SiriShortcutContentView: View {
    var body: some View {
        List {
            Section {
                ForEach(SiriShortcutItem.allCases) { item in
                    HStack {
                        Text(item.title)

                        Spacer()

                        SiriButton(shortcut: item.shortcut, layout: .right)
                    }
                    .frame(height: 60)
                }
            } header: {
                Text("你可以通过添加到快捷指令 App 的 Siri 捷径，或者直接呼出 Siri 说出个性化短语（“虫部落签到”、“虫部落排行榜”），即可快速打开 Msea 对应页面。")
            }
            .textCase(.none)
        }
        .navigationTitle("Siri 捷径")
        .onAppear {
            if !UIDevice.current.isPad {
                TabBarTool.showTabBar(false)
            }
        }
    }
}

struct SiriShortcutContentView_Previews: PreviewProvider {
    static var previews: some View {
        SiriShortcutContentView()
    }
}

enum SiriShortcutItem: String, CaseIterable, Identifiable {
    case daysign
    case ranklist

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .daysign:
            return "每日签到"
        case .ranklist:
            return "排行榜"
        }
    }

    var shortcut: INShortcut {
        switch self {
        case .daysign:
            let userActivity = NSUserActivity(activityType: Constants.daysignUserActivityType)
            userActivity.title = "虫部落签到"
            userActivity.suggestedInvocationPhrase = "虫部落签到"

            return INShortcut(userActivity: userActivity)
        case .ranklist:
            let userActivity = NSUserActivity(activityType: Constants.ranklistUserActivityType)
            userActivity.title = "虫部落排行榜"
            userActivity.suggestedInvocationPhrase = "虫部落排行榜"

            return INShortcut(userActivity: userActivity)
        }
    }
}
