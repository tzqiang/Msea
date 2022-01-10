//
//  SettingContentView.swift
//  Msea
//
//  Created by tzqiang on 2021/12/20.
//  Copyright © 2021 eternal.just. All rights reserved.
//

import SwiftUI
import Kanna

/// 设置相关
struct SettingContentView: View {
    @EnvironmentObject private var hud: HUDState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL

    @State private var isOn = false
    @State private var selectedDate = Date.now
    @State private var showAlert = false

    @State private var itemSections: [SettingSection] = [
        SettingSection(items: [.signalert]),
        SettingSection(items: [.review, .feedback, .share]),
        SettingSection(items: [.urlschemes, .about])
    ]

    var body: some View {
        VStack {
            List {
                ForEach(itemSections) { section in
                    Section {
                        ForEach(section.items) { item in
                            HStack {
                                if item != .logout {
                                    Image(systemName: item.icon)

                                    Text(item.title)

                                    Spacer()

                                    if item == .signalert {
                                        DatePicker("", selection: $selectedDate, displayedComponents: [.hourAndMinute])
                                            .onChange(of: selectedDate) { value in
                                                let components = Calendar.current.dateComponents([.hour, .minute], from: value)
                                                if let hour = components.hour, let minute = components.minute {
                                                    CacheInfo.shared.daysignHour = hour
                                                    CacheInfo.shared.daysignMinute = minute
                                                }
                                                if isOn {
                                                    Task {
                                                        _ = await LocalNotification.shared.daysign()
                                                    }
                                                }
                                            }

                                        Toggle("", isOn: $isOn)
                                            .alert("通知权限已关闭", isPresented: $showAlert) {
                                                Button("取消", role: .cancel) {
                                                }

                                                Button("去设置") {
                                                    // swiftlint:disable force_unwrapping
                                                    openURL(URL(string: UIApplication.openSettingsURLString)!)
                                                    // swiftlint:enble force_unwrapping
                                                }
                                            } message: {
                                                Text("可在设置中重新开启签到提醒")
                                                    .font(.callout)
                                            }
                                            .onChange(of: isOn) { value in
                                                Task {
                                                    print(value)
                                                    if await LocalNotification.shared.isAuthorizationDenied() {
                                                        if !isOn && !value {
                                                            showAlert.toggle()
                                                        }
                                                        isOn = false
                                                    } else {
                                                        CacheInfo.shared.daysignIsOn = value
                                                        if value {
                                                            if await !LocalNotification.shared.daysign() {
                                                                isOn = false
                                                            }
                                                        } else {
                                                            LocalNotification.shared.removeDaysign()
                                                        }
                                                    }
                                                }
                                            }
                                    } else {
                                        Image(systemName: "chevron.right")
                                    }
                                } else {
                                    Text(item.title)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Task {
                                    if item == .logout {
                                        await logout()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                let now = Date.now
                var components = Calendar.current.dateComponents([.hour, .minute], from: now)
                components.hour = CacheInfo.shared.daysignHour
                components.minute = CacheInfo.shared.daysignMinute
                let date = Calendar.current.date(from: components)
                selectedDate = date ?? now
                isOn = await LocalNotification.shared.isAuthorizationDenied() ? false : CacheInfo.shared.daysignIsOn
                if UserInfo.shared.isLogin() {
                    itemSections.append(SettingSection(items: [.logout]))
                }
            }
            TabBarTool.showTabBar(false)
        }
    }

    private func logout() async {
        Task {
            // swiftlint:disable force_unwrapping
            let url = URL(string: "\(kAppBaseURL)member.php?mod=logging&action=logout&formhash=\(UserInfo.shared.formhash)")!
            // swiftlint:enble force_unwrapping
            var request = URLRequest(url: url)
            request.configHeaderFields()
            let (data, _) = try await URLSession.shared.data(for: request)
            if let html = try? HTML(html: data, encoding: .utf8) {
                if let text = html.toHTML, text.contains("退出") {
                    UserInfo.shared.reset()
                    NotificationCenter.default.post(name: .logout, object: nil)
                    hud.show(message: "您已退出登录！")
                    dismiss()
                } else {
                    hud.show(message: "退出异常，请稍后重试！")
                }
            } else {
                hud.show(message: "退出异常，请稍后重试！")
            }
        }
    }
}

struct SettingContentView_Previews: PreviewProvider {
    static var previews: some View {
        SettingContentView()
    }
}

struct SettingSection: Identifiable {
    var id = UUID()
    var items: [SettingItem]
}

enum SettingItem: String, CaseIterable, Identifiable {
    case signalert
    case review
    case share
    case feedback
    case urlschemes
    case about
    case logout

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .signalert:
            return "clock.fill"
        case .review:
            return "star.fill"
        case .share:
            return "arrowshape.turn.up.right.fill"
        case .feedback:
            return "text.bubble.fill"
        case .urlschemes:
            return "personalhotspot.circle.fill"
        case .about:
            return "exclamationmark.circle.fill"
        case .logout:
            return ""
        }
    }

    var title: String {
        switch self {
        case .signalert:
            return "签到提醒"
        case .review:
            return "评价应用"
        case .share:
            return "分享给朋友"
        case .feedback:
            return "反馈问题"
        case .urlschemes:
            return "URL Schemes"
        case .about:
            return "关于 Msea"
        case .logout:
            return "退出登录"
        }
    }
}
