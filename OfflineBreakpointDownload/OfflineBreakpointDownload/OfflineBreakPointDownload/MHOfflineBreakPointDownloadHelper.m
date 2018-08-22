//
//  MHOfflineBreakPointDownloadHelper.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2017/5/26.
//  Copyright © 2017年 mason. All rights reserved.
//

#import "MHOfflineBreakPointDownloadHelper.h"

@interface MHOfflineBreakPointDownloadHelper()<NSURLSessionDataDelegate>

/** 下载资源路径 */
@property (strong, nonatomic) NSString *sourceUrl; //必须为NSUrl
/** 会话 */
//@property (strong, nonatomic) NSURLSession *session;

/** 任务 */
//@property (strong, nonatomic) NSURLSessionDataTask *dataTask;

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

/** <##> */
@property (strong, nonatomic) NSMutableDictionary *dataTaskDictionary;

@end

@implementation MHOfflineBreakPointDownloadHelper

+ (instancetype)shareDownloadInstance {
    static MHOfflineBreakPointDownloadHelper *downloadHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadHelper = [[MHOfflineBreakPointDownloadHelper alloc] init];
        downloadHelper.dataTaskDictionary = [NSMutableDictionary dictionary];
    });
    return downloadHelper;
}

/** 开始下载 */
- (void)startDownLoadWithUrl:(NSString *)url progressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock {
    NSURLSessionDataTask *task = self.dataTaskDictionary[url];
    if (task && task.state == NSURLSessionTaskStateRunning) {
        return;
    }
    task = [self downloadDataTaskWithUrl:url];
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    [task resume];
}

/** 暂停下载 */
- (void)suspendDownLoadWithUrl:(NSString *)url progressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock {
    NSURLSessionDataTask *task = self.dataTaskDictionary[url];
    if (!task || task.state == NSURLSessionTaskStateSuspended) {
        return;
    }
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    [task suspend];
}

/** 取消下载 */
- (void)cancelDownLoadWithUrl:(NSString *)url {
    NSURLSessionDataTask *task = self.dataTaskDictionary[url];
    if (!task || task.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    [task cancel];
    task = nil;
    [self.dataTaskDictionary removeObjectForKey:url];
}

/** 继续下载 */
- (void)goOnDownLoadWithUrl:(NSString *)url progressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock {
    NSURLSessionDataTask *task = self.dataTaskDictionary[url];
    if (!task || task.state == NSURLSessionTaskStateRunning) {
        return;
    }
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    [task resume];
}

#pragma mark - Private Method
- (NSURLSessionDataTask *)downloadDataTaskWithUrl:(NSString *)url{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:[self getFilePathWithUrl:url] error:nil];
    self.currentSize = [dic[@"NSFileSize"] integerValue];
    [request setValue:[NSString stringWithFormat:@"bytes=%zd-",self.currentSize] forHTTPHeaderField:@"Range"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];

    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    [self.dataTaskDictionary setValue:dataTask forKey:url];
    return dataTask;
}

- (NSString *)getFilePathWithUrl:(NSString *)url {
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:url.lastPathComponent];
    return path;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"开始下载 --- %s", __func__);
    self.totalSize = response.expectedContentLength + self.currentSize; //获取到本次请求的最大数据
    NSString *url = dataTask.currentRequest.URL.absoluteString;
    if (self.currentSize == 0) {
        [[NSFileManager defaultManager] createFileAtPath:[self getFilePathWithUrl:url] contents:nil attributes:nil];
    }
    self.handle = [NSFileHandle fileHandleForWritingAtPath:[self getFilePathWithUrl:url]];
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
    NSLog(@"下载完成 --- %s", __func__);
    [self.handle closeFile];
    self.handle = nil;
    
    if (self.completionBlock) {
        self.completionBlock(error);
    }
    if ([self.delegate respondsToSelector:@selector(downloadCompletion:)]) {
        [self.delegate downloadCompletion:error];
    }
    NSString *url = task.currentRequest.URL.absoluteString;
    [self.dataTaskDictionary removeObjectForKey:url];
}


@end
