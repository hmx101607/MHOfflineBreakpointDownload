//
//  ViewController.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2017/5/26.
//  Copyright © 2017年 mason. All rights reserved.
//

#import "ViewController.h"
#import "MHOfflineBreakPointDownloadHelper.h"

#define kFileUrl @"http://7qnbrb.com1.z0.glb.clouddn.com/video.mp4"
#define kGifUrl @"http://7qnbrb.com1.z0.glb.clouddn.com/scrollviewNest.gif"

typedef struct MYStruct {
    int a;
    int b;
    
}myStruct;

@interface ViewController ()


@property (weak, nonatomic) IBOutlet UIProgressView *progressView;



@end

@implementation ViewController


- (IBAction)startAction:(id)sender {
    
    
    NSRange range = NSMakeRange(10, 10);
    
//    [[MHOfflineBreakPointDownloadHelper shareDownloadInstance] startDownLoadWithProgressBlock:^(CGFloat currentSize, CGFloat totalSize) {
//        
//    } completionBlock:^(NSError *error) {
//        
//    }];
    [[MHOfflineBreakPointDownloadHelper shareDownloadInstance] addDownloadQueue:kFileUrl progressBlock:^(MHDownloadModel *downloadModel, CGFloat currentSize, CGFloat totalSize) {
        NSLog(@"thread : %@, url : %@, 执行下载 --- %.2f", [NSThread currentThread], downloadModel.fileUrl, currentSize / totalSize);
    } completionBlock:^(MHDownloadModel *downloadModel, NSError *error) {
        
    }];
    
    [[MHOfflineBreakPointDownloadHelper shareDownloadInstance] addDownloadQueue:kGifUrl progressBlock:^(MHDownloadModel *downloadModel, CGFloat currentSize, CGFloat totalSize) {
        NSLog(@"thread : %@, url : %@, 执行下载 --- %.2f", [NSThread currentThread], downloadModel.fileUrl, currentSize / totalSize);
    } completionBlock:^(MHDownloadModel *downloadModel, NSError *error) {
        
    }];
}

- (IBAction)suspendAction:(id)sender {
    [[MHOfflineBreakPointDownloadHelper shareDownloadInstance] suspendDownLoadWithUrl:kFileUrl progressBlock:^(MHDownloadModel *downloadModel, CGFloat currentSize, CGFloat totalSize) {
        CGFloat progress = currentSize / totalSize;
        self.progressView.progress = progress;
        NSLog(@"progress : %.2f", progress);
        
    } completionBlock:^(MHDownloadModel *downloadModel, NSError *error) {
        
    }];;
}

- (IBAction)cancelAction:(id)sender {
    [[MHOfflineBreakPointDownloadHelper shareDownloadInstance] cancelDownLoadWithUrl:kFileUrl];
}

- (IBAction)goOnAction:(id)sender {
    [[MHOfflineBreakPointDownloadHelper shareDownloadInstance] goOnDownLoadWithUrl:kFileUrl progressBlock:^(MHDownloadModel *downloadModel, CGFloat currentSize, CGFloat totalSize) {
        CGFloat progress = currentSize / totalSize;
        self.progressView.progress = progress;
        NSLog(@"thread : %@, progress : %.2f", [NSThread currentThread], progress);
        
    } completionBlock:^(MHDownloadModel *downloadModel, NSError *error) {
        
    }];;
}

- (IBAction)deleteFileAction:(id)sender {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[self getFilePathWithUrl:kFileUrl.lastPathComponent] error:nil];
    
}

- (NSString *)getFilePathWithUrl:(NSString *)url {
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:url.lastPathComponent];
    return path;
}

- (void)download {
//    MHOfflineBreakPointDownloadHelper *downloadHelper = [MHOfflineBreakPointDownloadHelper shareDownloadInstance];
//    [downloadHelper setProgressBlock:^(CGFloat currentSize, CGFloat totalSize){
//        NSLog(@" %zd ------ 下载进度 : %f", __func__, currentSize / totalSize);
//        self.progressView.progress = currentSize / totalSize;
//    }];
//
//    [downloadHelper setCompletionBlock:^(NSError *error){
//
//    }];
//    //@"http://7qnbrb.com1.z0.glb.clouddn.com/abc.mp3"//@"http://120.25.226.186:32812/resources/videos/minion_01.mp4"
//    downloadHelper.sourceUrl = @"http://7qnbrb.com1.z0.glb.clouddn.com/abc.mp3";
//    [downloadHelper startDownLoad];
}

@end
