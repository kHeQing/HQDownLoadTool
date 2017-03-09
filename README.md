# HQDownLoadTool
基于NSURLSession的大文件下载器,支持断点下载,下载进度等

```
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HQDownLoaderState) {
    /** 下载暂停 */
    HQDownLoaderStatePause,
    /** 正在下载 */
    HQDownLoaderStateDowning,
    /** 已经下载 */
    HQDownLoaderStateSuccess,
    /** 下载失败 */
    HQDownLoaderStateFailed
};

typedef void(^DownLoadStateChange)(HQDownLoaderState downLoaderState);
typedef void(^DownLoadMessage)(long long totalSize, NSString *downLoadedPath);
typedef void(^DownLoadPrograssChange)(float progress);
typedef void(^DownLoadSuccess)(NSString *downLoadedPath);
typedef void(^DownLoadFailed)(NSString *errorMsg);


@interface HQDownLoader : NSObject

@property (nonatomic, assign, readonly) HQDownLoaderState downLoaderState;

@property (nonatomic, copy) DownLoadStateChange stateChangeBlock;
@property (nonatomic, copy) DownLoadMessage messageBlock;
@property (nonatomic, copy) DownLoadPrograssChange progressBlock;
@property (nonatomic, copy) DownLoadSuccess sucessBlock;
@property (nonatomic, copy) DownLoadFailed failedBlock;


/**
 根据url地址下载

 @param url url地址
 */
- (void)downLoadWithURL:(NSURL *)url;
- (void)downLoadWithURL:(NSURL *)url messageBlock:(DownLoadMessage)messageBlock progress:(DownLoadPrograssChange)progressBlock success:(DownLoadSuccess)succcessBlock failed:(DownLoadFailed)failedBlock;


- (void)cancel;

- (void)pause;

- (void)resume;

- (void)cancelAndClean;

@end
```

### 支持CocoaPods  

**Podfile**

```
platform :ios, '9.0'
pod 'HQDownLoadTool.podspec'
```