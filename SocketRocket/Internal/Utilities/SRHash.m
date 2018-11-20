//
// Copyright (c) 2016-present, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

#import "SRHash.h"

#import <CommonCrypto/CommonDigest.h>

NS_ASSUME_NONNULL_BEGIN

NSData *SRSHA1HashFromString(NSString *string)
{
    size_t length = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    return SRSHA1HashFromBytes(string.UTF8String, length);
}
// SHA-1加密
NSData *SRSHA1HashFromBytes(const char *bytes, size_t length)
{
    uint8_t outputLength = CC_SHA1_DIGEST_LENGTH;
    unsigned char output[outputLength];
    CC_SHA1(bytes, (CC_LONG)length, output);

    return [NSData dataWithBytes:output length:outputLength];
}
// base64
NSString *SRBase64EncodedStringFromData(NSData *data)
{
    if ([data respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        return [data base64EncodedStringWithOptions:0]; // ios 7.0+
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [data base64Encoding]; // ios 4.0-7.0
#pragma clang diagnostic pop
}

NS_ASSUME_NONNULL_END


// 服务器 接收到来自客户端的upgrade请求，便会将请求头中的“Sec-WebSocket-Key”字段提取出来，
// 追加一个固定的“魔串”：258EAFA5-E914-47DA-95CA-C5AB0DC85B11，并进行SHA-1加密，
// 然后再次经过base64编码生成一个新的key，作为响应头中的“Sec-WebSocket-Accept”字段的内容返回给客户端。
