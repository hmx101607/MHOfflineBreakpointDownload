//
//  MHCustomOperation.m
//  Module-Common
//
//  Created by mason on 2018/8/2.
//

#import "MHCustomOperation.h"

@interface MHCustomOperation()
{
    BOOL executing;
    BOOL finished;
}

/** <##> */
@property (strong, nonatomic) NSURLSessionTask *task;
/** <##> */
@property (assign, nonatomic) BOOL isObserving;
/** <##> */
@property (copy, nonatomic) sessionBlock sessionBlock;

@end

@implementation MHCustomOperation


+ (instancetype)operationWithURLSessionTask:(NSURLSessionTask *)task sessionBlock:(sessionBlock)sessionBlock {
    MHCustomOperation *operation = [MHCustomOperation new];
    operation.sessionBlock = sessionBlock;
    return operation;
}

//添加进队列，会自动调用
- (void)start {
    
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
}

- (void)main {
    @try {
        NSLog(@"%s+++++++++++ : thread : %@", __func__, [NSThread currentThread]);
        //开启监听状态
        [self startObservingTask];
        //启动任务
        if (!self.task) {
            self.task = self.sessionBlock();
        }
        [self.task resume];
    }
    @catch (NSException *e) {
        [self stopObservingTask];
        [self completeOperation];
    }
}

- (void)startObservingTask {
    @synchronized(self){
        if (_isObserving) {
            return;
        }
        if (!self.task) {
            self.task = self.sessionBlock();
        }
        [self.task addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
        _isObserving = YES;
    }
}

- (void)stopObservingTask {
    @synchronized(self){
        if (!_isObserving) {
            return;
        }
        if (!self.task) {
            self.task = self.sessionBlock();
        }
        [self.task removeObserver:self forKeyPath:@"state"];
        _isObserving = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (!self.task) {
        self.task = self.sessionBlock();
    }
    if (self.task.state == NSURLSessionTaskStateCanceling || self.task.state == NSURLSessionTaskStateCompleted) {
        [self stopObservingTask];
        [self completeOperation];
    }
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    executing = NO;
    finished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isFinished {
    return finished;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isAsynchronous {
    return YES;
}

@end
