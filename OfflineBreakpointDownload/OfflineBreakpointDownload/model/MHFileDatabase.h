//
//  MHFileDatabase.h
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/28.
//  Copyright © 2018年 mason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MHDownloadModel.h"


@interface MHFileDatabase : NSObject

+ (instancetype)shareInstance;

/**
 只执行一次
 */
- (BOOL)createTable;

/**
 初始插入数据
 
 @param fileName 文件名称
 @param filePath 名称路径（沙盒）
 @param fileTotalSize 目标文件总大小
 @return 返回是否成功
 */
- (BOOL)insertFileWithFileName:(NSString *)fileName
                      filePath:(NSString *)filePath
                 fileTotalSize:(NSInteger)fileTotalSize;

/**
 更新下载状态
 
 @param fileName 文件名称
 @param downloadStatus 下载状态
 @return 返回是否成功
 */
- (BOOL)updateDownloadStatusWithFileName:(NSString *)fileName
                          downloadStatus:(MHDownloadStatus )downloadStatus;

/**
 删除数据

 @param fileName 文件名称
 @return 返回是否成功
 */
- (BOOL)deleteFileWithFileName:(NSString *)fileName;

/**
 查询所有未完成下载的文件

 @return 数据集合
 */
- (NSArray *)queryAllDownloading;

@end










