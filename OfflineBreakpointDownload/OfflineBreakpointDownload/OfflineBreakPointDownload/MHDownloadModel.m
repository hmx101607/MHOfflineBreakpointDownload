//
//  MHDownloadModel.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/25.
//  Copyright © 2018年 mason. All rights reserved.
//

/*
 表的正常操作：
 1.创建表：主键序列，文件名称，文件路径，总大小，已经下载大小（可选），下载状态（正在下载，暂停）
 2.开始下载时，获取到文件总大小，名称，更新表数据：下载状态为正在下载
 3.暂停 > 更新表数据：当前下载了多少，下载状态改成：暂停
 4.取消下载 > 删除该条数据
 5.下载完成 > 删除该条数据
 
 应用被杀掉
 1.检查是否有下载队列
 2.
 */

#import "MHDownloadModel.h"
#import <FMDB.h>

@interface MHDownloadModel()


@end

@implementation MHDownloadModel


@end




























