//
// Copyright (c) 2016-present, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

#import <Foundation/Foundation.h>

// opcode 4bit
// 解释说明 payload data 的用途、功能
// 如果收到了未知的opcode，最后会断开连接
// 0x0    连续的帧
// 0x1    text帧
// 0x2    binary帧
// 0x3-7  为非控制帧而预留的
// 0x8    关闭握手帧
// 0x9    ping帧
// 0xA    pong帧
// 0xB-F  为非控制帧预留的

typedef NS_ENUM(NSInteger, SROpCode)
{
    SROpCodeTextFrame = 0x1,   // text帧
    SROpCodeBinaryFrame = 0x2, // binary帧
    // 3-7 reserved.
    SROpCodeConnectionClose = 0x8,  // 关闭握手帧
    SROpCodePing = 0x9,  // ping帧
    SROpCodePong = 0xA,  // pong帧
    // B-F reserved.
};

/**
 Default buffer size that is used for reading/writing to streams.
 */
extern size_t SRDefaultBufferSize(void);
