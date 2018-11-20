//
// Copyright (c) 2016-present, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

#import "SRHTTPConnectMessage.h"

#import "SRURLUtilities.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *_SRHTTPConnectMessageHost(NSURL *url)
{
    NSString *host = url.host;
    if (url.port) {
        host = [host stringByAppendingFormat:@":%@", url.port];
    }
    return host;
}
// 创建一个 websocket 请求
CFHTTPMessageRef SRHTTPConnectMessageCreate(NSURLRequest *request,
                                            NSString *securityKey,
                                            uint8_t webSocketProtocolVersion,
                                            NSArray<NSHTTPCookie *> *_Nullable cookies,
                                            NSArray<NSString *> *_Nullable requestedProtocols)
{
    NSURL *url = request.URL;
    // http fd
    CFHTTPMessageRef message = CFHTTPMessageCreateRequest(NULL, CFSTR("GET"), (__bridge CFURLRef)url, kCFHTTPVersion1_1);

    // Set host first so it defaults
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Host"), (__bridge CFStringRef)_SRHTTPConnectMessageHost(url));

    // Sec-WebSocket-Key
    NSMutableData *keyBytes = [[NSMutableData alloc] initWithLength:16];
    int result = SecRandomCopyBytes(kSecRandomDefault, keyBytes.length, keyBytes.mutableBytes);
    if (result != errSecSuccess) {
        //TODO: (nlutsenko) Check if there was an error.
        // 是否可以使用一个固定的
    }

    // Apply cookies if any have been provided
    if (cookies) {
        NSDictionary<NSString *, NSString *> *messageCookies = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
        [messageCookies enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            if (key.length && obj.length) {
                CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef)key, (__bridge CFStringRef)obj);
            }
        }];
    }

    // set header for http basic auth
    NSString *basicAuthorizationString = SRBasicAuthorizationHeaderFromURL(url);
    if (basicAuthorizationString) {
        CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Authorization"), (__bridge CFStringRef)basicAuthorizationString);
    }

    // Upgrade 向服务器指定某种传输协议以便服务器进行转换
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Upgrade"), CFSTR("websocket"));
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Connection"), CFSTR("Upgrade"));
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Sec-WebSocket-Key"), (__bridge CFStringRef)securityKey);
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Sec-WebSocket-Version"), (__bridge CFStringRef)@(webSocketProtocolVersion).stringValue);

    // Origin 仅指示服务器名称
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Origin"), (__bridge CFStringRef)SRURLOrigin(url));

    if (requestedProtocols.count) {
        CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Sec-WebSocket-Protocol"),
                                         (__bridge CFStringRef)[requestedProtocols componentsJoinedByString:@", "]);
    }

    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef)key, (__bridge CFStringRef)obj);
    }];

    return message;
}

NS_ASSUME_NONNULL_END

/*
 
 这个请求头包含“Upgrade”字段，内容为“websocket”（注：upgrade字段用于改变HTTP协议版本或换用其他协议，这里显然是换用了websocket协议），
 还有一个最重要的字段“Sec-WebSocket-Key”，这是一个随机的经过base64编码的字符串，像密钥一样用于服务器和客户端的握手过程。
 
 一旦服务器君接收到来自客户端的upgrade请求，便会将请求头中的“Sec-WebSocket-Key”字段提取出来，追加一个固定的“魔串”：258EAFA5-E914-47DA-95CA-C5AB0DC85B11，并进行SHA-1加密，然后再次经过base64编码生成一个新的key，作为响应头中的“Sec-WebSocket-Accept”字段的内容返回给浏览器。
 一旦浏览器接收到来自服务器的响应，便会解析响应中的“Sec-WebSocket-Accept”字段，与自己加密编码后的串进行匹配，一旦匹配成功，便有建立连接的可能了（因为还依赖许多其他因素）
 
 
 基本的Client请求
 GET /chat HTTP/1.1
 Host: server.example.com
 Upgrade: websocket
 Connection: Upgrade
 Sec-WebSocket-Key: ************
 Sec-WebSocket-Version: **
 Sec-WebSocket-Protocol: chat, superchat
 Origin: http://example.com
 
 Server 响应头：
 HTTP/1.1 101 Switching Protocols
 Upgrade: websocket
 Connection: Upgrade
 Sec-WebSocket-Accept: *************
 Sec-WebSocket-Protocol: chat
 
 表示双方握手成功
 
 */
