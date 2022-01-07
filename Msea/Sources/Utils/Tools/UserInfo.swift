//
//  UserInfo.swift
//  Msea
//
//  Created by tzqiang on 2021/12/13.
//  Copyright © 2021 eternal.just. All rights reserved.
//

import Foundation
import SwiftUI

/// 用户信息
class UserInfo: NSObject {
    /// 单例
    static let shared: UserInfo = UserInfo()

    func reset() {
        uid = ""
        space = ""
        level = "LV0"
        name = ""
        avatar = ""
        auth = ""
        formhash = ""
        views = "--"
        integral = "--"
        bits = "--"
        friend = "--"
        topic = "--"
        violation = "--"
        blog = "--"
        album = "--"
        share = "--"
    }

    func isLogin() -> Bool {
        return !auth.isEmpty
    }

    @AppStorage(UserKeys.uid) var uid = ""
    @AppStorage(UserKeys.space) var space = ""
    @AppStorage(UserKeys.level) var level = "LV0"
    @AppStorage(UserKeys.name) var name = ""
    @AppStorage(UserKeys.avatar) var avatar = ""
    @AppStorage(UserKeys.auth) var auth = ""
    @AppStorage(UserKeys.formhash) var formhash = ""
    @AppStorage(UserKeys.views) var views = "0"
    @AppStorage(UserKeys.integral) var integral = "--"
    @AppStorage(UserKeys.bits) var bits = "--"
    @AppStorage(UserKeys.friend) var friend = "--"
    @AppStorage(UserKeys.topic) var topic = "--"
    @AppStorage(UserKeys.violation) var violation = "--"
    @AppStorage(UserKeys.blog) var blog = "--"
    @AppStorage(UserKeys.album) var album = "--"
    @AppStorage(UserKeys.share) var share = "--"
}
