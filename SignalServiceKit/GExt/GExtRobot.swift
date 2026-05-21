//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

/// 机器人账号配置，对应服务器 gextRobot 字段
public struct GExtRobot: Codable, Equatable {

    /// 是否为机器人账号
    public let robot: Bool

    /// 消息输入栏按钮可见性（仅 robot=true 时有意义）
    public let msgButtonVisible: MsgButtonVisible?

    public struct MsgButtonVisible: Codable, Equatable {
        /// 贴纸按钮
        public let sticker: Bool?
        /// 相机按钮
        public let camera: Bool?
        /// 麦克风/语音按钮
        public let microphone: Bool?
        /// 相册按钮
        public let photos: Bool?
        /// GIF 按钮
        public let gif: Bool?
        /// 文件按钮
        public let file: Bool?
        /// 联系人按钮
        public let contact: Bool?
        /// 位置按钮
        public let location: Bool?
    }
}
