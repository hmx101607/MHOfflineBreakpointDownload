//
//  MHOfflineBreakPointDownloadHelper.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2017/5/26.
//  Copyright © 2017年 mason. All rights reserved.
//

#import "MHOfflineBreakPointDownloadHelper.h"
#import "MHCustomOperation.h"

@interface MHDownloadModel()

/** 句柄，处理离线下载进度 */
@property (strong, nonatomic) NSFileHandle *handle;
/** <##> */
@property (strong, nonatomic) NSURLSessionDataTask *task;

@end

@implementation MHDownloadModel


@end


@interface MHOfflineBreakPointDownloadHelper()
<
 NSURLSessionDataDelegate
>

/** <##> */
@property (strong, nonatomic) NSOperationQueue *operationQueue;
/** 进度回调 */
@property (copy, nonatomic) progressBlock progressBlock;
/** 完成回调 */
@property (copy, nonatomic) completionBlock completionBlock;
/** <##> */
@property (strong, nonatomic) NSMutableArray *downloadTasks;

@end

@implementation MHOfflineBreakPointDownloadHelper

+ (instancetype)shareDownloadInstance {
    static MHOfflineBreakPointDownloadHelper *downloadHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadHelper = [[MHOfflineBreakPointDownloadHelper alloc] init];
        downloadHelper.operationQueue = [[NSOperationQueue alloc] init];
        downloadHelper.downloadTasks = [NSMutableArray array];
    });
    return downloadHelper;
}

- (void)addDownloadQueue:(NSString *)fileUrl progressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock{
    MHDownloadModel *downloadModel = [MHDownloadModel new];
    downloadModel.fileUrl = fileUrl;
    [self.downloadTasks addObject:downloadModel];
    
    [self startDownLoadWithUrl:fileUrl progressBlock:progressBlock completionBlock:completionBlock];
}

/** 开始下载 */
- (void)startDownLoadWithUrl:(NSString *)url progressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock {
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    NSURLSessionDataTask *task = downloadModel.task;
    if (task && task.state == NSURLSessionTaskStateRunning) {
        return;
    }
    task = [self downloadDataTaskWithUrl:url];
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    
    __weak typeof(self) weakSelf = self;
    MHCustomOperation *operation = [MHCustomOperation operationWithURLSessionTask:nil sessionBlock:^NSURLSessionTask *{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSLog(@"thread : %@, MHCustomOperation operationWithURLSessionTask", [NSThread currentThread]);
        return [strongSelf downloadDataTaskWithUrl:url];
    }];
    [self.operationQueue addOperation:operation];
    
}


#pragma mark - Private Method
- (NSURLSessionDataTask *)downloadDataTaskWithUrl:(NSString *)url{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:[self getFilePathWithUrl:url] error:nil];
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    downloadModel.currentSize = [dic[@"NSFileSize"] integerValue];
    [request setValue:[NSString stringWithFormat:@"bytes=%zd-",downloadModel.currentSize] forHTTPHeaderField:@"Range"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    NSLog(@"thread : %@, 执行下载 --- %s", [NSThread currentThread], __func__);
    downloadModel.task = dataTask;
    return dataTask;
}

- (NSString *)getFilePathWithUrl:(NSString *)url {
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:url.lastPathComponent];
    return path;
}

#pragma mark - +++++++++++++++++++++ NSURLSessionDataDelegate ++++++++++++++++++++++++
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"thread : %@, 开始下载 --- %s", [NSThread currentThread], __func__);
    NSString *url = dataTask.currentRequest.URL.absoluteString;
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    downloadModel.totalSize = response.expectedContentLength + downloadModel.currentSize; //获取到本次请求的最大数据
    if (downloadModel.currentSize == 0) {
        [[NSFileManager defaultManager] createFileAtPath:[self getFilePathWithUrl:url] contents:nil attributes:nil];
    }
    downloadModel.handle = [NSFileHandle fileHandleForWritingAtPath:[self getFilePathWithUrl:url]];
    [downloadModel.handle seekToEndOfFile]; // 要插入的数据移动到最后
    
    completionHandler (NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    NSString *url = dataTask.currentRequest.URL.absoluteString;
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    [downloadModel.handle writeData:data];
    downloadModel.currentSize += data.length;
    if (self.progressBlock) {
        self.progressBlock(downloadModel, downloadModel.currentSize * 1.0, downloadModel.totalSize * 1.0);
    }
    if ([self.delegate respondsToSelector:@selector(downloadProgressWithCurrentSize:totalSize:)]) {
        [self.delegate downloadProgressWithCurrentSize:downloadModel.currentSize * 1.0 totalSize:downloadModel.totalSize * 1.0];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    NSLog(@"thread : %@, 下载完成 --- %s", [NSThread currentThread], __func__);
    NSString *url = task.currentRequest.URL.absoluteString;
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    [downloadModel.handle closeFile];
    downloadModel.handle = nil;
    if (self.completionBlock) {
        self.completionBlock(downloadModel, error);
    }
    if ([self.delegate respondsToSelector:@selector(downloadCompletion:)]) {
        [self.delegate downloadCompletion:error];
    }
    [self removeDownloadModelWithFileUrl:url];
}

/** 暂停下载 */
- (void)suspendDownLoadWithUrl:(NSString *)url progressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock {
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    NSURLSessionDataTask *task = downloadModel.task;
    if (!task || task.state == NSURLSessionTaskStateSuspended) {
        return;
    }
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    [task suspend];
}

/** 取消下载 */
- (void)cancelDownLoadWithUrl:(NSString *)url {
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    NSURLSessionDataTask *task = downloadModel.task;
    if (!task || task.state == NSURLSessionTaskStateCanceling) {
        return;
    }
    [task cancel];
    task = nil;
    [self removeDownloadModelWithFileUrl:url];
}

/** 继续下载 */
- (void)goOnDownLoadWithUrl:(NSString *)url progressBlock:(progressBlock)progressBlock completionBlock:(completionBlock)completionBlock {
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    NSURLSessionDataTask *task = downloadModel.task;
    if (!task || task.state == NSURLSessionTaskStateRunning) {
        return;
    }
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    [task resume];
}

- (MHDownloadModel *)fetchDownloadModelWithFileUrl:(NSString *)fileUrl {
    for (MHDownloadModel *model in self.downloadTasks) {
        if ([model.fileUrl isEqualToString:fileUrl]) {
            return model;
        }
    }
    return nil;;
}

- (void)removeDownloadModelWithFileUrl:(NSString *)fileUrl {
    for (MHDownloadModel *model in self.downloadTasks) {
        if ([model.fileUrl isEqualToString:fileUrl]) {
            [self.downloadTasks removeObject:model];
            break;
        }
    }
}

@end
