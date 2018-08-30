//
//  MHFileDatabase.m
//  OfflineBreakpointDownload
//
//  Created by mason on 2018/8/28.
//  Copyright © 2018年 mason. All rights reserved.
//

#import "MHFileDatabase.h"
#import <FMDB.h>
#import "MHUtil.h"

/*
 表的正常操作：
 1.创建表：主键序列，文件名称，文件路径，总大小，已经下载大小（可选），下载状态（正在下载，暂停）
 2.开始下载时，获取到文件总大小，名称，更新表数据：下载状态为正在下载
 3.暂停 > 更新表数据：当前下载了多少，下载状态改成：暂停
 4.取消下载 > 删除该条数据
 5.下载完成 > 删除该条数据
 
 应用被杀掉
 1.检查是否有下载队列
 2.对于处于下载状态的队列，自动启动
 3.处于暂停及其它情况的队列，依然保持原本的情况
 */

@interface MHFileDatabase()

/** <##> */
@property (strong, nonatomic) FMDatabaseQueue *databaseQueue;

@end

@implementation MHFileDatabase

+ (instancetype)shareInstance {
    static MHFileDatabase *fileDatabase;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fileDatabase = [MHFileDatabase new];
        NSString *sqliteName = [NSString stringWithFormat:@"%@.sqlite", NSStringFromClass([self class])];
        NSString *fileName = [MHUtil cacheDocumentPathWithFileName:sqliteName];
        NSLog(@"fileName : %@", fileName);
        fileDatabase.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:fileName];
    });
    return fileDatabase;
}

/**
 只执行一次，
 */
- (BOOL)createTable {
    __block BOOL result = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[MHFileDatabase shareInstance].databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            result = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS download_file (file_id integer PRIMARY KEY AUTOINCREMENT, file_name text NOT NULL, file_path text NOT NULL, file_total_size integer, file_download_size integer, download_status integer);"];
            if (result) {
                NSLog(@"创建表成功");
            }
        }];
    });
    return result;
}

- (BOOL)insertFileWithFileName:(NSString *)fileName
                      filePath:(NSString *)filePath
                 fileTotalSize:(NSInteger)fileTotalSize {
    __block BOOL result = NO;
    [[MHFileDatabase shareInstance].databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db executeUpdateWithFormat:@"insert into download_file (file_name, file_path, file_total_size, download_status) values (%@,%@,%ld,%d);", fileName, filePath, (long)fileTotalSize, 0];
    }];
    return result;
}

- (BOOL)updateDownloadStatusWithFileName:(NSString *)fileName
                          downloadStatus:(MHDownloadStatus )downloadStatus {
    __block BOOL result = NO;
    [[MHFileDatabase shareInstance].databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db executeUpdateWithFormat:@"update download_file set download_status = %ld where file_name = %@;", (long)downloadStatus, fileName];
    }];
    return result;
}

- (BOOL)updateDownloadFileTotalSizeWithFileName:(NSString *)fileName
                                 downloadStatus:(MHDownloadStatus)downloadStatus
                                  fileTotalSize:(NSInteger)fileTotalSize {
    __block BOOL result = NO;
    [[MHFileDatabase shareInstance].databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db executeUpdateWithFormat:@"update download_file set file_total_size = %ld,download_status = %ld where file_name = %@;", (long)fileTotalSize, downloadStatus, fileName];
    }];
    return result;
}

- (BOOL)updateDownloadFileCurrentSizeWithFileName:(NSString *)fileName
                                  fileCurrentSize:(NSInteger)fileCurrentSize {
    __block BOOL result = NO;
    [[MHFileDatabase shareInstance].databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db executeUpdateWithFormat:@"update download_file set file_download_size = %ld where file_name = %@;", (long)fileCurrentSize, fileName];
    }];
    return result;
}

- (BOOL)deleteFileWithFileName:(NSString *)fileName {
    __block BOOL result = NO;
    [[MHFileDatabase shareInstance].databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db executeUpdateWithFormat:@"delete from download_file where file_name=%@;", fileName];
    }];
    return result;
}

- (MHDownloadModel *)queryModelWitFileName:(NSString *)fileName {
    return [self queryWithFileName:fileName].firstObject;
}

- (NSArray *)queryAllDownloading {
    return [self queryWithFileName:@""];
}

- (NSArray *)queryWithFileName:(NSString *)fileName {
    __block FMResultSet *results;
    __block NSMutableArray *list = [NSMutableArray array];
    [[MHFileDatabase shareInstance].databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if (fileName && fileName.length > 0) {
            results = [db executeQueryWithFormat:@"select * from download_file where file_name=%@;", fileName];
        } else {
            results = [db executeQueryWithFormat:@"select * from download_file"];
        }
    }];
    while ([results  next]) {
        MHDownloadModel *downloadModel = [MHDownloadModel new];
        downloadModel.fileName = [results objectForColumn:@"file_name"];
        downloadModel.totalSize = [results doubleForColumn:@"file_total_size"];
        //直接根据路径查询文件是否存在：1.存在：a: 获取大小是否对于总大小 b.不一致，说明为下载完，一直则直接删除数据库中该条数据
        //2.不存在：启用下载
        if ([MHUtil isFileExist:downloadModel.fileName]) {
            NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:[MHUtil cacheDocumentPathWithFileName:downloadModel.fileName] error:nil];
            NSInteger currentSize = [dic[@"NSFileSize"] integerValue];
            if (currentSize >= downloadModel.totalSize) {
                //删除该条数据
                [self deleteFileWithFileName:downloadModel.fileName];
                continue;
            }
            downloadModel.currentSize = currentSize;
        }
        downloadModel.filePath = [results objectForColumn:@"file_path"];
        downloadModel.downloadStatus = [results intForColumn:@"download_status"];
        [list addObject:downloadModel];
    }
    return list;
}


@end















