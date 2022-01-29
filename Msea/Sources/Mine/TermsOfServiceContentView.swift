//
//  TermsOfServiceContentView.swift
//  Msea
//
//  Created by Awro on 2022/1/29.
//  Copyright © 2022 eternal.just. All rights reserved.
//

import SwiftUI

struct TermsOfServiceContentView: View {
    var body: some View {
        VStack {
            TermsOfServiceTextView()
        }
        .navigationTitle("使用条款")
    }
}

struct TermsOfServiceContentView_Previews: PreviewProvider {
    static var previews: some View {
        TermsOfServiceContentView()
    }
}

struct TermsOfServiceTextView: View {
    private var text = """
                       虫部落提醒您：在使用虫部落前，请您务必仔细阅读并透彻理解本声明。您可以选择不使用虫部落，但如果您使用虫部落，您的使用行为将被视为对本声明全部内容的认可。

                       本站搜索聚合工具（快搜、学术搜索、搜书等）所收录等第三方搜索引擎的搜索算法、数据和搜索结果均属其个人或组织行为，不代表本站立场。

                       鉴于本站搜索聚合工具未使用自建索引/数据存储/分析模式，无法确定您输入的条件进行是否合法，也无法实时监控第三方网站的搜索结果的合法性，所以本站对搜索聚合工具页面检索/分析出的结果不承担责任。如果因以本站的检索/分析结果作为任何商业行为或者学术研究的依据而产生不良后果，虫部落不承担任何法律责任。

                       任何通过使用本站搜索聚合工具中的第三方搜索引擎而搜索链接到的其它第三方网页均系他人制作或提供，您可能从该第三方网页上获得资讯及享用服务，虫部落对其合法性概不负责，亦不承担任何法律责任。

                       虫部落注册用户在社区发布的任何软件、插件和脚本等程序，仅用于测试和学习研究，禁止用于商业用途，不能保证其合法性，准确性，完整性和有效性，请根据情况自行判断，虫部落不承担任何法律责任。

                       虫部落所有资源文件，禁止任何公众号、自媒体进行任何形式的转载、发布。

                       虫部落对任何个人发布的软件、插件和脚本等程序问题概不负责，包括但不限于由任软件、插件和脚本等程序错误导致的任何损失或损害。

                       请勿将虫部落的任何内容用于商业或非法目的，否则后果自负。如果任何单位或个人认为虫部落的相关内容可能涉嫌侵犯其权利，则应及时通知管理员并提供身份证明，所有权证明，管理员将在收到认证文件后删除相关脚本。

                       再次重申：您访问、浏览、使用或者复制了虫部落的任何内容，则视为已接受此声明，请仔细阅读!
                       """

    var body: some View {
        ScrollView {
            Text(text)
                .padding()
        }
    }
}
