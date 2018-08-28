//
//  MHSingleOperationViewController.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/24.
//  Copyright © 2018年 mason. All rights reserved.
//

#import "MHSingleOperationViewController.h"
#import "MHDownloadListItemTableViewCell.h"
#import "MHOfflineBreakPointDownloadManager.h"
#import "MHFileDatabase.h"
#import "MHSourceListTableViewController.h"

static NSString *const kDownloadCellIdentifier = @"kDownloadCellIdentifier";

@interface MHSingleOperationViewController ()
<
UITableViewDelegate,
UITableViewDataSource,
MHDownloadListItemTableViewCellDelegate,
MHOfflineBreakPointDownloadManagerDelegate,
MHSourceListTableViewControllerDelegate
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
    [MHOfflineBreakPointDownloadManager shareDownloadInstance].delegate = self;

    [self setupView];
    [self configRightNavigationBar];
    
    NSArray *list = [[MHFileDatabase shareInstance] queryAllDownloading];
    [list enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MHDownloadModel *downloadModel = obj;
        if (downloadModel.downloadStatus == MHDownloadStatusDownloading) {
            [[MHOfflineBreakPointDownloadManager shareDownloadInstance] addDownloadQueue:downloadModel.filePath];
        }
    }];
    [self.itemArray addObjectsFromArray:list];
    [self.tableView reloadData];
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

- (void)configRightNavigationBar {
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加文件" style:UIBarButtonItemStylePlain target:self action:@selector(clickAction:)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
}

- (void)clickAction:(UIButton *)sender {
    MHSourceListTableViewController *sourceListVC = [MHSourceListTableViewController new];
    sourceListVC.delegate = self;
    [self.navigationController pushViewController:sourceListVC animated:YES];

}

- (void)didSelecteDownloadModel:(MHDownloadModel *)downloadModel {
    __block BOOL exit = NO;
    [self.itemArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MHDownloadModel *model = obj;
        if ([model.filePath isEqualToString:downloadModel.filePath]) {
            exit = YES;
            *stop = YES;
        }
    }];
    if (!exit) {
        [self.itemArray addObject:downloadModel];
    }
    [self.tableView reloadData];
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
    [[MHOfflineBreakPointDownloadManager shareDownloadInstance] addDownloadQueue:downloadModel.filePath];
}

- (void)suspendDownloadWithDownloadModel:(MHDownloadModel *)downloadModel {
    [[MHOfflineBreakPointDownloadManager shareDownloadInstance] suspendDownLoadWithUrl:downloadModel.filePath];
}

- (void)cancelDownloadWithDownloadModel:(MHDownloadModel *)downloadModel {
    [[MHOfflineBreakPointDownloadManager shareDownloadInstance] cancelDownLoadWithUrl:downloadModel.filePath];
    NSInteger index = [self fetchDownloadModelWithFilePath:downloadModel.filePath];
    if (index == -1) {
        return;
    }
    [self.itemArray removeObjectAtIndex:index];
    [self.tableView reloadData];
}

#pragma mark - Delegate MHOfflineBreakPointDownloadHelperDelegate
- (void)downloadProgressWithDownloadModel:(MHDownloadModel *)downloadModel {
    NSInteger index = [self fetchDownloadModelWithFilePath:downloadModel.filePath];
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
    NSInteger index = [self fetchDownloadModelWithFilePath:downloadModel.filePath];
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

- (NSInteger )fetchDownloadModelWithFilePath:(NSString *)filePath {
    @synchronized(self.itemArray) {
        for (NSInteger i = 0; i < self.itemArray.count; i++) {
            MHDownloadModel *model = self.itemArray[i];
            if ([model.filePath isEqualToString:filePath]) {
                return i;
            }
        }
    }
    return -1;
}

- (NSMutableArray *)itemArray {
    if (!_itemArray) {
        _itemArray = [NSMutableArray array];
    }
    return _itemArray;
}

@end













