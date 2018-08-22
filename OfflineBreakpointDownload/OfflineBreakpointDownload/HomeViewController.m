//
//  HomeViewController.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/21.
//  Copyright © 2018年 mason. All rights reserved.
//

#import "HomeViewController.h"
#import "ViewController.h"

@interface HomeViewController ()

/** <##> */
@property (strong, nonatomic) UIButton *btn;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.btn = btn;
    [self.view addSubview:btn];
    btn.frame = CGRectMake(100.f, 150.f, 100.f, 80.f);
    [btn setTitle:@"点击" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(nextPage) forControlEvents:UIControlEventTouchUpInside];
}

- (void)nextPage {
    ViewController *vc = [[UIStoryboard storyboardWithName:NSStringFromClass([ViewController class]) bundle:nil] instantiateInitialViewController];
    
    [self.navigationController pushViewController:vc animated:YES];
}


@end
