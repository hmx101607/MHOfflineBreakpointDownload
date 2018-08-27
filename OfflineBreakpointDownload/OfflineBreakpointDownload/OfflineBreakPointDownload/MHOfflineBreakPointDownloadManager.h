//
//  MHOfflineBreakPointDownloadManager.h
//  OfflineBreakpointDownload
//
//  Created by mason on 2017/5/26.
//  Copyright © 2017年 mason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "MHDownloadModel.h"

/**
 资源默认保存在沙盒Cache中
 */

//typedef void(^progressBlock) (MHDownloadModel *downloadModel, CGFloat currentSize, CGFloat totalSize);
//typedef void(^completionBlock) (MHDownloadModel *downloadModel, NSError *error);

@protocol MHOfflineBreakPointDownloadManagerDelegate <NSObject>

- (void)downloadProgressWithDownloadModel:(MHDownloadModel *)downloadModel;
- (void)downloadCompletionWithDownloadModel:(MHDownloadModel *)downloadModel error:(NSError *)error;

@end


@interface MHOfflineBreakPointDownloadManager : NSObject

@property (weak, nonatomic) id<MHOfflineBreakPointDownloadManagerDelegate>delegate;

+ (instancetype)shareDownloadInstance;

/**
 最大并发数
 
 @param count 数值
 */
- (void)setMaxConcurrentOperationCount:(NSInteger)count;

- (void)addDownloadQueue:(NSString *)fileUrl;

/** 暂停下载 */
- (void)suspendDownLoadWithUrl:(NSString *)url;

/** 取消下载 */
- (void)cancelDownLoadWithUrl:(NSString *)url;

/** 继续下载 */
- (void)goOnDownLoadWithUrl:(NSString *)url;


@end
