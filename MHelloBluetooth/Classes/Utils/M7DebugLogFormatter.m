//
//  M7LogFormatter.m
//  CicaeroEntertainment
//
//  Created by thatsoul on 15/7/11.
//  Copyright (c) 2015年 cicaero. All rights reserved.
//

#import "M7DebugLogFormatter.h"

@interface M7DebugLogFormatter () {
    NSInteger _loggerCount;
}
@property (nonatomic) NSDateFormatter *threadUnsafeDateFormatter;
@end

@implementation M7DebugLogFormatter

- (id)init {
    if((self = [super init])) {
        _threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
        [_threadUnsafeDateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
    }
    return self;
}

#pragma mark - DDLogFormatter
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    return [NSString stringWithFormat:@"[Log] %@ %@ \n%@:[%lu]", [self.threadUnsafeDateFormatter stringFromDate:logMessage.timestamp], logMessage.message, logMessage.function, (unsigned long)logMessage.line];
}
- (void)didAddToLogger:(id <DDLogger>)logger {
    _loggerCount++;
    NSAssert(_loggerCount <= 1, @"This logger isn't thread-safe");
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    _loggerCount--;
}

@end
