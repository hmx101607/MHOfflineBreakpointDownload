//
//  MHDownloadListItemTableViewCell.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/24.
//Copyright © 2018年 mason. All rights reserved.
//

#import "MHDownloadListItemTableViewCell.h"

@interface MHDownloadListItemTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *operationBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;


@end

@implementation MHDownloadListItemTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setDownloadModel:(MHDownloadModel *)downloadModel {
    _downloadModel = downloadModel;
    self.titleLabel.text = downloadModel.filePath.lastPathComponent;
    CGFloat progress = 0;
    if (downloadModel.totalSize != 0) {
        progress = downloadModel.currentSize*1.0 / downloadModel.totalSize * 1.0f;
    }
    self.progressView.progress = progress;
    self.progressLabel.textColor = [UIColor blackColor];
    switch (downloadModel.downloadStatus) {
        case MHDownloadStatusDownloadWait:
        {
            [self.operationBtn setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
            self.progressLabel.text = @"等待下载";
            break;
        }
        case MHDownloadStatusDownloadSuspend:
        {
            [self.operationBtn setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
            self.progressLabel.text = @"暂停";
            break;
        }
        case MHDownloadStatusDownloading:
        {
            [self.operationBtn setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
            self.progressLabel.text = [NSString stringWithFormat:@"正在下载：%.0f%%", progress*100];
            break;
        }
        case MHDownloadStatusDownloadComplete:
        {
            break;
        }
        case MHDownloadStatusDownloadFail:
        {
            [self.operationBtn setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
            self.progressLabel.text = @"失败";
            self.progressLabel.textColor = [UIColor redColor];
            break;
        }
        case MHDownloadStatusDownloadCancel:
        {
            break;
        }
    }
}


- (IBAction)operationAction:(id)sender {
    switch (self.downloadModel.downloadStatus) {
        case MHDownloadStatusDownloadWait:
        {
            [self.operationBtn setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
            if ([self.delegate respondsToSelector:@selector(startDownloadWithDownloadModel:)]) {
                [self.delegate startDownloadWithDownloadModel:self.downloadModel];
            }
            break;
        }
        case MHDownloadStatusDownloadSuspend:
        {
            [self.operationBtn setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
            if ([self.delegate respondsToSelector:@selector(startDownloadWithDownloadModel:)]) {
                [self.delegate startDownloadWithDownloadModel:self.downloadModel];
            }
            break;
        }
        case MHDownloadStatusDownloading:
        {
            [self.operationBtn setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
            if ([self.delegate respondsToSelector:@selector(suspendDownloadWithDownloadModel:)]) {
                [self.delegate suspendDownloadWithDownloadModel:self.downloadModel];
            }
            break;
        }
        case MHDownloadStatusDownloadComplete:
        {
            break;
        }
        case MHDownloadStatusDownloadFail:
        {
            [self.operationBtn setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
            if ([self.delegate respondsToSelector:@selector(startDownloadWithDownloadModel:)]) {
                [self.delegate startDownloadWithDownloadModel:self.downloadModel];
            }
            break;
        }
        case MHDownloadStatusDownloadCancel:
        {
            break;
        }
    }
    
}

- (IBAction)deleteAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cancelDownloadWithDownloadModel:)]) {
        [self.delegate cancelDownloadWithDownloadModel:self.downloadModel];
    }
    
}

@end
