//
//  TopicDetailContentView.swift
//  Msea
//
//  Created by tzqiang on 2022/1/6.
//  Copyright © 2022 eternal.just. All rights reserved.
//

import SwiftUI
import Kanna

struct TopicDetailContentView: View {
    var tid: String = ""

    @State private var action = ""
    @State private var title = ""
    @State private var commentCount = ""
    @State private var comments = [TopicCommentModel]()
    @State private var isHidden = false
    @State private var page = 1
    @State private var isRefreshing = false
    @State private var nextPage = false
    @State private var pageSize = 1
    @State private var isSelectedPage = false
    @State private var isConfirming = false

    @State private var needLogin = false
    @EnvironmentObject private var hud: HUDState

    @State private var inputComment = ""
    @FocusState private var focused: Bool
    @State private var isPresented = false
    @State private var isShowing = false
    @State var bottomTrigger = false

    @State private var isReply = false
    @State private var replyName = ""
    @State private var replyContent = ""
    @State private var replyAction = ""
    @FocusState private var replyFocused: Bool
    @State private var showAlert = false
    @Environment(\.dismiss) private var dismiss

    @State private var disAgree = false
    @State private var isPosterShielding = false
    @State private var favoriteAction = ""

    @State private var uid = ""
    @State private var isSpace = false
    @State private var newTid = ""
    @State private var isViewthread = false
    @State private var webURLItem: WebURLItem?
    @State private var pid = ""

