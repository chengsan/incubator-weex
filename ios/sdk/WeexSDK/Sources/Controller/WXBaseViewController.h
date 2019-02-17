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

#import <UIKit/UIKit.h>
#import "WXSDKInstance.h"

typedef void (^LongriseWeexPopBlock)(id result);

@interface WXBaseViewController : UIViewController

@property (nonatomic, retain) WXSDKInstance *instance;
@property(nonatomic,retain)UIView *noticeView;
@property(nonatomic,retain)UILabel *noticeLabel;
@property(nonatomic,copy)LongriseWeexPopBlock block;
@property(nonatomic,retain)UIButton *refreshBtn;
@property(nonatomic,assign)BOOL isDebugMode;//是否调试模式


- (instancetype)initWithSourceURL:(NSURL *)sourceURL :(NSDictionary *)data;

- (void)refreshWeex;

#pragma mark WEEX和WEEX的逆向传值设值方法
-(void)setPopData:(NSDictionary *)dic;
#pragma mark WEEX拉起UIViewController逆向传值
-(void)refresh:(NSDictionary *)params;


@end
