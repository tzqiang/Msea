//
//  CreditContentView.swift
//  Msea
//
//  Created by tzqiang on 2022/1/25.
//  Copyright © 2022 eternal.just. All rights reserved.
//

import SwiftUI

struct CreditContentView: View {
    @State private var selectedItem = CreditItem.mycredit
    @State private var selectedIndex = 0

    var body: some View {
        VStack {
            TabView(selection: $selectedIndex) {
                ForEach(CreditItem.allCases) { item in
                    getContentView(item)
                        .tag(item.index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    SegmentedControlView(selectedIndex: $selectedIndex, titles: CreditItem.allCases.map { $0.title })
                        .frame(width: 180)
                }
            })
        }
        .navigationTitle("积分")
        .ignoresSafeArea(edges: .bottom)
        .onAppear(perform: {
            if !UIDevice.current.isPad {
                TabBarTool.showTabBar(false)
            }
        })
    }

    @ViewBuilder private func getContentView(_ item: CreditItem) -> some View {
        switch item {
        case .mycredit:
            MyCreditContentView()
        case .usergroup:
            UserGroupContentView()
        }
    }
}

struct CreditContentView_Previews: PreviewProvider {
    static var previews: some View {
        CreditContentView()
    }
}

enum CreditItem: String, CaseIterable, Identifiable {
    case mycredit
    case usergroup

    var id: String { self.rawValue }
    var title: String {
        switch self {
        case .mycredit: return "我的积分"
        case .usergroup: return "用户组"
        }
    }
    var index: Int {
        switch self {
        case .mycredit: return 0
        case .usergroup: return 1
        }
    }
}
