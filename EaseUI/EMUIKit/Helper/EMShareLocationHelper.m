//
//  EMShareLocationHelper.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 16/5/24.
//  Copyright © 2016年 WYZ. All rights reserved.
//

#import "EMShareLocationHelper.h"
#import <objc/runtime.h>

#import "EMLocationMap.h"
#import "EMSmallBall.h"

static char shareLocationIsValidKey;
static char shareLocationConversationKey;

/** @brief 待发送位置共享的CMD消息action */
#define KEMMESSAGE_SHARELOCATION                  @"em_shareLocation"
#define KEMMESSAGE_SHARELOCATION_STATUS           @"em_shareLocation_status"
//#define KEMMESSAGE_SHARELOCATION_COORDINATE       @"em_shareLocation_coordinate"


#define KEMMESSAGE_COORDINATE_LATITUDE            @"em_coordinate_latitude"
#define KEMMESSAGE_COORDINATE_LONGITUDE           @"em_coordinate_longitude"

#define KEMMESSAGE_SHARELOCATION_TIMEINTERVAL     5


@interface EMShareLocationHelper()<EMChatManagerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSNumber *isValid;

@property (nonatomic, strong) EMConversation *conversation;

@property (nonatomic, strong) NSValue *locationValue;

@property (nonatomic, strong) EMLocationMap *map;

@property (nonatomic, strong) EMSmallBall *ball;

@end

@implementation EMShareLocationHelper
{
    BOOL _isAllow;
    NSTimer *_timer;
    NSRunLoop *_runLoop;
    NSNumber *_latestTimestamp;
    long long _timestamp;
}


+ (EMShareLocationHelper *)defaultHelper {
    static EMShareLocationHelper *helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(){
        helper = [[EMShareLocationHelper alloc] init];
        
    });
    return helper;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isAllow = NO;
        [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
        _timestamp = -1;
    }
    return self;
}

- (void)dealloc {
    [[EMClient sharedClient].chatManager removeDelegate:self];
    _map = nil;
}

#pragma mark - EMChatManagerDelegate

- (void)didReceiveCmdMessages:(NSArray *)aCmdMessages {
    
    _locationValue = nil;
    __block EMMessage *_cmdMsg = nil;
    [aCmdMessages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[EMMessage class]]) {
            
            EMMessage *cmdMsg = (EMMessage *)obj;
            if ([EMShareLocationHelper isShareLocationCMDMessage:cmdMsg]) {
                _cmdMsg = cmdMsg;
                *stop = YES;
            }
        }
    }];
    
    if (_cmdMsg) {
        
        _locationValue = [self shareLocationHandleResult:_cmdMsg];
        if (!_locationValue) {
            return;
        }
        if (!_isAllow) {
            //alert保证只弹一次
            NSString *msg = [NSString stringWithFormat:@"%@向您发出了位置共享，是否同意？", _cmdMsg.from];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            [alertView show];
        }
    }
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        _isAllow = YES;
        if (self.shareDelegate && [self.shareDelegate respondsToSelector:@selector(emHelper:handleSharedLocation:)]) {
            
            CLLocationCoordinate2D coor;
            [_locationValue getValue:&coor];
            [self.shareDelegate emHelper:self handleSharedLocation:coor];
        }
    }
}

#pragma mark - getter

- (NSNumber *)isValid
{
    return objc_getAssociatedObject(self, &shareLocationIsValidKey);
}

- (EMConversation *)conversation
{
    return objc_getAssociatedObject(self, &shareLocationConversationKey);
}

#pragma mark - setter 

