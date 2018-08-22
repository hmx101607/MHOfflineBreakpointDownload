//
//  MHOfflineBreakPointDownloadHelper.h
//  OfflineBreakpointDownload
//
//  Created by mason on 2017/5/26.
//  Copyright © 2017年 mason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
/**
 资源默认保存在沙盒Cache中
 */

typedef void(^progressBlock) (CGFloat currentSize, CGFloat totalSize);
typedef void(^completionBlock) (NSError *error);

@protocol MHOfflineBreakPointDownloadHelperDelegate <NSObject>

- (void)downloadProgressWithCurrentSize:(CGFloat)currentSize totalSize:(CGFloat)totalSize;
- (void)downloadCompletion:(NSError *)error;

@end

@interface MHOfflineBreakPointDownloadHelper : NSObject

@property (weak, nonatomic) id<MHOfflineBreakPointDownloadHelperDelegate>delegate;

+ (instancetype)shareDownloadInstance;

/** 开始下载 */
- (void)startDownLoadWithUrl:(NSString *)url
               progressBlock:(progressBlock)progressBlock
             completionBlock:(completionBlock)completionBlock;

/** 暂停下载 */
- (void)suspendDownLoadWithUrl:(NSString *)url
                 progressBlock:(progressBlock)progressBlock
               completionBlock:(completionBlock)completionBlock;

/** 取消下载 */
- (void)cancelDownLoadWithUrl:(NSString *)url;

/** 继续下载 */
- (void)goOnDownLoadWithUrl:(NSString *)url
              progressBlock:(progressBlock)progressBlock
            completionBlock:(completionBlock)completionBlock;


@end
