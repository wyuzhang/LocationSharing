//
//  EMSmallBall.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 16/8/24.
//  Copyright © 2016年 WYZ. All rights reserved.
//

#import "EMSmallBall.h"

@implementation EMSmallBall

- (instancetype)initWithAction:(SEL)action target:(id)target {
    self = [super initWithFrame:CGRectMake(0, 0, 60, 60)];
    if (self) {
        
        [self addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        self.layer.cornerRadius = self.frame.size.width / 2.0;
        self.backgroundColor = [UIColor orangeColor];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self setTitle:@"放大" forState:UIControlStateNormal];
    }
    return self;
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGRect frame = self.frame;
    frame.origin.y = window.bounds.size.height / 2.0;
    frame.origin.x = window.bounds.size.width - 20 - frame.size.width;
    self.frame = frame;
    self.transform = CGAffineTransformMakeScale(0, 0);
    if (![window.subviews containsObject:self]) {
        [window addSubview:self];
        [window bringSubviewToFront:self];
    }
    [UIView animateWithDuration:0.25f delay:0.15 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [self AddAniamtionLikeGameCenterBubble];
    }];
}

//----类似GameCenter的气泡晃动动画------
-(void)AddAniamtionLikeGameCenterBubble{
    
    
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.calculationMode = kCAAnimationPaced;
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.removedOnCompletion = NO;
    pathAnimation.repeatCount = INFINITY;
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    pathAnimation.duration = 5.0;
    
    
    CGMutablePathRef curvedPath = CGPathCreateMutable();
    CGRect circleContainer = CGRectInset(self.frame, self.bounds.size.width / 2 - 10, self.bounds.size.width / 2 - 10);
    
    CGPathAddEllipseInRect(curvedPath, NULL, circleContainer);
    
    pathAnimation.path = curvedPath;
    CGPathRelease(curvedPath);
    [self.layer addAnimation:pathAnimation forKey:@"myCircleAnimation"];
    
    
    CAKeyframeAnimation *scaleX = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
    scaleX.duration = 1;
    scaleX.values = @[@1.0, @1.1, @1.0];
    scaleX.keyTimes = @[@0.0, @0.5, @1.0];
    scaleX.repeatCount = INFINITY;
    scaleX.autoreverses = YES;
    
    scaleX.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.layer addAnimation:scaleX forKey:@"scaleXAnimation"];
    
    
    CAKeyframeAnimation *scaleY = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
    scaleY.duration = 1.5;
    scaleY.values = @[@1.0, @1.1, @1.0];
    scaleY.keyTimes = @[@0.0, @0.5, @1.0];
    scaleY.repeatCount = INFINITY;
    scaleY.autoreverses = YES;
    scaleX.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.layer addAnimation:scaleY forKey:@"scaleYAnimation"];
}


@end
