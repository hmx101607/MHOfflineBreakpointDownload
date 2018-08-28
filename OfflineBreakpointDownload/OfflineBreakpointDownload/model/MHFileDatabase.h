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
 更新文件总大小

 @param fileName 文件名称
 @param fileTotalSize 文件总大小
 @return 返回是否成功
 */
- (BOOL)updateDownloadFileTotalSizeWithFileName:(NSString *)fileName
                                  fileTotalSize:(NSInteger)fileTotalSize;


/**
 更新当前下载的进度

 @param fileName 文件名称
 @param fileCurrentSize 当前下载的大小
 @return 返回是否成功
 */
- (BOOL)updateDownloadFileCurrentSizeWithFileName:(NSString *)fileName
                                  fileCurrentSize:(NSInteger)fileCurrentSize;

/**
 删除数据

 @param fileName 文件名称
 @return 返回是否成功
 */
- (BOOL)deleteFileWithFileName:(NSString *)fileName;


/**
 根据文件名称，查询是否有某个文件

 @param fileName 文件名称
 @return 返回是否成功
 */
- (MHDownloadModel *)queryModelWitFileName:(NSString *)fileName;

/**
 查询所有未完成下载的文件

 @return 数据集合
 */
- (NSArray *)queryAllDownloading;

@end










