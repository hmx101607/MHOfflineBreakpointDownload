//
//  MHDownloadListItemTableViewCell.h
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/24.
//Copyright © 2018年 mason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MHOfflineBreakPointDownloadManager.h"

@protocol MHDownloadListItemTableViewCellDelegate<NSObject>

- (void)startDownloadWithDownloadModel:(MHDownloadModel *)downloadModel;
- (void)suspendDownloadWithDownloadModel:(MHDownloadModel *)downloadModel;
- (void)cancelDownloadWithDownloadModel:(MHDownloadModel *)downloadModel;

@end


@interface MHDownloadListItemTableViewCell : UITableViewCell

/** <##> */
@property (strong, nonatomic) MHDownloadModel *downloadModel;
@property (weak, nonatomic) id<MHDownloadListItemTableViewCellDelegate>delegate;


@end
