//
//  MHHomeViewController.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/21.
//  Copyright © 2018年 mason. All rights reserved.
//

#import "MHHomeViewController.h"
#import "ViewController.h"

static NSString *const kDownloadCellIdentifier = @"kDownloadCellIdentifier";

@interface MHHomeViewController ()
<
UITableViewDelegate,
UITableViewDataSource
>

/** <##> */
@property (strong, nonatomic) UIButton *btn;

/** <##> */
@property (strong, nonatomic) UITableView *tableView;
/** <##> */
@property (strong, nonatomic) NSArray *itemArray;


@end

@implementation MHHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupView];
}

- (void)setupView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView = tableView;
    [self.view addSubview:tableView];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kDownloadCellIdentifier];
    tableView.tableFooterView = [UIView new];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.itemArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDownloadCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDownloadCellIdentifier];
    }
    NSDictionary *dic = self.itemArray[indexPath.row];
    cell.textLabel.text = dic[@"title"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dic = self.itemArray[indexPath.row];
    NSString *cleassName = dic[@"vc"];
    if ([dic[@"title"] isEqualToString:@"下载测试"]) {
        UIViewController *vc = [[UIStoryboard storyboardWithName:cleassName bundle:nil] instantiateInitialViewController];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [self.navigationController pushViewController:[[NSClassFromString(cleassName) alloc] init] animated:YES];
    }
}

- (void)nextPage {
    ViewController *vc = [[UIStoryboard storyboardWithName:NSStringFromClass([ViewController class]) bundle:nil] instantiateInitialViewController];
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSArray *)itemArray {
    if (!_itemArray) {
        _itemArray = @[@{@"vc" : @"ViewController",
                         @"title" : @"下载测试"},
                        @{@"vc" : @"MHSingleOperationViewController",
                         @"title" : @"单任务下载"}];
    }
    return _itemArray;
}


@end
