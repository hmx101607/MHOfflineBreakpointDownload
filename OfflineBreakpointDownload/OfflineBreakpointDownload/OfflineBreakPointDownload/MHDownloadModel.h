//
//  MHDownloadModel.h
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/25.
//  Copyright © 2018年 mason. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MHDownloadStatus) {
    MHDownloadStatusDownloadWait,
    MHDownloadStatusDownloadSuspend,
    MHDownloadStatusDownloading,
    MHDownloadStatusDownloadComplete,
    MHDownloadStatusDownloadFail,
    MHDownloadStatusDownloadCancel
};

@interface MHDownloadModel : NSObject

//1.创建表：主键序列，文件名称，文件路径，总大小，已经下载大小（可选），下载状态（正在下载，暂停）

/** 文件id */
@property (assign, nonatomic) NSInteger fileId;
/** 文件地址(原始下载地址) */
@property (strong, nonatomic) NSString *filePath;
/** 文件名称 */
@property (strong, nonatomic) NSString *fileName;
/** 总大小 */
@property (assign, nonatomic) NSInteger totalSize;
/** 当前下载大小 */
@property (assign, nonatomic) NSInteger currentSize;
/** 下载状态<##> */
@property (assign, nonatomic)  MHDownloadStatus downloadStatus;

/** 句柄，处理离线下载进度 */
@property (strong, nonatomic) NSFileHandle *handle;
/** <##> */
@property (strong, nonatomic) NSURLSessionDataTask *task;

@end
