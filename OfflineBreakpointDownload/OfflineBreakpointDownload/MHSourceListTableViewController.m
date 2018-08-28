//
//  MHSourceListTableViewController.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/28.
//  Copyright © 2018年 mason. All rights reserved.
//

#import "MHSourceListTableViewController.h"


#define kFileUrl @"http://7qnbrb.com1.z0.glb.clouddn.com/video.mp4"
#define kGifUrl @"http://7qnbrb.com1.z0.glb.clouddn.com/scrollviewNest.gif"
#define KWMVUrl @"http://7qnbrb.com1.z0.glb.clouddn.com/1102.wmv"

@interface MHSourceListTableViewController ()

/** <##> */
@property (strong, nonatomic) NSMutableArray *dataSource;

@end

@implementation MHSourceListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    self.tableView.tableFooterView = [UIView new];
}


#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    MHDownloadModel *downloadModel = self.dataSource[indexPath.row];
    cell.textLabel.text = downloadModel.filePath.lastPathComponent;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MHDownloadModel *downloadModel = self.dataSource[indexPath.row];
    if ([self.delegate respondsToSelector:@selector(didSelecteDownloadModel:)]) {
        [self.delegate didSelecteDownloadModel:downloadModel];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
        
        MHDownloadModel *fileDownloadModel = [MHDownloadModel new];
        fileDownloadModel.filePath = kFileUrl;
        
        MHDownloadModel *gifDownloadModel = [MHDownloadModel new];
        gifDownloadModel.filePath = kGifUrl;
        
        MHDownloadModel *wmvDownloadModel = [MHDownloadModel new];
        wmvDownloadModel.filePath = KWMVUrl;
        
        [_dataSource addObjectsFromArray:@[fileDownloadModel, gifDownloadModel, wmvDownloadModel]];
    }
    return _dataSource;
}

@end
