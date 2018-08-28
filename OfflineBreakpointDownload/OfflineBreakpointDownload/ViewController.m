//
//  ViewController.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2017/5/26.
//  Copyright © 2017年 mason. All rights reserved.
//

#import "ViewController.h"
#import "MHOfflineBreakPointDownloadManager.h"
#import "MHFileDatabase.h"

#define kFileUrl @"http://7qnbrb.com1.z0.glb.clouddn.com/video.mp4"
#define kGifUrl @"http://7qnbrb.com1.z0.glb.clouddn.com/scrollviewNest.gif"
#define KWMVUrl @"http://7qnbrb.com1.z0.glb.clouddn.com/1102.wmv"


@interface ViewController ()
<
MHOfflineBreakPointDownloadManagerDelegate
>

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [MHOfflineBreakPointDownloadManager shareDownloadInstance].delegate = self;
}

- (IBAction)startAction:(id)sender {
    
    [[MHOfflineBreakPointDownloadManager shareDownloadInstance] addDownloadQueue:kFileUrl];
}

- (IBAction)suspendAction:(id)sender {
    [[MHOfflineBreakPointDownloadManager shareDownloadInstance] suspendDownLoadWithUrl:kFileUrl];
}

- (IBAction)cancelAction:(id)sender {
    [[MHOfflineBreakPointDownloadManager shareDownloadInstance] cancelDownLoadWithUrl:kFileUrl];
}

- (IBAction)goOnAction:(id)sender {
    [[MHOfflineBreakPointDownloadManager shareDownloadInstance] addDownloadQueue:kFileUrl];
}

- (IBAction)deleteFileAction:(id)sender {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[self getFilePathWithUrl:kFileUrl.lastPathComponent] error:nil];
    
}

- (NSString *)getFilePathWithUrl:(NSString *)url {
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:url.lastPathComponent];
    return path;
}

- (void)downloadCompletionWithDownloadModel:(MHDownloadModel *)downloadModel error:(NSError *)error {
    NSLog(@"error : %@", error.domain);
}

- (void)downloadProgressWithDownloadModel:(MHDownloadModel *)downloadModel {
    CGFloat progress = downloadModel.currentSize * 1.0 / downloadModel.totalSize * 1.0;
    self.progressView.progress = progress;
}

- (IBAction)createTableView:(id)sender {
//    [MHFileDatabase  createTable];
}

- (IBAction)query:(id)sender {
    NSArray *list = [[MHFileDatabase shareInstance] queryAllDownloading];
    [list enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MHDownloadModel *model = obj;
    }];
}

- (IBAction)insert:(id)sender {
    [[MHFileDatabase shareInstance] insertFileWithFileName:@"video.mp4" filePath:@"123" fileTotalSize:0.5];
}

@end

