    var body: some View {
        ZStack {
            if disAgree || isPosterShielding {
                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        if disAgree {
                            Text("同意使用条款后才能查看帖子")
                        } else {
                            Text("楼主已经被屏蔽，帖子信息不再展示")
                        }

                        Spacer()
                    }

                    Spacer()
                }
            } else {
                VStack {
                    ScrollViewReader { proxy in
                        List {
                            Section {
                                ForEach(comments) { comment in
                                    VStack(alignment: .leading) {
                                        HStack {
                                            AsyncImage(url: URL(string: comment.avatar)) { image in
                                                image.resizable()
                                            } placeholder: {
                                                ProgressView()
                                            }
                                            .frame(width: 40, height: 40)
                                            .cornerRadius(5)
                                            .onTapGesture {
                                                if !comment.uid.isEmpty {
                                                    uid = comment.uid
                                                    isSpace.toggle()
                                                }
                                            }

                                            VStack(alignment: .leading) {
                                                Text(comment.name)
                                                    .font(.font17Blod)
                                                Text(comment.time)
                                                    .font(.font13)
                                            }
                                        }
                                        .onAppear {
                                            if comment.id == comments.last?.id {
                                                if nextPage {
                                                    page += 1
                                                    isSelectedPage = false
                                                    Task {
                                                        await loadData()
                                                    }
                                                }
                                            }
                                        }

                                        if comment.isText {
                                            Text(comment.content)
                                                .font(.font16)
                                                .multilineTextAlignment(.leading)
                                                .lineSpacing(5)
                                                .fixedSize(horizontal: false, vertical: true)
                                        } else {
                                            Web(bodyHTMLString: comment.content, didFinish: { scrollHeight in
                                                if comment.webViewHeight == .zero, let index = comments.firstIndex(where: { obj in obj.id == comment.id }) {
                                                    var model = comment
                                                    model.webViewHeight = scrollHeight
                                                    model.id = UUID()
                                                    if index < comments.count, comments.count != 1 {
                                                        comments.replaceSubrange(index..<(index + 1), with: [model])
                                                    } else {
                                                        comments = [model]
                                                    }
                                                }
                                            }, decisionHandler: { url in
                                                if let url = url {
                                                    handler(url: url)
                                                }
                                            })
                                                .frame(height: comment.webViewHeight)
                                        }
                                    }
                                    .padding([.top, .bottom], 5)
                                    .id(comment.pid)
                                    .swipeActions {
                                        if comment.id == comments.first?.id && UserInfo.shared.isLogin() && !comment.favorite.isEmpty {
                                            Button("收藏") {
                                                favoriteAction = comment.favorite
                                                Task {
                                                    await favorite()
                                                }
                                            }
                                        }
//                                        Button("回复") {
//                                            replyName = comment.name
//                                            replyAction = comment.reply
//                                            focused = false
//                                            isReply = true
//                                            replyFocused.toggle()
//                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    TopicDetailHeaderView(title: title, commentCount: commentCount)
                                        .onTapGesture {
                                            UIPasteboard.general.string = tid
                                            hud.show(message: "已复制 tid")
                                        }

                                    if pageSize > 1 {
                                        Spacer()

                                        Button {
                                            isConfirming.toggle()
                                        } label: {
                                            Image(systemName: "arrow.up.arrow.down")
                                        }
                                        .confirmationDialog("", isPresented: $isConfirming) {
                                            ForEach((1...pageSize), id: \.self) { index in
                                                Button("\(index)") {
                                                    page = index
                                                    isSelectedPage = true
                                                    Task {
                                                        await loadData()
                                                    }
                                                }
                                            }
                                        } message: {
                                            Text("分页选择")
                                        }
                                    }
                                }
                            }
                        }
                        //                    .simultaneousGesture(DragGesture().onChanged({ _ in
                        //                        focused = false
                        //                        isReply = false
                        //                        replyFocused = false
                        //                    }))
                        .listStyle(.plain)
                        .refreshable {
                            page = 1
                            isSelectedPage = false
                            await loadData()
                        }
                        .task {
                            if !isHidden {
                                page = 1
                                isSelectedPage = false
                                await loadData()
                            }
                        }
                        .onOpenURL { url in
                            if let query = url.query, query.contains("pid=") {
                                let pid = query.components(separatedBy: "=")[1]
                                if Int(pid) != nil {
                                    proxy.scrollTo(pid, anchor: .top)
                                }
                            }
                        }
                        .safeAreaInset(edge: .bottom) {
                            HStack {
                                Button {
                                    if UserInfo.shared.isLogin() {
                                        isPresented.toggle()
                                    } else {
                                        needLogin.toggle()
                                    }
                                } label: {
                                    Label(title: {
                                        Text("输入评论内容")
                                    }, icon: {
                                        Image(systemName: "rectangle.and.pencil.and.ellipsis")
                                    })
                                        .frame(maxWidth: UIScreen.main.bounds.width - 60, minHeight: 30)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(.secondary, lineWidth: 1)
                                        )
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 66)
                            .background(.regularMaterial)
                        }
                    }

//                    ZStack {

//                        VStack {
//                            Text("回复\(replyName)")
//
//                            HStack {
//                                TextEditor(text: $replyContent)
//                                    .multilineTextAlignment(.leading)
//                                    .font(.font12)
//                                    .focused($replyFocused)
//                                    .onChange(of: replyContent) { newValue in
//                                        print(newValue)
//                                    }
//                                    .border(Color.theme)
//                                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 20, trailing: 0))
//
//                                Spacer()
//
//                                Button("回复") {
//                                    if !UserInfo.shared.isLogin() {
//                                        needLogin.toggle()
//                                    } else {
//                                        Task {
//                                            await getReply()
//                                        }
//                                    }
//                                }
//                                .offset(x: 0, y: -10)
//                                .padding(.trailing, 10)
//                            }
//                        }
//                        .frame(maxWidth: UIScreen.main.bounds.width - 20)
//                        .isHidden(!isReply)
//                    }
//                    .frame(minHeight: 65)
//                    .background(Color(light: .white, dark: .black))

                    NavigationLink(destination: SpaceProfileContentView(uid: uid), isActive: $isSpace) {
                        EmptyView()
                    }
                    .opacity(0.0)

                    NavigationLink(destination: TopicDetailContentView(tid: newTid), isActive: $isViewthread) {
                        EmptyView()
                    }
                    .opacity(0.0)
                }
            }

            ProgressView()
                .isHidden(isHidden)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !CacheInfo.shared.agreeTermsOfService {
                            showAlert.toggle()
                        }
                    }
                }
        }
        .edgesIgnoringSafeArea(UIDevice.current.isPad ? [] : [.bottom])
        .navigationTitle("帖子详情")
        .onAppear {
            if !UIDevice.current.isPad {
                TabBarTool.showTabBar(false)
            }
            if let first = comments.first {
                isPosterShielding = UserInfo.shared.shieldUsers.contains { $0.uid == first.uid }
                if isPosterShielding {
                    dismiss()
                } else {
                    shieldUsers()
                }
            }
        }
        .dialog(isPresented: $isPresented, paddingTop: 100) {
            VStack {
                HStack {
                    Spacer()

                    Text("评论帖子")
                        .font(.font17)

                    Spacer()

                    Button {
                        closeDialog()
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                }

                ZStack(alignment: .leading) {
                    TextEditor(text: $inputComment)
                        .multilineTextAlignment(.leading)
                        .font(.font16)
                        .focused($focused)
                        .onChange(of: inputComment) { newValue in
                            print(newValue)
                        }
                        .border(Color.theme)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 20, trailing: 0))

                    if inputComment.isEmpty {
                        Text("输入评论内容")
                            .multilineTextAlignment(.leading)
                            .font(.font16)
                            .foregroundColor(.secondary)
                            .padding(EdgeInsets(top: -43, leading: 16, bottom: 30, trailing: 0))
                    }
                }

                Button(isShowing ? " " : "发表评论", action: {
                    Task {
                        await comment()
                    }
                })
                    .showProgress(isShowing: $isShowing, color: .white)
                    .disabled(isShowing)
                    .buttonStyle(BigButtonStyle())
                    .padding(EdgeInsets(top: 20, leading: 0, bottom: 10, trailing: 0))
            }
            .frame(width: 300, height: 200)
            .onAppear {
                focused.toggle()
            }
        }
        .sheet(isPresented: $needLogin) {
            LoginContentView()
        }
        .sheet(item: $webURLItem, content: { item in
            Safari(url: URL(string: item.url))
        })
        .alert("使用条款", isPresented: $showAlert) {
            Button("不同意", role: .cancel) {
                disAgree = true
                dismiss()
            }

            Button("同意") {
                CacheInfo.shared.agreeTermsOfService = true
                showAlert = false
            }
        } message: {
            TermsOfServiceContentView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if UserInfo.shared.isLogin() {
                        Button {
                            if let action = comments.first?.favorite,
                               UserInfo.shared.isLogin(),
                               !action.isEmpty {
                                favoriteAction = action
                                Task {
                                    await favorite()
                                }
                            }
                        } label: {
                            Label("收藏", systemImage: "star.fill")
                        }
                    }

                    Menu("举报") {
                        ForEach(ReportMenuItem.allCases) { item in
                            Button {
                                Task {
                                    await report()
                                }
                            } label: {
                                Text(item.title)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .isHidden(disAgree)
            }
        }
    }

    private func closeDialog() {
        withAnimation {
            focused = false
            isPresented.toggle()
            if !UIDevice.current.isPad {
                TabBarTool.showTabBar(false)
            }
        }
    }

    private func shieldUsers() {
        comments = comments.filter { model in
            !UserInfo.shared.shieldUsers.contains { $0.uid == model.uid }
        }
    }

    private func loadData() async {
        isRefreshing = true
        print("pageSize: \(pageSize)")
        print("page: \(page)")
        Task {
            // swiftlint:disable force_unwrapping
            let url = URL(string: "https://www.chongbuluo.com/forum.php?mod=viewthread&tid=\(tid)&extra=&page=\(page)")!
            // swiftlint:enble force_unwrapping
            var requset = URLRequest(url: url)
            requset.configHeaderFields()
            let (data, _) = try await URLSession.shared.data(for: requset)
            if let html = try? HTML(html: data, encoding: .utf8) {
                if let text = html.at_xpath("//div[@id='f_pst']/form/@action", namespaces: nil)?.text {
                    action = text
                }
                if let text = html.at_xpath("//td[@class='plc ptm pbn vwthd']/h1/span", namespaces: nil)?.text {
                    title = text
                }
                if let text1 = html.at_xpath("//td[@class='plc ptm pbn vwthd']/div[@class='ptn']/span[2]", namespaces: nil)?.text, let text2 = html.at_xpath("//td[@class='plc ptm pbn vwthd']/div[@class='ptn']/span[5]", namespaces: nil)?.text {
                    commentCount = "查看: \(text1)  |  回复: \(text2)  |  tid(\(tid))"
                }
                if let text = html.toHTML, text.contains("下一页") {
                    nextPage = true
                } else {
                    nextPage = false
                }
                if var size = html.at_xpath("//div[@class='pgs mtm mbm cl']/div[@class='pg']/a[last()-1]", namespaces: nil)?.text {
                    size = size.replacingOccurrences(of: "... ", with: "")
                    if let num = Int(size), num > 1 {
                        pageSize = num
                    }
                }
                let node = html.xpath("//table[@class='plhin']", namespaces: nil)
                var list = [TopicCommentModel]()
                node.forEach { element in
                    var comment = TopicCommentModel()
                    if let url = element.at_xpath("//div[@class='imicn']/a/@href", namespaces: nil)?.text {
                        let uid = getUid(url: url)
                        if !uid.isEmpty {
                            comment.uid = uid
                        }
                    }
                    if let avatar = element.at_xpath("//div[@class='avatar']//img/@src", namespaces: nil)?.text {
                        comment.avatar = avatar
                    }
                    if let name = element.at_xpath("//div[@class='authi']/a", namespaces: nil)?.text {
                        comment.name = name
                    }
                    if let time = element.at_xpath("//div[@class='authi']/em", namespaces: nil)?.text {
                        comment.time = time
                    }
                    let a = element.xpath("//div[@class='pob cl']//a", namespaces: nil)
                    a.forEach { ele in
                        if let text = ele.text, text.contains("回复") {
                            if let reply = ele.at_xpath("/@href", namespaces: nil)?.text {
                                comment.reply = reply
                            }
                        }
                    }
                    var table = element.at_xpath("//div[@class='t_fsz']/table", namespaces: nil)
                    if table?.toHTML == nil {
                        table = element.at_xpath("//div[@class='pcbs']/table", namespaces: nil)
                    }
                    if table?.toHTML == nil {
                        table = element.at_xpath("//div[@class='pcbs']", namespaces: nil)
                    }
                    if let content = table?.toHTML {
                        if let id = table?.at_xpath("//td/@id", namespaces: nil)?.text, id.contains("_") {
                            comment.pid = id.components(separatedBy: "_")[1]
                        }
                        comment.content = content
                        if content.contains("font") || content.contains("strong") || content.contains("color") || content.contains("quote") || content.contains("</a>") {
                            comment.isText = false
                            comment.content = content.replacingOccurrences(of: "</blockquote></div>\n<br>", with: "</blockquote></div>")
                            if content.contains("file") && content.contains("src") {
                                comment.content = comment.content.replacingOccurrences(of: "src=\"static/image/common/none.gif\"", with: "")
                                comment.content = comment.content.replacingOccurrences(of: "file", with: "src")
                            }
                        } else {
                            comment.content = table?.text ?? ""
                        }
                        if let i = comment.content.firstIndex(of: "\r\n") {
                            comment.content.remove(at: i)
                        }
                        if let action = element.at_xpath("//div[@class='pob cl']//a[1]/@href", namespaces: nil)?.text, action.contains("favorite") {
                            comment.favorite = action
                        }
                    }
                    list.append(comment)
                }
                html.getFormhash()

                if isSelectedPage {
                    comments = []
                }
                if page == 1 {
                    comments = list
                    isRefreshing = false
                } else {
                    comments += list
                }
                isHidden = true

                shieldUsers()
            }
        }
    }

    private func favorite() async {
        Task {
            // swiftlint:disable force_unwrapping
            let url = URL(string: "https://www.chongbuluo.com/\(favoriteAction)")!
            // swiftlint:enble force_unwrapping
            var requset = URLRequest(url: url)
            requset.httpMethod = "POST"
            requset.configHeaderFields()
            let (data, _) = try await URLSession.shared.data(for: requset)
            if let html = try? HTML(html: data, encoding: .utf8) {
                if let text = html.toHTML {
                    if text.contains("信息收藏成功") {
                        hud.show(message: "收藏成功")
                    } else if text.contains("已收藏") {
                        hud.show(message: "抱歉，您已收藏，请勿重复收藏")
                    } else {
                        hud.show(message: "收藏收藏失败，请稍后重试")
                    }
                }
            } else {
                hud.show(message: "收藏收藏失败，请稍后重试")
            }
        }
    }

    private func comment() async {
        if inputComment.isEmpty {
            hud.show(message: "请输入评论内容")
            return
        }

        Task {
            if !UserInfo.shared.isLogin() {
                needLogin.toggle()
                return
            }

            let time = Int(Date().timeIntervalSince1970)
            // swiftlint:disable force_unwrapping
            let parames = "&formhash=\(UserInfo.shared.formhash)&message=\(inputComment)&posttime=\(time)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let url = URL(string: "https://www.chongbuluo.com/\(action)\(parames)")!
            // swiftlint:enble force_unwrapping
            var requset = URLRequest(url: url)
            requset.httpMethod = "POST"
            requset.configHeaderFields()
            let (data, _) = try await URLSession.shared.data(for: requset)
            if let html = try? HTML(html: data, encoding: .utf8) {
                if let text = html.toHTML, text.contains("刚刚") || text.contains("秒前") {
                    inputComment = ""
                    hud.show(message: "评论成功")
                } else {
                    hud.show(message: "评论失败")
                }
                closeDialog()
                await loadData()
            }
        }
    }

    private func getReply() async {
        if replyContent.isEmpty {
            hud.show(message: "请输入回复内容")
            return
        }

        Task {
            // swiftlint:disable force_unwrapping
            let url = URL(string: "https://www.chongbuluo.com/\(replyAction)")!
            // swiftlint:enble force_unwrapping
            var requset = URLRequest(url: url)
            requset.httpMethod = "POST"
            requset.configHeaderFields()
            let (data, _) = try await URLSession.shared.data(for: requset)
            if let html = try? HTML(html: data, encoding: .utf8) {
                html.getFormhash()
                let time = Int(Date().timeIntervalSince1970)
                var param = "&formhash=\(UserInfo.shared.formhash)&message=\(replyContent)&posttime=\(time)&checkbox=0&wysiwyg=0&replysubmit=yes"
                if let noticeauthor = html.at_xpath("//input[@name='noticeauthor']/@value", namespaces: nil)?.text {
                    param += "&noticeauthor=\(noticeauthor)"
                }
                // FIXME: 回复提交提示 [quote][url=forum.php?mod=redirect
                if let noticetrimstr = html.at_xpath("//input[@name='noticetrimstr']/@value", namespaces: nil)?.text {
                    param += "&noticetrimstr=\(noticetrimstr)"
                }
                if let noticeauthormsg = html.at_xpath("//input[@name='noticeauthormsg']/@value", namespaces: nil)?.text {
                    param += "&noticeauthormsg=\(noticeauthormsg)"
                }
                if let reppid = html.at_xpath("//input[@name='reppid']/@value", namespaces: nil)?.text {
                    param += "&reppid=\(reppid)"
                }
                if let reppost = html.at_xpath("//input[@name='reppost']/@value", namespaces: nil)?.text {
                    param += "&reppost=\(reppost)"
                }
                param = param.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                await reply(param)
            }
        }
    }

    private func reply(_ param: String) async {
        Task {
            var action = replyAction.components(separatedBy: "&repquote=")[0]
            action += "&extra=&replysubmit=yes"
            // swiftlint:disable force_unwrapping
            let url = URL(string: "https://www.chongbuluo.com/\(action)\(param)")!
            // swiftlint:enble force_unwrapping
            var requset = URLRequest(url: url)
            requset.httpMethod = "POST"
            requset.configHeaderFields()
            let (data, _) = try await URLSession.shared.data(for: requset)
            if let html = try? HTML(html: data, encoding: .utf8) {
                if let text = html.toHTML, text.contains("刚刚") || text.contains("秒前") {
                    replyContent = ""
                    hud.show(message: "回复成功")
                } else {
                    hud.show(message: "回复失败")
                }
                replyFocused = false
                await loadData()
            }
        }
    }

    private func report() async {
        Task {
            let action = "misc.php?mod=report&rtype=post&tid=\(tid)"
            // swiftlint:disable force_unwrapping
            let url = URL(string: "https://www.chongbuluo.com/\(action)")!
            // swiftlint:enble force_unwrapping
            var requset = URLRequest(url: url)
            requset.httpMethod = "POST"
            requset.configHeaderFields()
            let (data, _) = try await URLSession.shared.data(for: requset)
            if let html = try? HTML(html: data, encoding: .utf8) {
                print(html)
                hud.show(message: "感谢您的举报，管理员会对改帖子内容进行审核！")
            }
        }
    }

    private func handler(url: URL) {
        var absoluteString = url.absoluteString
        if absoluteString.contains("uid=") && !absoluteString.hasPrefix("http") {
            absoluteString = "https://www.chongbuluo.com/" + absoluteString
        }
        print(absoluteString)
        if absoluteString.contains("chongbuluo"), absoluteString.contains("thread") || absoluteString.contains("uid=") {
            if absoluteString.contains("uid=") {
                let uid = getUid(url: absoluteString)
                if !uid.isEmpty {
                    self.uid = uid
                    isSpace.toggle()
                }
            } else {
                if absoluteString.contains("&tid=") {
                    let list = absoluteString.components(separatedBy: "&")
                    var tid = ""
                    list.forEach { text in
                        if text.hasPrefix("tid=") {
                            tid = text
                        }
                    }
                    let tids = tid.components(separatedBy: "=")
                    if tids.count == 2 {
                        newTid = tids[1]
                        isViewthread.toggle()
                    }
                } else if absoluteString.contains("thread-") {
                    let tids = absoluteString.components(separatedBy: "thread-")
                    if tids.count == 2 {
                        newTid = tids[1].components(separatedBy: "-")[0]
                        isViewthread.toggle()
                    }
                }
            }
        } else if absoluteString.hasPrefix("mailto:") {
            UIApplication.shared.open(url)
        } else if absoluteString.contains("&pid=") {
            let pid = getPid(url: absoluteString)
            if !pid.isEmpty, let postURL = URL(string: "msea://post?pid=\(pid)") {
                UIApplication.shared.open(postURL)
            }
        } else {
            webURLItem = WebURLItem(url: absoluteString)
        }
    }

    private func getPid(url: String) -> String {
        if url.contains("&pid=") {
            let list = url.components(separatedBy: "&")
            var pid = ""
            list.forEach { text in
                if text.hasPrefix("pid=") {
                    pid = text
                }
            }
            let pids = pid.components(separatedBy: "=")
            if pids.count == 2 {
                return pids[1]
            }
            return ""
        }
        return ""
    }

    private func getUid(url: String) -> String {
        if url.contains("&uid=") {
            let list = url.components(separatedBy: "&")
            var uid = ""
            list.forEach { text in
                if text.hasPrefix("uid=") {
                    uid = text
                }
            }
            let uids = uid.components(separatedBy: "=")
            if uids.count == 2 {
                return uids[1]
            }
            return ""
        }
        return ""
    }
}

struct TopicDetailHeaderView: View {
    var title = ""
    var commentCount = ""
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.font20)

            Text(commentCount)
        }
    }
}

struct TopicDetailContentView_Previews: PreviewProvider {
    static var previews: some View {
        TopicDetailContentView()
    }
}

struct TopicCommentModel: Identifiable {
    var id = UUID()
    var uid = ""
    var pid = ""
    var reply = ""
    var favorite = ""
    var name = ""
    var avatar = ""
    var lv = ""
    var time = ""
    var content = ""
    var isText = true
    var webViewHeight: CGFloat = .zero
}

struct WebURLItem: Identifiable {
    var id = UUID()
    var url = ""
}

enum ReportMenuItem: String, CaseIterable, Identifiable {
    case ad
    case violation
    case malicious
    case repetition

    var id: String { self.rawValue }
    var title: String {
        switch self {
        case .ad:
            return "广告垃圾"
        case .violation:
            return "违规内容"
        case .malicious:
            return "恶意灌水"
        case .repetition:
            return "重复发帖"
        }
    }
}
