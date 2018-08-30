//
//  MHOfflineBreakPointDownloadManager.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2017/5/26.
//  Copyright © 2017年 mason. All rights reserved.
//

#import "MHOfflineBreakPointDownloadManager.h"
#import "MHURLSessionTaskOperation.h"
#import "MHFileDatabase.h"


@interface MHOfflineBreakPointDownloadManager()
<
 NSURLSessionDataDelegate
>

/** 队列 */
@property (strong, nonatomic) NSOperationQueue *operationQueue;
/** 下载任务 */
@property (strong, nonatomic) NSMutableArray *downloadTasks;
/** 最大并发数 */
@property (assign, nonatomic) NSInteger maxConcurrentOperationCount;
/** 是否正在下载 */
@property (assign, nonatomic) BOOL downloading;

@end

@implementation MHOfflineBreakPointDownloadManager

+ (instancetype)shareDownloadInstance {
    static MHOfflineBreakPointDownloadManager *downloadHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadHelper = [[MHOfflineBreakPointDownloadManager alloc] init];
        downloadHelper.operationQueue = [[NSOperationQueue alloc] init];
        downloadHelper.maxConcurrentOperationCount = 3;
        downloadHelper.operationQueue.maxConcurrentOperationCount =downloadHelper.maxConcurrentOperationCount;
        downloadHelper.downloadTasks = [NSMutableArray array];
    });
    return downloadHelper;
}

#pragma mark - +++++++++++++++++++++ 事件操作 start ++++++++++++++++++++++++
#pragma mark - 添加下载任务到队列中
- (void)addDownloadQueue:(NSString *)fileUrl {
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:fileUrl];
    if (downloadModel) {
        return;
    }
    //如果数据库中存在该文件，则表明仅仅只是由暂停或失败状态，重启下载（暂停 -> 正在下载）
    downloadModel = [[MHFileDatabase shareInstance] queryModelWitFileName:fileUrl.lastPathComponent];
    if (downloadModel) {
        //更新下载文件的状态
        [[MHFileDatabase shareInstance] updateDownloadStatusWithFileName:fileUrl.lastPathComponent downloadStatus:MHDownloadStatusDownloading];
    } else {
        //插入数据，记录下载文件
        [[MHFileDatabase shareInstance] insertFileWithFileName:fileUrl.lastPathComponent filePath:fileUrl fileTotalSize:0];
        downloadModel = [MHDownloadModel new];
        downloadModel.filePath = fileUrl;
    }
    
    [self.downloadTasks addObject:downloadModel];
    [self startDownLoadWithUrl:fileUrl];
}

