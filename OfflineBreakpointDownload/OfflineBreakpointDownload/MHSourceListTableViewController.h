//
//  MHSourceListTableViewController.h
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/28.
//  Copyright © 2018年 mason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MHDownloadModel.h"

@protocol MHSourceListTableViewControllerDelegate<NSObject>

- (void)didSelecteDownloadModel:(MHDownloadModel *)downloadModel;

@end

@interface MHSourceListTableViewController : UITableViewController

@property (weak, nonatomic) id<MHSourceListTableViewControllerDelegate>delegate;

@end
