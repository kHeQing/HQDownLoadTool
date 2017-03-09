//
//  HQFileTool.m
//  HQDownLoadTool
//
//  Created by zfwlxt on 17/3/6.
//  Copyright © 2017年 何晴. All rights reserved.
//

#import "HQFileTool.h"

@implementation HQFileTool

+ (BOOL)createDirectoryIfNotExists:(NSString *)path {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        NSError *error;
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)fileExistsAtPath:(NSString *)path {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    return [manager fileExistsAtPath:path];
}

+ (long long)fileSizeAtPath:(NSString *)path {
    
    if (![self fileExistsAtPath:path]){
        return 0;
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDictionary *fileInfoDic = [manager attributesOfItemAtPath:path error:nil];
    
    return [fileInfoDic[NSFileSize] longLongValue];
}

+ (void)removeFileAtPath:(NSString *)path{
    
    if (![self fileExistsAtPath:path]) {
        return;
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:path error:nil];
}

+ (void)moveFileFromPath:(NSString *)fromPath toPath:(NSString *)toPath{

    if (![self fileExistsAtPath:fromPath]) {
        return;
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager moveItemAtPath:fromPath toPath:toPath error:nil];
}

@end
