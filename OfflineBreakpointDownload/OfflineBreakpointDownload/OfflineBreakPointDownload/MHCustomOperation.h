//
//  MHCustomOperation.h
//  Module-Common
//
//  Created by mason on 2018/8/2.
//

#import <Foundation/Foundation.h>

typedef NSURLSessionTask *(^sessionBlock) (void);

@interface MHCustomOperation : NSOperation

+ (instancetype)operationWithURLSessionTask:(NSURLSessionTask*)task
                               sessionBlock:(sessionBlock)sessionBlock;

@end
