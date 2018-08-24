//
//  MHSingleOperationViewController.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/24.
//  Copyright © 2018年 mason. All rights reserved.
//

#import "MHSingleOperationViewController.h"
#import "MHDownloadListItemTableViewCell.h"
#import "MHOfflineBreakPointDownloadHelper.h"

static NSString *const kDownloadCellIdentifier = @"kDownloadCellIdentifier";

#define kFileUrl @"http://7qnbrb.com1.z0.glb.clouddn.com/video.mp4"
#define kGifUrl @"http://7qnbrb.com1.z0.glb.clouddn.com/scrollviewNest.gif"
#define KWMVUrl @"http://7qnbrb.com1.z0.glb.clouddn.com/1102.wmv"

@interface MHSingleOperationViewController ()
<
UITableViewDelegate,
UITableViewDataSource,
MHDownloadListItemTableViewCellDelegate,
MHOfflineBreakPointDownloadHelperDelegate
>
/** <##> */
@property (strong, nonatomic) UITableView *tableView;
/** <##> */
@property (strong, nonatomic) NSMutableArray *itemArray;

@end

@implementation MHSingleOperationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [MHOfflineBreakPointDownloadHelper shareDownloadInstance].delegate = self;

    [self setupView];
}

- (void)setupView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView = tableView;
    [self.view addSubview:tableView];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.rowHeight = 100.f;
    [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([MHDownloadListItemTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([MHDownloadListItemTableViewCell class])];
    tableView.tableFooterView = [UIView new];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.itemArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MHDownloadListItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([MHDownloadListItemTableViewCell class]) forIndexPath:indexPath];
    MHDownloadModel *downloadModel = self.itemArray[indexPath.row];
    cell.downloadModel = downloadModel;
    cell.delegate = self;
    return cell;
}

#pragma mark - Delegate MHDownloadListItemTableViewCellDelegate
- (void)startDownloadWithDownloadModel:(MHDownloadModel *)downloadModel {
    [[MHOfflineBreakPointDownloadHelper shareDownloadInstance] addDownloadQueue:downloadModel.fileUrl];
}

- (void)suspendDownloadWithDownloadModel:(MHDownloadModel *)downloadModel {
    [[MHOfflineBreakPointDownloadHelper shareDownloadInstance] suspendDownLoadWithUrl:downloadModel.fileUrl];
}

- (void)cancelDownloadWithDownloadModel:(MHDownloadModel *)downloadModel {
    [[MHOfflineBreakPointDownloadHelper shareDownloadInstance] cancelDownLoadWithUrl:downloadModel.fileUrl];
}

#pragma mark - Delegate MHOfflineBreakPointDownloadHelperDelegate
- (void)downloadProgressWithDownloadModel:(MHDownloadModel *)downloadModel {
    NSLog(@"thread : %@, url : %@, 下载进度 +++++downloadModel.progress : %.2f", [NSThread currentThread], downloadModel.fileUrl.lastPathComponent, downloadModel.currentSize*1.0 /downloadModel.totalSize*1.0);
    NSInteger index = [self fetchDownloadModelWithFileUrl:downloadModel.fileUrl];
    if (index == -1) {
        return;
    }
    if (downloadModel.downloadStatus == MHDownloadStatusDownloadComplete || downloadModel.downloadStatus == MHDownloadStatusDownloadCancel) {
        [self.itemArray removeObjectAtIndex:index];
        [self.tableView reloadData];
    } else {
        [self.itemArray replaceObjectAtIndex:index withObject:downloadModel];
        [self.tableView beginUpdates];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
}

- (void)downloadCompletionWithDownloadModel:(MHDownloadModel *)downloadModel error:(NSError *)error {
    NSInteger index = [self fetchDownloadModelWithFileUrl:downloadModel.fileUrl];
    if (index == -1) {
        return;
    }
    if (downloadModel.downloadStatus == MHDownloadStatusDownloadComplete || downloadModel.downloadStatus == MHDownloadStatusDownloadCancel) {
        [self.itemArray removeObjectAtIndex:index];
        [self.tableView reloadData];
    } else {
        [self.itemArray replaceObjectAtIndex:index withObject:downloadModel];
        [self.tableView beginUpdates];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
}

- (NSInteger )fetchDownloadModelWithFileUrl:(NSString *)fileUrl {
    @synchronized(self.itemArray) {
        for (NSInteger i = 0; i < self.itemArray.count; i++) {
            MHDownloadModel *model = self.itemArray[i];
            if ([model.fileUrl isEqualToString:fileUrl]) {
                return i;
            }
        }
    }
    return -1;
}


- (NSMutableArray *)itemArray {
    if (!_itemArray) {
        _itemArray = [NSMutableArray array];
        
        MHDownloadModel *fileDownloadModel = [MHDownloadModel new];
        fileDownloadModel.fileUrl = kFileUrl;
        
        MHDownloadModel *gifDownloadModel = [MHDownloadModel new];
        gifDownloadModel.fileUrl = kGifUrl;
        
        MHDownloadModel *wmvDownloadModel = [MHDownloadModel new];
        wmvDownloadModel.fileUrl = KWMVUrl;
        
        [_itemArray addObjectsFromArray:@[fileDownloadModel, gifDownloadModel, wmvDownloadModel]];
    }
    return _itemArray;
}

@end