#pragma mark - 开始下载
- (void)startDownLoadWithUrl:(NSString *)url {
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    downloadModel.downloadStatus = MHDownloadStatusDownloadWait;
    NSURLSessionDataTask *task = downloadModel.task;
    if (task && task.state == NSURLSessionTaskStateRunning) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    MHURLSessionTaskOperation *operation = [MHURLSessionTaskOperation operationWithURLSessionTask:nil sessionBlock:^NSURLSessionTask *{
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

#pragma mark - 暂停下载
- (void)suspendDownLoadWithUrl:(NSString *)url{
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    NSURLSessionDataTask *task = downloadModel.task;
    if (!task || task.state == NSURLSessionTaskStateSuspended) {
        return;
    }
    downloadModel.downloadStatus = MHDownloadStatusDownloadSuspend;
    [task cancel];
}

#pragma mark - 取消下载
- (void)cancelDownLoadWithUrl:(NSString *)url {
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    NSURLSessionDataTask *task = downloadModel.task;
    if (!task || task.state == NSURLSessionTaskStateCanceling) {
        [self cancelTask:url];
        return;
    } else {
    }
    downloadModel.downloadStatus = MHDownloadStatusDownloadCancel;
    [task cancel];
    task = nil;
    [self cancelTask:url];
}

#pragma mark - +++++++++++++++++++++ 事件操作 end ++++++++++++++++++++++++

#pragma mark - Private Method
- (void)completeTask:(NSString *)fileUrl {
    [self removeDownloadModelWithFileUrl:fileUrl];
    [[MHFileDatabase shareInstance] deleteFileWithFileName:fileUrl.lastPathComponent];
}

- (void)suspendOrFialTask:(NSString *)fileUrl suspend:(BOOL)suspend{
    //从下载任务中移除
    [self removeDownloadModelWithFileUrl:fileUrl];
    //数据库中保留数据
    if (suspend) {
        //修改数据库改文件的下载状态
        [[MHFileDatabase shareInstance] updateDownloadStatusWithFileName:fileUrl.lastPathComponent downloadStatus:MHDownloadStatusDownloadSuspend];
    } else {
        //修改数据库改文件的下载状态
        [[MHFileDatabase shareInstance] updateDownloadStatusWithFileName:fileUrl.lastPathComponent downloadStatus:MHDownloadStatusDownloadFail];
    }
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:[self getFilePathWithUrl:fileUrl] error:nil];
    [[MHFileDatabase shareInstance] updateDownloadFileCurrentSizeWithFileName:fileUrl.lastPathComponent fileCurrentSize:[dic[@"NSFileSize"] integerValue]];
}

- (void)cancelTask:(NSString *)fileUrl {
    //从下载任务中移除
    [self removeDownloadModelWithFileUrl:fileUrl];
    //从数据库及文件中移除
    [[MHFileDatabase shareInstance] deleteFileWithFileName:fileUrl.lastPathComponent];
    //从磁盘中删除该条数据
    NSString *path = [self getFilePathWithUrl:fileUrl.lastPathComponent];
    NSError *error;
    if (path && path.length > 0) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    }
    if (error) {
        NSLog(@"移除失败  : %@", error);
    }
}

#pragma mark - +++++++++++++++++++++ NSURLSessionDataDelegate start ++++++++++++++++++++++++
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"thread : %@, 开始下载 --- %s", [NSThread currentThread], __func__);
    NSString *url = dataTask.currentRequest.URL.absoluteString;
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    downloadModel.downloadStatus = MHDownloadStatusDownloading;
    downloadModel.totalSize = response.expectedContentLength + downloadModel.currentSize; //获取到本次请求的最大数据
    if (downloadModel.currentSize == 0) {
        [[NSFileManager defaultManager] createFileAtPath:[self getFilePathWithUrl:url] contents:nil attributes:nil];
    }
    downloadModel.handle = [NSFileHandle fileHandleForWritingAtPath:[self getFilePathWithUrl:url]];
    [downloadModel.handle seekToEndOfFile]; // 要插入的数据移动到最后
    
    //更新下载文件的总大小与及状态
    [[MHFileDatabase shareInstance] updateDownloadFileTotalSizeWithFileName:url.lastPathComponent downloadStatus:MHDownloadStatusDownloading fileTotalSize:downloadModel.totalSize];
    
    completionHandler (NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    NSString *url = dataTask.currentRequest.URL.absoluteString;
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    [downloadModel.handle writeData:data];
    downloadModel.currentSize += data.length;
    if ([self.delegate respondsToSelector:@selector(downloadProgressWithDownloadModel:)]) {
        [self.delegate downloadProgressWithDownloadModel:downloadModel];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    NSLog(@"thread : %@, 下载完成 --- %s", [NSThread currentThread], __func__);
    NSString *url = task.currentRequest.URL.absoluteString;
    MHDownloadModel *downloadModel = [self fetchDownloadModelWithFileUrl:url];
    if (!downloadModel) {
        return;
    }
    [downloadModel.handle closeFile];
    downloadModel.handle = nil;
    if (error) {
        if ([error.userInfo[NSLocalizedDescriptionKey] isEqualToString:@"cancelled"]) {
            if (downloadModel.downloadStatus == MHDownloadStatusDownloadSuspend) {
                [self suspendOrFialTask:url suspend:YES];
            } else if (downloadModel.downloadStatus == MHDownloadStatusDownloadCancel) {
                [self cancelTask:url];
            }
        } else {
            downloadModel.downloadStatus = MHDownloadStatusDownloadFail;
            [self suspendOrFialTask:url suspend:NO];
        }
        NSLog(@"error : %@", error);
    } else {
        downloadModel.downloadStatus = MHDownloadStatusDownloadComplete;
        [self completeTask:url];
    }
    if ([self.delegate respondsToSelector:@selector(downloadCompletionWithDownloadModel:error:)]) {
        [self.delegate downloadCompletionWithDownloadModel:downloadModel error:error];
    }
    [downloadModel.task cancel];
}
#pragma mark - +++++++++++++++++++++ NSURLSessionDataDelegate end ++++++++++++++++++++++++


#pragma mark - 根据filePath获取model实体
- (MHDownloadModel *)fetchDownloadModelWithFileUrl:(NSString *)filePath {
    @synchronized(self.downloadTasks) {
        for (MHDownloadModel *model in self.downloadTasks) {
            if ([model.filePath isEqualToString:filePath]) {
                return model;
            }
        }
    }
    return nil;;
}

#pragma mark - 根据filePath移除下载任务
- (void)removeDownloadModelWithFileUrl:(NSString *)filePath {
    @synchronized(self.downloadTasks) {
        for (MHDownloadModel *model in self.downloadTasks) {
            if ([model.filePath isEqualToString:filePath]) {
                [self.downloadTasks removeObject:model];
                break;
            }
        }
    }
}

- (NSString *)getFilePathWithUrl:(NSString *)url {
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:url.lastPathComponent];
    NSLog(@"path : %@", path);
    return path;
}

@end
