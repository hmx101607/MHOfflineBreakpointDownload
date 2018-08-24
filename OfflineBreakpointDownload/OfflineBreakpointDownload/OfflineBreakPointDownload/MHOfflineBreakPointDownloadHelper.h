//
//  MHOfflineBreakPointDownloadHelper.h
//  OfflineBreakpointDownload
//
//  Created by mason on 2017/5/26.
//  Copyright © 2017年 mason. All rights reserved.
//

#import <UIKit/UIKit.h>
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

@end

/**
 资源默认保存在沙盒Cache中
 */

//typedef void(^progressBlock) (MHDownloadModel *downloadModel, CGFloat currentSize, CGFloat totalSize);
//typedef void(^completionBlock) (MHDownloadModel *downloadModel, NSError *error);

@protocol MHOfflineBreakPointDownloadHelperDelegate <NSObject>

- (void)downloadProgressWithDownloadModel:(MHDownloadModel *)downloadModel;
- (void)downloadCompletionWithDownloadModel:(MHDownloadModel *)downloadModel error:(NSError *)error;

@end


@interface MHOfflineBreakPointDownloadHelper : NSObject

@property (weak, nonatomic) id<MHOfflineBreakPointDownloadHelperDelegate>delegate;

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
