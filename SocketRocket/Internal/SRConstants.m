//
// Copyright (c) 2016-present, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

#import "SRConstants.h"

size_t SRDefaultBufferSize(void) {
    static size_t size;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size = getpagesize(); // 一页内存大小，单位 byte
    });
    return size;
}

// 系统给我们提供真正的内存时
// 用页为单位提供
// 一次最少提供一页的真实的内存空间

// 最小存储单位是一个字节（1B），最小管理单位是一页（4KB）
// 即使一个.txt文件中只有一个“a”字母，其大小为1B而其占用大小为4K。
// https://blog.csdn.net/apollon_krj/article/details/53869173
