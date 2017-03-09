//
//  HQDownLoader.m
//  HQDownLoadTool
//
//  Created by zfwlxt on 17/3/6.
//  Copyright © 2017年 何晴. All rights reserved.
//

#import "HQDownLoader.h"
#import "HQFileTool.h"

#define kCache NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject


@interface HQDownLoader()<NSURLSessionDataDelegate>
{
    long long _fileTmpSize;
    long long _totalSize;
}
@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, copy) NSString *downLoadedFilePath;
@property (nonatomic, copy) NSString *downLoadingFilePath;

@property (nonatomic, strong) NSOutputStream *outputStream;

@property (nonatomic, weak) NSURLSessionDataTask *tast;

@end

@implementation HQDownLoader

#pragma mark - 接口
- (void)downLoadWithURL:(NSURL *)url messageBlock:(DownLoadMessage)messageBlock progress:(DownLoadPrograssChange)progressBlock success:(DownLoadSuccess)succcessBlock failed:(DownLoadFailed)failedBlock{
    
    self.messageBlock = messageBlock;
    self.progressBlock = progressBlock;
    self.sucessBlock = succcessBlock;
    self.failedBlock = failedBlock;
    
    [self downLoadWithURL:url];
}


- (void)downLoadWithURL:(NSURL *)url {
    
    self.downLoadedFilePath = [self.downLoadedPath stringByAppendingPathComponent:url.lastPathComponent];
    self.downLoadingFilePath = [self.downLoadingPath stringByAppendingPathComponent:url.lastPathComponent];
    
    // 1.判断当前的url对应资源是否下载完毕,如果下载完毕直接返回
    if ([HQFileTool fileExistsAtPath:self.downLoadedFilePath]) {
        NSLog(@"当前资源已经下载完毕");
        return;
    }
    
    // 2.检测,本地有没有下载过临时缓存
    if (![HQFileTool fileExistsAtPath:self.downLoadingFilePath]) {
        [self downLoadWithURL:url offset:_fileTmpSize];
        return;
    }
    
    [self cancel];
    
    // 3.获取本地缓存的大小ls : 文件真正正确的总大小rs
    _fileTmpSize = [HQFileTool fileSizeAtPath:self.downLoadingFilePath];
    [self downLoadWithURL:url offset:_fileTmpSize];
    
}

- (void)cancel {
    
    [self.session invalidateAndCancel];
    self.session = nil;
}

- (void)resume {

    if ((self.tast && self.downLoaderState == HQDownLoaderStatePause) || self.downLoaderState == HQDownLoaderStateFailed) {
        [self.tast resume];
        self.downLoaderState = HQDownLoaderStateDowning;
    }
}

- (void)pause {

    if (self.downLoaderState == HQDownLoaderStateDowning) {
        [self.tast suspend];
        self.downLoaderState = HQDownLoaderStatePause;
    }
}

- (void)cancelAndClean {
    
    [self cancel];
    [HQFileTool removeFileAtPath:self.downLoadingFilePath];
}

#pragma mark - 私有方法
- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset {

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-",offset] forHTTPHeaderField:@"Range"];
    self.tast = [self.session dataTaskWithRequest:request];
    [self.tast resume];
    
}

#pragma mark - NSURLSessionDataDelegate
/**
 第一次接受到下载信息 相应头信息的时候调用

 @param session 会话
 @param dataTask 任务
 @param response 响应头
 @param completionHandler 系统回调,可以通过这个回调传递不同的参数,来决定是否需要接受后续的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {

    // "Content-Range" = "bytes 0-21574061/21574062";
    NSLog(@"%@",response);
    
    NSString *ranageStr = response.allHeaderFields[@"Content-Range"];
    _totalSize = [[ranageStr componentsSeparatedByString:@"/"].lastObject longLongValue];
    
    if (_fileTmpSize == _totalSize) {
        NSLog(@"下载完成,执行移动操作");
        [HQFileTool moveFileFromPath:self.downLoadingFilePath toPath:self.downLoadedFilePath];
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    if (_fileTmpSize > _totalSize) {
        NSLog(@"清除本地缓存,然后,从0开始下载,并且,取消本次请求");
        [HQFileTool removeFileAtPath:self.downLoadingFilePath];
        completionHandler(NSURLSessionResponseCancel);
        [self downLoadWithURL:response.URL];
        return;
    }
    
    // 创建文件输出流
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.downLoadingFilePath append:YES];
    [self.outputStream open];
    
    NSLog(@"继续接受数据");
    completionHandler(NSURLSessionResponseAllow);
    
}

/**
 如果是可以接受后续数据 那么在接受过程中,就会调用这个方法

 @param session 会话
 @param dataTask 任务
 @param data 接收到的数据,一段
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    NSLog(@"在接受数据");
    _fileTmpSize += data.length;
    
    if (self.progressBlock) {
        self.progressBlock(1.0 * _fileTmpSize / _totalSize);
    }
    
    [self.outputStream write:data.bytes maxLength:data.length];
    
}


/**
 请求完毕, != 下载完成

 @param session 会话
 @param task 任务
 @param error 任务
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {

    if (!error) {
        NSLog(@"本次请求完成");
        if (_fileTmpSize == _totalSize) {
            [HQFileTool moveFileFromPath:self.downLoadingFilePath toPath:self.downLoadedFilePath];
            self.downLoaderState = HQDownLoaderStateSuccess;
        }
    }else{
        
        self.downLoaderState = HQDownLoaderStateFailed;
        if (self.failedBlock) {
            self.failedBlock(error.localizedDescription);
        }
    }
    
}




#pragma mark - setter getter
- (NSURLSession *)session
{
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue new]];
    }
    return _session;
}

- (NSString *)downLoadingPath {
    
    NSString *path = [kCache stringByAppendingPathComponent:@"downLoader/downLoading"];
    
    BOOL result = [HQFileTool createDirectoryIfNotExists:path];
    if (result) {
        return path;
    }
    return @"";
    
}

- (NSString *)downLoadedPath {
    
    NSString *path = [kCache stringByAppendingPathComponent:@"downLoader/downloaded"];
    
    BOOL result = [HQFileTool createDirectoryIfNotExists:path];
    if (result) {
        return path;
    }
    return @"";
}

- (void)setDownLoaderState:(HQDownLoaderState)downLoaderState{
    
    _downLoaderState = downLoaderState;
    
    if (self.stateChangeBlock) {
        self.stateChangeBlock(_downLoaderState);
    }
}


@end