- (void)setIsValid:(NSNumber *)isValid
{
    objc_setAssociatedObject(self, &shareLocationIsValidKey, isValid, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setConversation:(EMConversation *)conversation
{
    objc_setAssociatedObject(self, &shareLocationConversationKey, conversation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - private

- (void)showMap {
    _map = [[EMLocationMap alloc] initWithParentVc:nil];
    _map.closeLocationSharing = ^(){
        EMShareLocationHelper *helper = [EMShareLocationHelper defaultHelper];
        if (helper.ball) {
            [helper.ball removeFromSuperview];
        }
        [EMShareLocationHelper closeShareLocation];
    };
    _map.updateUserLocation = ^(NSDictionary *annotationInfo) {
        long long currentTimestamp = (long long)[[NSDate date] timeIntervalSince1970];
        if (self->_timestamp < 0 || currentTimestamp - self->_timestamp > 5) {
            self->_timestamp = currentTimestamp;
            [[EMShareLocationHelper defaultHelper] sendShareLocationMessageWithLocation:nil status:YES];
        }
    };
    [_map show];
}

- (void)showSmallBall {
    _ball = [[EMSmallBall alloc] initWithAction:@selector(showLocationMapFull) target:[EMShareLocationHelper defaultHelper]];
    [_ball show];
}

//点击显示大地图
- (void)showLocationMapFull {
    if (_map) {
        [_map show];
    }
}

- (void)setIsAllow:(BOOL)isAllow {
    _isAllow = isAllow;
}


- (void)sendShareLocationMessageWithLocation:(CLLocation *)location status:(BOOL)isShare
{
    if (!location) {
        return;
    }
    NSMutableDictionary *ext = [NSMutableDictionary dictionary];
    [ext setObject:[NSNumber numberWithBool:isShare] forKey:KEMMESSAGE_SHARELOCATION_STATUS];
    if (isShare) {
        CLLocationCoordinate2D coordinate = location.coordinate;
        [ext setObject:[NSString stringWithFormat:@"%.16f",coordinate.latitude] forKey:KEMMESSAGE_COORDINATE_LATITUDE];
        [ext setObject:[NSString stringWithFormat:@"%.16f",coordinate.longitude] forKey:KEMMESSAGE_COORDINATE_LONGITUDE];
    }
//    
//    
//    NSValue *coordinateValue = [NSValue valueWithBytes:&coordinate objCType:@encode(CLLocationCoordinate2D)];
//    [ext setObject:coordinateValue forKey:KEMMESSAGE_SHARELOCATION_COORDINATE];
    
    EMCmdMessageBody *cmdBody = [[EMCmdMessageBody alloc] initWithAction:KEMMESSAGE_SHARELOCATION];
    EMMessage *cmdMessage = [[EMMessage alloc] initWithConversationID:self.conversation.conversationId from:[EMClient sharedClient].currentUsername to:self.conversation.conversationId body:cmdBody ext:ext];
    cmdMessage.chatType = EMChatTypeChat;
    
    [[EMClient sharedClient].chatManager asyncSendMessage:cmdMessage progress:nil completion:^(EMMessage *message, EMError *error) {
        
        NSLog(@"--- %@",error);
    }];
}

- (CLLocationCoordinate2D)coordinate2D:(NSDictionary *)ext
{
    CLLocationCoordinate2D coordinate2D;
    if (!ext[KEMMESSAGE_COORDINATE_LONGITUDE] || !ext[KEMMESSAGE_COORDINATE_LATITUDE]) {
        return coordinate2D;
    }
    
    coordinate2D = CLLocationCoordinate2DMake([ext[KEMMESSAGE_COORDINATE_LATITUDE] doubleValue], [ext[KEMMESSAGE_COORDINATE_LONGITUDE] doubleValue]);
    
    return coordinate2D;
}




#pragma mark - public

/**
 * 开启位置共享功能
 *
 */
+ (void)openShareLocation:(EMConversation *)conversation
{
    [[EMShareLocationHelper defaultHelper] setIsValid:[NSNumber numberWithBool:YES]];
    [[EMShareLocationHelper defaultHelper] setConversation:conversation];
    [[EMShareLocationHelper defaultHelper] setIsAllow:NO];
    [[EMShareLocationHelper defaultHelper] performSelector:@selector(showSmallBall) withObject:nil afterDelay:0.5];
    [[EMShareLocationHelper defaultHelper] performSelector:@selector(showMap) withObject:nil afterDelay:0.5];
}

/**
 * 关闭位置共享功能
 *
 */
+ (void)closeShareLocation
{
    if ([EMShareLocationHelper shareLocationIsValid])
    {
        [[EMShareLocationHelper defaultHelper] sendShareLocationMessageWithLocation:nil status:NO];
    }
    [[EMShareLocationHelper defaultHelper] setIsValid:[NSNumber numberWithBool:NO]];
    [[EMShareLocationHelper defaultHelper] setConversation:nil];
    [[EMShareLocationHelper defaultHelper] setIsAllow:NO];
}

/**
 * 位置共享功能是否可用
 *
 * @return 判断结果, YES代表输入状态提示功能可用
 */
+ (BOOL)shareLocationIsValid
{
    return [[EMShareLocationHelper defaultHelper].isValid boolValue];
}

/**
 * 恢复位置共享功能视图
 *
 * @return 判断结果, YES代表位置共享功能可用
 */
+ (void)resumeLocationsharingView {
    [[EMShareLocationHelper defaultHelper] showLocationMapFull];
}


+ (BOOL)isShareLocationCMDMessage:(EMMessage *)message
{
    if (![message.body isKindOfClass:[EMCmdMessageBody class]])
    {
        return NO;
    }
    EMCmdMessageBody *body = (EMCmdMessageBody *)message.body;
    if (!body)
    {
        return NO;
    }
    return [body.action isEqualToString:KEMMESSAGE_SHARELOCATION];
}

//处理接收到输入状态cmd消息
- (NSValue *)shareLocationHandleResult:(EMMessage *)cmdMessage
{
    if (![EMShareLocationHelper isShareLocationCMDMessage:cmdMessage])
    {
        return nil;
    }
    if (![(NSNumber *)cmdMessage.ext[KEMMESSAGE_SHARELOCATION_STATUS] boolValue])
    {
        return nil;
    }
    CLLocationCoordinate2D coordinate = [self coordinate2D:cmdMessage.ext];
    if (CLLocationCoordinate2DIsValid(coordinate))
    {
        NSValue *value = [NSValue valueWithBytes:&coordinate objCType:@encode(CLLocationCoordinate2D)];
        return value;
    }
    
    return nil;
}

#pragma mark - 定时

//接收方，启动runloop
- (void)startRunLoop
{
    [self stopRunLoop];
    if (![EMShareLocationHelper shareLocationIsValid])
    {
        return;
    }
    if (!_runLoop)
    {
        _runLoop = [[NSRunLoop alloc] init];
    }
    
    if (!_timer)
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:KEMMESSAGE_SHARELOCATION_TIMEINTERVAL target:self selector:@selector(handleTimerAction:) userInfo:nil repeats:NO];
    }
    [_runLoop addTimer:_timer forMode:NSRunLoopCommonModes];
    [_runLoop run];
}

//关闭runloop
- (void)stopRunLoop
{
    if (_timer.isValid)
    {
        [_timer invalidate];
        _timer = nil;
        _runLoop = nil;
    }
}

//定时处理方法
- (void)handleTimerAction:(NSTimer *)timer
{
    //规定时间内接收方没有收到输入状态通知
    [self stopRunLoop];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.shareDelegate && [weakSelf.shareDelegate respondsToSelector:@selector(cancelSharedLocation)]) {
            [weakSelf.shareDelegate cancelSharedLocation];
        }
    });
}










@end
