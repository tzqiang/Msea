//
//  TreadRankContentView.swift
//  Msea
//
//  Created by Awro on 2022/2/19.
//  Copyright © 2022 eternal.just. All rights reserved.
//

import SwiftUI
import Kanna

/// 帖子排行榜
struct TreadRankContentView: View {
    @State private var selectedTab = TreadRankTab.replies
    @State private var orderbyTab = TreadRankOrderbyTab.thisweek

    @State private var treadList = [TreadRankListModel]()
    @State private var headerTitle = ""

    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(treadList) { tread in
                        ZStack(alignment: .leading) {
                            VStack(alignment: .leading) {
                                HStack {
                                    HStack {
                                        Image(systemName: "\(tread.num).circle.fill")
                                            .resizable()
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, tread.numTop ? .red : Color.theme)
                                            .frame(width: 20, height: 20)

                                        VStack(alignment: .leading) {
                                            Text(tread.name)
                                                .font(.font15)

                                            Text(tread.time)
                                                .font(.font12)
                                        }
                                    }
                                    .frame(width: UIDevice.current.isPad ? 250 : 130, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)

                                    Spacer()

                                    Text(tread.plate)
                                        .font(.font15)
                                        .frame(width: UIDevice.current.isPad ? 140 : 70)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Spacer()

                                    Text(tread.count)
                                        .foregroundColor(.secondaryTheme)
                                        .frame(width: UIDevice.current.isPad ? 250 : 130, alignment: .trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Text(tread.title)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding([.top, .bottom], 5)

                            NavigationLink(destination: TopicDetailContentView(tid: tread.tid)) {
                                EmptyView()
                            }
                            .opacity(0.0)
                        }
                    }
                } header: {
                    HStack {
                        Text("作者")

                        Spacer()

                        Text("板块")

                        Spacer()

                        Text(selectedTab.title)
                    }
                } footer: {
                    HStack {
                        Text(headerTitle)
                            .font(.font15)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("\(selectedTab.title)排行 • \(orderbyTab.title)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(TreadRankTab.allCases) { tab in
                        Menu(tab.title + "排行 ") {
                            ForEach(TreadRankOrderbyTab.allCases) { item in
                                Button {
                                    selectedTab = tab
                                    orderbyTab = item

                                    Task {
                                        await loadData()
                                    }
                                } label: {
                                    Text(item.title)
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .task {
            if treadList.isEmpty {
                await loadData()
            }
        }
    }

    private func loadData() async {
        Task {
            // swiftlint:disable force_unwrapping
            let url = URL(string: "https://www.chongbuluo.com/misc.php?mod=ranklist&type=thread&view=\(selectedTab.id)&orderby=\(orderbyTab.id)")!
            // swiftlint:enble force_unwrapping
            var requset = URLRequest(url: url)
            requset.configHeaderFields()
            let (data, _) = try await URLSession.shared.data(for: requset)
            if let html = try? HTML(html: data, encoding: .utf8) {
                let tr = html.xpath("//div[@class='tl']/table/tr")
                var list = [TreadRankListModel]()
                tr.forEach { element in
                    var model = TreadRankListModel()
                    if let num = element.at_xpath("/td[@class='icn']")?.text {
                        model.num = num
                    }
                    if let num = element.at_xpath("/td[@class='icn']/img/@alt")?.text {
                        model.num = num
                        model.numTop = true
                    }
                    if let title = element.at_xpath("/th/a")?.text {
                        model.title = title
                    }
                    if let plate = element.at_xpath("/td[@class='frm']/a")?.text {
                        model.plate = plate
                    }
                    if let name = element.at_xpath("/td[@class='by']/cite/a")?.text {
                        model.name = name
                    }
                    if let time = element.at_xpath("/td[@class='by']/em")?.text {
                        model.time = time
                    }
                    if let count = element.at_xpath("/td/a[@class='xi2']")?.text {
                        model.count = count
                    }
                    if let uid = element.at_xpath("/td[@class='by']/cite/a/@href")?.text {
                        if uid.contains("space-uid-") {
                            model.uid = uid.components(separatedBy: "space-uid-")[1].components(separatedBy: ".")[0]
                        } else if uid.contains("uid=") {
                            model.uid = uid.components(separatedBy: "uid=")[1]
                        }
                    }
                    if let tid = element.at_xpath("/th/a/@href")?.text {
                        if tid.contains("thread-") {
                            model.tid = tid.components(separatedBy: "-")[1]
                        } else if tid.contains("tid=") {
                            model.tid = tid.components(separatedBy: "tid=")[1]
                        }
                    }
                    list.append(model)
                }

                if let notice = html.at_xpath("//div[@class='notice']")?.text {
                    headerTitle = notice
                }
                treadList = list
            }
        }
    }
}

struct TreadRankContentView_Previews: PreviewProvider {
    static var previews: some View {
        TreadRankContentView()
    }
}

enum TreadRankTab: String, CaseIterable, Identifiable {
    case replies
    case views
    case favtimes
    case heats

    var id: String { self.rawValue }
    var title: String {
        switch self {
        case .replies: return "回复"
        case .views: return "查看"
        case .favtimes: return "收藏"
        case .heats: return "热度"
        }
    }
}

enum TreadRankOrderbyTab: String, CaseIterable, Identifiable {
    case thisweek
    case thismonth
    case today
    case all

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .thisweek: return "本周"
        case .thismonth: return "本月"
        case .today: return "今日"
        case .all: return "全部"
        }
    }
}

struct TreadRankListModel: Identifiable {
    var id = UUID()
    var tid = ""
    var uid = ""
    var num = ""
    var numTop = false
    var name = ""
    var time = ""
    var plate = ""
    var count = ""
    var title = ""
}
