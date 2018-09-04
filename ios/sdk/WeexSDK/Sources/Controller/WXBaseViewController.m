/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#import "WXBaseViewController.h"
#import "WXRootViewController.h"
#import "WXSDKInstance.h"
#import "WXSDKInstance_private.h"
#import "WXSDKEngine.h"
#import "WXSDKManager.h"
#import "WXUtility.h"
#import "WXPrerenderManager.h"
#import "WXMonitor.h"

@interface WXBaseViewController ()


@property (nonatomic, strong) UIView *weexView;
@property (nonatomic, strong) NSURL *sourceURL;
    @property (nonatomic, strong) NSDictionary *data;
@end

@implementation WXBaseViewController

- (void)dealloc
{
    [_instance destroyInstance];
    [self _removeObservers];
}

- (instancetype)initWithSourceURL:(NSURL *)sourceURL :(NSDictionary *)data
{
    if ((self = [super init])) {
        self.sourceURL = sourceURL;
        self.hidesBottomBarWhenPushed = YES;
        self.data = data;
        
        [self _addObservers];
    }
    return self;
}

/**
 *  After setting the navbar hidden status , this function will be called automatically. In this function, we
 *  set the height of mainView equal to screen height, because there is something wrong with the layout of
 *  page content.
 */

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if ([self.navigationController isKindOfClass:[WXRootViewController class]]) {
        CGRect frame = self.view.frame;
        frame.origin.y = 0;
        frame.size.height = [UIScreen mainScreen].bounds.size.height;
        self.view.frame = frame;
    }    
}

