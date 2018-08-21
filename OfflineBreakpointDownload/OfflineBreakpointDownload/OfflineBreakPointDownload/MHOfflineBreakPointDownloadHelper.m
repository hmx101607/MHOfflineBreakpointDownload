//
//  MHOfflineBreakPointDownloadHelper.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2017/5/26.
//  Copyright © 2017年 mason. All rights reserved.
//

#import "MHOfflineBreakPointDownloadHelper.h"

@interface MHOfflineBreakPointDownloadHelper()<NSURLSessionDataDelegate>

/** 会话 */
@property (strong, nonatomic) NSURLSession *session;

/** 任务 */
@property (strong, nonatomic) NSURLSessionDataTask *dataTask;

/** 句柄，处理离线下载进度 */
@property (strong, nonatomic) NSFileHandle *handle;

/** 总大小 */
@property (assign, nonatomic) NSInteger totalSize;

/** 当前下载大小 */
@property (assign, nonatomic) NSInteger currentSize;

/** 进度回调 */
@property (copy, nonatomic) progressBlock progressBlock;

/** 完成回调 */
@property (copy, nonatomic) completionBlock completionBlock;

@end

@implementation MHOfflineBreakPointDownloadHelper

+ (instancetype)shareDownloadInstance {
    static MHOfflineBreakPointDownloadHelper *downloadHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadHelper = [[MHOfflineBreakPointDownloadHelper alloc] init];
    });
    return downloadHelper;
}

/** 开始下载 */
- (void)startDownLoadWithProgressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock {
    if (self.dataTask.state == NSURLSessionTaskStateRunning) {
        return;
    }
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    [self.dataTask resume];
}

- (void)startDownLoadWithUrl:(NSString *)url progressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock {
    if (self.dataTask.state == NSURLSessionTaskStateRunning) {
        return;
    }
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    [self.dataTask resume];
}

/** 暂停下载 */
- (void)suspendDownLoadWithProgressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock {
    if (self.dataTask.state == NSURLSessionTaskStateSuspended) {
        return;
    }
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    [self.dataTask suspend];
}

- (void)suspendDownLoadWithUrl:(NSString *)url progressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock {
    if (self.dataTask.state == NSURLSessionTaskStateSuspended) {
        return;
    }
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    [self.dataTask suspend];
}

/** 取消下载 */
- (void)cancelDownLoad {
    if (!self.dataTask || self.dataTask.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    [self.dataTask cancel];
    self.dataTask = nil;
}

/** 继续下载 */
- (void)goOnDownLoadWithProgressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock {
    if (self.dataTask.state == NSURLSessionTaskStateRunning) {
        return;
    }
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    [self.dataTask resume];
}

- (void)goOnDownLoadWithUrl:(NSString *)url progressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock {
    if (self.dataTask.state == NSURLSessionTaskStateRunning) {
        return;
    }
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    [self.dataTask resume];}

#pragma mark - Private Method
- (NSString *)getFilePath {
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:self.sourceUrl.lastPathComponent];
    return path;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"开始下载 --- %zd", __func__);
    self.totalSize = response.expectedContentLength + self.currentSize; //获取到本次请求的最大数据
    
    if (self.currentSize == 0) {
        [[NSFileManager defaultManager] createFileAtPath:[self getFilePath] contents:nil attributes:nil];
    }
    self.handle = [NSFileHandle fileHandleForWritingAtPath:[self getFilePath]];
    [self.handle seekToEndOfFile]; // 要插入的数据移动到最后
    
    completionHandler (NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    [self.handle writeData:data];
    self.currentSize += data.length;
    if (self.progressBlock) {
        self.progressBlock(self.currentSize * 1.0, self.totalSize * 1.0);
    }
    if ([self.delegate respondsToSelector:@selector(downloadProgressWithCurrentSize:totalSize:)]) {
        [self.delegate downloadProgressWithCurrentSize:self.currentSize * 1.0 totalSize:self.totalSize * 1.0];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    NSLog(@"下载完成 --- %zd", __func__);
    [self.handle closeFile];
    self.handle = nil;
    
    if (self.completionBlock) {
        self.completionBlock(error);
    }
    if ([self.delegate respondsToSelector:@selector(downloadCompletion:)]) {
        [self.delegate downloadCompletion:error];
    }
    NSLog(@"path : %@", [self getFilePath]);
}

#pragma mark - Property
- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

- (NSURLSessionDataTask *)dataTask{
    if (!_dataTask) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.sourceUrl]];
        
        NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:[self getFilePath] error:nil];
        self.currentSize = [dic[@"NSFileSize"] integerValue];
        [request setValue:[NSString stringWithFormat:@"bytes=%zd-",self.currentSize] forHTTPHeaderField:@"Range"];
        _dataTask = [self.session dataTaskWithRequest:request];
    }
    return _dataTask;
}

- (void)dealloc{
    [self.session invalidateAndCancel]; //销毁NSSession
}

@end
