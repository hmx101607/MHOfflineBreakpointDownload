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
#define KWMVUrl @"http://7qnbrb.com1.z0.glb.clouddn.com/1102.wmv"

typedef struct MYStruct {
    int a;
    int b;
    
}myStruct;

@interface ViewController ()
<
MHOfflineBreakPointDownloadHelperDelegate
>

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;



@end

@implementation ViewController


- (IBAction)startAction:(id)sender {
    
    [MHOfflineBreakPointDownloadHelper shareDownloadInstance].delegate = self;
    [[MHOfflineBreakPointDownloadHelper shareDownloadInstance] addDownloadQueue:kFileUrl progressBlock:nil completionBlock:nil];
//    [[MHOfflineBreakPointDownloadHelper shareDownloadInstance] addDownloadQueue:kGifUrl progressBlock:nil completionBlock:nil];
//    [[MHOfflineBreakPointDownloadHelper shareDownloadInstance] addDownloadQueue:KWMVUrl progressBlock:nil completionBlock:nil];
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

- (void)downloadProgressWithDownloadModel:(MHDownloadModel *)downloadModel CurrentSize:(CGFloat)currentSize totalSize:(CGFloat)totalSize {
    CGFloat progress = currentSize / totalSize;
    self.progressView.progress = progress;
    NSLog(@"thread : %@, url : %@, 下载进度 --- %.2f", [NSThread currentThread], downloadModel.fileUrl.lastPathComponent, currentSize / totalSize);
}

- (void)downloadCompletionWithDownloadModel:(MHDownloadModel *)downloadModel error:(NSError *)error {
    
}

@end

