/**
 *  We assume that the initial state of viewController's navigtionBar is hidden.  By setting the attribute of
 *  'dataRole' equal to 'navbar', the navigationBar hidden will be NO.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *statusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [self getStatusBarHeight])];
    statusView.backgroundColor = [self colorWithHexString:@"#4E7FFF" alpha:1.0f];
    [self.view addSubview:statusView];
    
    self.noticeView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+[self getStatusBarHeight], self.view.frame.size.width, self.view.frame.size.height-[self getStatusBarHeight])];
    //self.noticeView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.noticeView];
    
    //关闭按钮
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.noticeView.frame.size.width-70, 10, 60, 30)];
    [closeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    closeBtn.layer.cornerRadius = 5;
    closeBtn.layer.borderWidth = 1;
    closeBtn.layer.masksToBounds = YES;
    closeBtn.layer.borderColor = [UIColor blackColor].CGColor;
    [closeBtn addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.noticeView addSubview:closeBtn];
    
    self.noticeLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.noticeView.frame.size.width-60)/2, (self.noticeView.frame.size.height-100)/2, 100, 60)];
    [self.noticeLabel setFont:[UIFont systemFontOfSize:16]];
    [self.noticeLabel setText:@"加载中..."];
    [self.noticeView addSubview:self.noticeLabel];
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self _renderWithURL:_sourceURL];
    if ([self.navigationController isKindOfClass:[WXRootViewController class]]) {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self _updateInstanceState:WeexInstanceAppear];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self _updateInstanceState:WeexInstanceDisappear];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self _updateInstanceState:WeexInstanceMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshWeex
{
    [self _renderWithURL:_sourceURL];
}


- (void)addEdgePop
{
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)_renderWithURL:(NSURL *)sourceURL
{
    if (!sourceURL) {
        return;
    }
    
    [_instance destroyInstance];
    if([WXPrerenderManager isTaskReady:[self.sourceURL absoluteString]]){
        _instance = [WXPrerenderManager instanceFromUrl:self.sourceURL.absoluteString];
    }

    _instance = [[WXSDKInstance alloc] init];
    _instance.frame = CGRectMake(0.0f, [self getStatusBarHeight], self.view.bounds.size.width, self.view.bounds.size.height-[self getStatusBarHeight]);
    _instance.pageObject = self;
    _instance.pageName = sourceURL.absoluteString;
    _instance.viewController = self;
    
    NSString *newURL = nil;
    
    if ([sourceURL.absoluteString rangeOfString:@"?"].location != NSNotFound) {
        newURL = [NSString stringWithFormat:@"%@&random=%d", sourceURL.absoluteString, arc4random()];
    } else {
        newURL = [NSString stringWithFormat:@"%@?random=%d", sourceURL.absoluteString, arc4random()];
    }
    NSMutableDictionary *data;
    if(self.data)
    {
        data = [[NSMutableDictionary alloc] initWithDictionary:self.data];
    }
    else
    {
        data = [[NSMutableDictionary alloc] init];
    }
    [data setObject:sourceURL.absoluteString forKey:@"bundleUrl"];
    [_instance renderWithURL:[NSURL URLWithString:newURL] options:@{@"data":data} data:nil];
    
    __weak typeof(self) weakSelf = self;
    _instance.onCreate = ^(UIView *view) {
        weakSelf.noticeView.hidden = YES;
        [weakSelf.weexView removeFromSuperview];
        weakSelf.weexView = view;
        [weakSelf.view addSubview:weakSelf.weexView];
    };
    
    _instance.onFailed = ^(NSError *error) {
        
    };
    
    _instance.renderFinish = ^(UIView *view) {
        [weakSelf _updateInstanceState:WeexInstanceAppear];
    };
    
    if([WXPrerenderManager isTaskReady:[self.sourceURL absoluteString]]){
        WX_MONITOR_INSTANCE_PERF_START(WXPTJSDownload, _instance);
        WX_MONITOR_INSTANCE_PERF_END(WXPTJSDownload, _instance);
        WX_MONITOR_INSTANCE_PERF_START(WXPTFirstScreenRender, _instance);
        WX_MONITOR_INSTANCE_PERF_START(WXPTAllRender, _instance);
        [WXPrerenderManager renderFromCache:[self.sourceURL absoluteString]];
        return;
    }
}

- (void)_updateInstanceState:(WXState)state
{
    if (_instance && _instance.state != state) {
        _instance.state = state;
        
        if (state == WeexInstanceAppear) {
            [[WXSDKManager bridgeMgr] fireEvent:_instance.instanceId ref:WX_SDK_ROOT_REF type:@"viewappear" params:nil domChanges:nil];
        } else if (state == WeexInstanceDisappear) {
            [[WXSDKManager bridgeMgr] fireEvent:_instance.instanceId ref:WX_SDK_ROOT_REF type:@"viewdisappear" params:nil domChanges:nil];
        }
    }
}

- (void)_appStateDidChange:(NSNotification *)notify
{
    if ([notify.name isEqualToString:@"UIApplicationDidBecomeActiveNotification"]) {
        [self _updateInstanceState:WeexInstanceForeground];
    } else if([notify.name isEqualToString:@"UIApplicationDidEnterBackgroundNotification"]) {
        [self _updateInstanceState:WeexInstanceBackground]; ;
    }
}

- (void)_addObservers
{
    for (NSString *name in @[UIApplicationDidBecomeActiveNotification,
                             UIApplicationDidEnterBackgroundNotification]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_appStateDidChange:)
                                                     name:name
                                                   object:nil];
    }
}

-(void)close
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark 状态栏高度
-(CGFloat)getStatusBarHeight
{
    return [[UIApplication sharedApplication] statusBarFrame].size.height;
}

- (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha
{
    //删除字符串中的空格
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6)
    {
        return [UIColor clearColor];
    }
    // strip 0X if it appears
    //如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"0X"])
    {
        cString = [cString substringFromIndex:2];
    }
    //如果是#开头的，那么截取字符串，字符串从索引为1的位置开始，一直到末尾
    if ([cString hasPrefix:@"#"])
    {
        cString = [cString substringFromIndex:1];
    }
    if ([cString length] != 6)
    {
        return [UIColor clearColor];
    }
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    //r
    NSString *rString = [cString substringWithRange:range];
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    return [UIColor colorWithRed:((float)r / 255.0f) green:((float)g / 255.0f) blue:((float)b / 255.0f) alpha:alpha];
}

#pragma mark 设置Pop时回传的数据
-(void)setPopData:(NSDictionary *)dic
{
    if(_instance)
    {
        NSMutableDictionary *tempData = nil;
        if(dic)
        {
            tempData = [[NSMutableDictionary alloc]initWithDictionary:dic];
        }
        else
        {
            tempData = [[NSMutableDictionary alloc]init];
        }
        
        [tempData setObject:_instance.instanceId forKey:@"id"];
        [_instance fireGlobalEvent:@"longriseWeexBack" params:tempData];
    }
}

#pragma mark WEEX拉起UIViewController逆向传值
-(void)refresh:(NSDictionary *)params
{
    if(_instance)
    {
        NSMutableDictionary *tempData = nil;
        if(params)
        {
            tempData = [[NSMutableDictionary alloc]initWithDictionary:params];
        }
        else
        {
            tempData = [[NSMutableDictionary alloc]init];
        }
        
        [tempData setObject:_instance.instanceId forKey:@"id"];
        [_instance fireGlobalEvent:@"longriseWeexToActivityBack" params:tempData];
    }
}
- (void)_removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
