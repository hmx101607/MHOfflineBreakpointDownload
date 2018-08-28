//
//  MHUtil.h
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/28.
//  Copyright © 2018年 mason. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MHUtil : NSObject


/**
 文件是否存在

 @param fileName 文件名
 @return 放回结果
 */
+ (BOOL)isFileExist:(NSString *)fileName;


/**
 缓存的路径

 @param fileName 文件名
 @return 路径
 */
+ (NSString *)cacheDocumentPathWithFileName:(NSString *)fileName;

@end
