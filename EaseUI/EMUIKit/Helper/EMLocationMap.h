//
//  EMLocationMap.h
//  ChatDemo-UI3.0
//
//  Created by WYZ on 16/8/24.
//  Copyright © 2016年 WYZ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMLocationMap : UIView

@property (nonatomic, copy) void (^updateUserLocation)(NSDictionary *annotationInfo);

@property (nonatomic, copy) void (^closeLocationSharing)();

- (instancetype)initWithParentVc:(UIViewController *)parentVC;

- (void)show;

@end
