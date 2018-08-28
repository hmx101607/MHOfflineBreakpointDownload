//
//  MHUtil.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/28.
//  Copyright © 2018年 mason. All rights reserved.
//

#import "MHUtil.h"

@implementation MHUtil

+ (BOOL)isFileExist:(NSString *)fileName {
    NSString*filePath =[self cacheDocumentPathWithFileName:fileName];
    BOOL fileExists=[[NSFileManager defaultManager] fileExistsAtPath:filePath];
    return fileExists;
}

+ (NSString *)cacheDocumentPathWithFileName:(NSString *)fileName {
    NSArray* paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = paths.firstObject;
    fileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString* filePath =[path stringByAppendingPathComponent:fileName];
    return filePath;
}

@end
