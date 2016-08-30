//
//  EMShareLocationHelper.h
//  ChatDemo-UI3.0
//
//  Created by WYZ on 16/5/24.
//  Copyright © 2016年 WYZ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMSDK.h"


@class EMShareLocationHelper;

@protocol EMShareLocationDelegate <NSObject>

@required

/**
 * 处理接收到的消息撤销cmd消息后回调
 * @param needRevokeMessags 待撤销的消息
 */
- (void)emHelper:(EMShareLocationHelper *)emHelper handleSharedLocation:(CLLocationCoordinate2D)locationCoordinate2D;

/**
 * 处理接收到的消息撤销cmd消息后回调
 * @param needRevokeMessags 待撤销的消息
 */
- (void)cancelSharedLocation;

@end

@interface EMShareLocationHelper : NSObject


@property (nonatomic, assign) id<EMShareLocationDelegate> shareDelegate;

+ (EMShareLocationHelper *)defaultHelper;

#pragma mark - private


#pragma mark - public

/**
 * 开启位置共享功能
 *
 */
+ (void)openShareLocation:(EMConversation *)conversation;

/**
 * 关闭位置共享功能
 *
 */
+ (void)closeShareLocation;

/**
 * 位置共享功能是否可用
 *
 * @return 判断结果, YES代表位置共享功能可用
 */
+ (BOOL)shareLocationIsValid;

/**
 * 恢复位置共享功能视图
 *
 * @return 判断结果, YES代表位置共享功能可用
 */
+ (void)resumeLocationsharingView;


/**
 * cmd消息是否为位置共享类型
 *
 * @return 判断结果, YES代表位置共享类型
 */
+ (BOOL)isShareLocationCMDMessage:(EMMessage *)message;

//处理接收到输入状态cmd消息
- (NSValue *)shareLocationHandleResult:(EMMessage *)cmdMessage;

@end
