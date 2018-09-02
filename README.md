## NSURLSessionDataTask与NSOperationQueue实现多文件断点下载（任意时刻终止进程，重启应用，自动重启下载）
### 知识要点
> 1. NSURLSession网络操作
> 2. NSOperationQueue线程队列的管理
> 3. FMDB数据库操作

### NSURLSession
> NSURLSession是iOS7中用于替换NSURLConnection而新增的接口，用于网络相关的操 作，包括数据请求，上传，下载，处理认证等工具，能处理http协议中的所用事情。但NSURLSession并不直接工作，而是由NSURLSessionTask完成，NSURLSessionTask 有三个子类：数据请求**NSURLSessionDataTask**，上传**NSURLSessionUploadTask**，下载**NSURLSessionDownloadTask**，可以使用block,delegate来进行初始化，当然使用NSURLSessionDataTask来进行上传和下载工作也是可行的。
关系结构
![](http://7qnbrb.com1.z0.glb.clouddn.com/0C40F331FE61A52D81482A013B417CFF.jpg)

### NSURLSessionDataTask与NSURLSessionDownloadTask方案选择的考虑
+ NSURLSessionDownloadTask
 	+ 优点：使用cancelByProducingResumeData取消下载时，能获取到当前下载文件的情况的resumeData，包含下载了多少，总大小等，以及能配置后台下载功能。
 	+ 缺点：NSURLSessionDownloadTask下载下来的二进制文件会先存储在tmp临时文件（该文件夹下的内容随时可能清空）中，在下载结束后，才将文件移动到指定的沙盒文件中。
 
+ NSURLSessionDataTask
	+ 优点：直接将二进制数据写入可以永久存储的沙盒文件（NSDocumentDirectory,NSLibraryDirectory）中
	+ 缺点：需要自定义NSFileHandle，然后将下载的数据拼接存储在本地
+ 对比：通过两者的优缺点对比，NSURLSessionDownloadTask如果需要实现在进程终止后，能自启下载，就必须不断的将tmp的二进制文件拷贝到NSDocumentDirectory或NSLibraryDirectory中，以及不断获取resumeData值，这样会造成很大的资源的浪费以及内存的开销。使用NSURLSessionDataTask避免了二进制文件的拷贝，将基础的数据在开始下载是就存入到数据库中，从而做到任意时刻终止进程，重启应用，都能获取到资源路径，资源大小，下载的状态，保持应用终止前的状态或自动重启下载。

### 思路
+ 1.准备下载：将下载任务添加到下载任务队列中，并将文件名称，资源路径，下载状态（等待下载）存储到数据库中
+ 2.开始下载：获取到文件总大小，名称，更新表数据：下载状态为正在下载，并将二进制数据使用NSFileHandle写入沙盒
+ 3.暂停 > 更新表数据：当前下载了多少，下载状态改成：暂停
+ 4.取消下载 > 数据库中删除该条数据，从任务数组中移除该数据
+ 5.下载完成 > 数据库中删除该条数据，从任务数组中移除该数据
+ 6.应用被杀掉,重启应用
	+ 6.1.检查是否有下载队列
	+ 6.2.对于处于下载状态的队列，自动启动
	+ 6.33.处于暂停及其它情况的队列，依然保持原本的情况
 
#### 添加下载任务到队列中
> 这里分两块：第一次新增，以及由暂停或失败状态重启
 
~~~
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
~~~

#### 启动下载任务
> 此时并不一定马上下载，下载的启动由NSOperationQueue控制，默认最大的下载并发数为3。
 
~~~
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
~~~

#### 封装下载请求：
> 1.设置url  
> 2.设置request，设置请求头、请求体  
> 3.发送请求

~~~
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
~~~

#### 实现代理NSURLSessionDataDelegate
> +  开始下载：获取目标	文件的大小，创建沙盒文件
 必须调用 completionHandler (NSURLSessionResponseAllow)
 
~~~
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
~~~

> + 获取下载进度，并将二进制数据写入沙盒
 
~~~
 - (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
~~~

> + 下载完成或出错
 
~~~
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
~~~
