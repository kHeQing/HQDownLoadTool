//
//  ViewController.m
//  HQDownLoadTool
//
//  Created by zfwlxt on 17/3/6.
//  Copyright © 2017年 何晴. All rights reserved.
//

#import "ViewController.h"
#import "HQDownLoader.h"

@interface ViewController ()

@property (nonatomic, strong) HQDownLoader *downLoader;

@property (nonatomic, weak) NSTimer *timer;

@end

@implementation ViewController

- (NSTimer *)timer
{
    if (!_timer) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(update) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}

- (HQDownLoader *)downLoader
{
    if (!_downLoader) {
        _downLoader = [HQDownLoader new];
    }
    return _downLoader;
}

- (IBAction)downLoad:(id)sender {
    
    NSURL *url = [NSURL URLWithString:@"http://free2.macx.cn:8281/tools/photo/Sip44.dmg"];
    [self.downLoader downLoadWithURL:url messageBlock:^(long long totalSize, NSString *downLoadedPath) {
        
        NSLog(@"开始下载--%@--%lld",downLoadedPath,totalSize);
        
    } progress:^(float progress) {
        
        NSLog(@"下载中--%f",progress);
        
    } success:^(NSString *downLoadedPath) {
        
        NSLog(@"完成--%@",downLoadedPath);
        
    } failed:^(NSString *errorMsg) {
        
        NSLog(@"失败--%@",errorMsg);
        
    }];
}

- (IBAction)pause:(id)sender {
    [self.downLoader pause];
}

- (IBAction)resume:(id)sender {
    [self.downLoader resume];
}

- (IBAction)cancel:(id)sender {
    [self.downLoader cancel];
}



- (void)viewDidLoad {
    [super viewDidLoad];
  
    [self timer];
}

- (void)update {
    
//        NSLog(@"%zd", self.downLoader.downLoaderState);
    
}


@end
