//
//  MHDownloadModel.h
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/25.
//  Copyright © 2018年 mason. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MHDownloadStatus) {
    MHDownloadStatusDownloadSuspend,
    MHDownloadStatusDownloading,
    MHDownloadStatusDownloadComplete,
    MHDownloadStatusDownloadFail,
    MHDownloadStatusDownloadCancel
};

@interface MHDownloadModel : NSObject

/** 文件地址 */
@property (strong, nonatomic) NSString *fileUrl;
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
