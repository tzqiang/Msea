//
//  HomeContentView.swift
//  Msea
//
//  Created by Awro on 2021/12/5.
//  Copyright © 2021 eternal.just. All rights reserved.
//

import SwiftUI

/// 首页列表
struct HomeContentView: View {
    @State private var search = ""
    @State private var selectedViewTab = ViewTab.new
    @State private var navigationBarHidden = true
    @State private var isActive = false
    @ObservedObject private var selection = TabItemSelection()

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    NavigationLink(destination: DaySignContentView(), isActive: $isActive) {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.theme)
                            .imageScale(.large)
                            .padding(.leading, 20)
                    }

                    TextField("搜索", text: $search)
                        .textFieldStyle(.roundedBorder)

                    Spacer()
                }

                Picker("ViewTab", selection: $selectedViewTab) {
                    ForEach(ViewTab.allCases) { view in
                        Text(view.title)
                            .tag(view)
                    }
                }
                .pickerStyle(.segmented)
                .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))

                TabView(selection: $selectedViewTab) {
                    ForEach(ViewTab.allCases) { view in
                        TopicListContentView(view: view)
                            .tag(view)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .never))
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(navigationBarHidden)
            .onAppear {
                navigationBarHidden = true
            }
            .onDisappear {
                navigationBarHidden = false
            }
            .onReceive(NotificationCenter.default.publisher(for: .daysign, object: nil)) { _ in
                selection.index = .home
                isActive = true
            }
        }
    }
}

struct HomeContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeContentView()
    }
}

enum ViewTab: String, CaseIterable, Identifiable {
    case new
    case hot
    case newthread
    case sofa

    var id: String { self.rawValue }
    var title: String {
        switch self {
        case .new: return "最新回复"
        case .hot: return "热门"
        case .newthread: return "最新发表"
        case .sofa: return "前排"
        }
    }
}
