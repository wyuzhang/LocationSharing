//
//  EMLocationMap.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 16/8/24.
//  Copyright © 2016年 WYZ. All rights reserved.
//

#import "EMLocationMap.h"
#import <MapKit/MapKit.h>


@interface EMLocationMap()<MKMapViewDelegate>

@property (nonatomic, strong) UIViewController *parentVC;

@property (nonatomic, strong) MKMapView *mapView;

@end


//该模型是大头针模型 所以必须实现协议MKAnnotation协议 和CLLocationCoordinate2D中的属性coordinate
@interface EMShareAnnotation : NSObject<MKAnnotation>

- (instancetype)initWithDic:(NSDictionary *)dic;

- (NSDictionary *)annotationToDic;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

//@property (nonatomic, copy) NSString *nickname;

@property (nonatomic, copy) NSString *avarterUrl;

//@property (nonatomic, copy) NSString *address;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *subtitle;

@end

@implementation EMLocationMap
{
    EMShareAnnotation *_annotation;
    EMShareAnnotation *_aa;
    MKCoordinateSpan _span;
}

- (instancetype)initWithParentVc:(UIViewController *)parentVC {
    self = [super init];
    if (self) {
        _parentVC = parentVC;
        [self setupMapView];
    }
    return self;
}

- (void)setupMapView {
    
    CGRect frame = self.window.bounds;
    frame.origin.y = -frame.size.height;
    self.frame = frame;
    self.backgroundColor = [UIColor orangeColor];
    
    //搞个地图
    _mapView = [[MKMapView alloc] initWithFrame:self.window.bounds];
    _mapView.showsUserLocation = YES;
    _mapView.zoomEnabled = YES;
    _mapView.scrollEnabled=YES;
    _mapView.pitchEnabled = YES;
    _mapView.rotateEnabled = YES;
    // 标注地图类型
    _mapView.mapType = MKMapTypeStandard ;
    //用于将当前视图控制器赋值给地图视图的delegate属性
    _mapView.delegate = self ;
    [self addSubview:_mapView];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(20, 20, 50, 50);
    [closeBtn setImage:[UIImage imageNamed:@"close_shareLocation"] forState:UIControlStateNormal];
    [closeBtn setImage:[UIImage imageNamed:@"close_shareLocation"] forState:UIControlStateHighlighted];
    [closeBtn addTarget:self action:@selector(closeLocationMapAction) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *hideBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    hideBtn.frame = CGRectMake(frame.size.width - 50 - 20, 20, 50, 50);
    [hideBtn setImage:[UIImage imageNamed:@"hiden_shareLocation"] forState:UIControlStateNormal];
    [hideBtn setImage:[UIImage imageNamed:@"hiden_shareLocation"] forState:UIControlStateHighlighted];
    [hideBtn addTarget:self action:@selector(hidenLocationMapAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:closeBtn];
    [self addSubview:hideBtn];
//    [self bringSubviewToFront:closeBtn];
}

- (UIWindow *)window {
    return [UIApplication sharedApplication].keyWindow;
}

#pragma mark - public method

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (![window.subviews containsObject:self]) {
        [window addSubview:self];
        [window bringSubviewToFront:self];
    }
    [UIView animateWithDuration:0.25f delay:0.15 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect frame = self.frame;
        frame.origin.y = 0;
        self.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)closeMap {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.25f animations:^{
        CGRect frame = weakSelf.frame;
        frame.origin.y = -weakSelf.frame.size.height;
        weakSelf.frame = frame;
    } completion:^(BOOL finished) {
        if (finished) {
            [weakSelf removeFromSuperview];
        }
    }];
}

- (void)hidenMap {
    [UIView animateWithDuration:0.25f animations:^{
        CGRect frame = self.frame;
        frame.origin.y = -self.frame.size.height;
        self.frame = frame;
    } completion:^(BOOL finished) {
        if (finished) {
            [self removeFromSuperview];
        }
    }];
}


- (void)updateAnnotation:(EMShareAnnotation *)annotation {
    if (_annotation == nil) {
        _annotation = annotation;
        MKCoordinateRegion region = MKCoordinateRegionMake(annotation.coordinate, MKCoordinateSpanMake(0.01, 0.01));
        [_mapView setRegion:[_mapView regionThatFits:region] animated:YES];
    }
    else{
        [_mapView removeAnnotation:_annotation];
    }
//    _annotation.avarterUrl = @"http://article.fd.zol-img.com.cn/t_s500x2000/g5/M00/02/09/ChMkJ1ehnwyIQGORAAHWDVwGFX8AAUHnQJWjccAAdYl309.jpg";
    [_mapView addAnnotation:_annotation];
}

#pragma mark - action

- (void)closeLocationMapAction {
    if (self.closeLocationSharing) {
        self.closeLocationSharing();
    }
    [self closeMap];
}

- (void)hidenLocationMapAction {
    [self hidenMap];
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    __weak typeof(self) weakSelf = self;
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:userLocation.location completionHandler:^(NSArray *array, NSError *error) {
        if (!error && array.count > 0) {
            CLPlacemark *placemark = [array objectAtIndex:0];
            NSDictionary *addressDictionary = placemark.addressDictionary;
            NSString *street = addressDictionary[@"Street"];
            NSRange range = [street rangeOfString:@"座"];
            if (range.length > 0) {
                street = [street substringToIndex:range.location + range.length];
            }
            EMShareAnnotation *annotation = [[EMShareAnnotation alloc] init];
            annotation.subtitle = street;
            annotation.title = [EMClient sharedClient].currentUsername;
            annotation.coordinate = userLocation.coordinate;
            annotation.avarterUrl = @"http://article.fd.zol-img.com.cn/t_s500x2000/g5/M00/02/09/ChMkJ1ehnwyIQGORAAHWDVwGFX8AAUHnQJWjccAAdYl309.jpg";
            [weakSelf updateAnnotation:annotation];
            if (weakSelf.updateUserLocation) {
                weakSelf.updateUserLocation([annotation annotationToDic]);
            }
        }
    }];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    static NSString* annoId = @"EMShareAnnotation";
    MKAnnotationView* annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:annoId];
    if (!annotationView) {
        annotationView = [[MKAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:annoId];
    }
    if (![annotation isKindOfClass:[MKUserLocation class]]) {
        EMShareAnnotation *shareAnnotation = (EMShareAnnotation *)annotation;
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:shareAnnotation.avarterUrl]];
        UIImage *image = [UIImage imageWithData:data];
        annotationView.image = [self circleImage:image size:CGSizeMake(40, 40)];
        annotationView.canShowCallout = YES;
    }
    return  annotationView;
}


- (UIImage *)circleImage:(UIImage *)img size:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 0.5);
    CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGContextAddArc(context, size.width / 2, size.height / 2, size.width / 2.0, 0, 2 * M_PI, 0);
    CGContextClip(context);
    
    [img drawInRect:rect];
    CGContextAddArc(context, size.width / 2, size.height / 2, size.width / 2.0, 0, 2 * M_PI, 0);
    CGContextStrokePath(context);
    UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newimg;
}

@end



@implementation EMShareAnnotation


- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (instancetype)initWithDic:(NSDictionary *)dic {
    self = [super init];
    if (self) {
        if (dic[@"latitude"] && dic[@"longitude"]) {
            _coordinate = CLLocationCoordinate2DMake([dic[@"latitude"] doubleValue], [dic[@"longitude"] doubleValue]);
            if (dic[@"title"]) {
                _title = dic[@"title"];
            }
            if (dic[@"subtitle"]) {
                _subtitle = dic[@"subtitle"];
            }
        }
    }
    return self;
}

- (NSDictionary *)annotationToDic {
    NSMutableDictionary *returnDic = [NSMutableDictionary dictionary];
    if (self.title.length > 0) {
        [returnDic setObject:self.title forKey:@"title"];
    }
    if (self.subtitle.length > 0) {
        [returnDic setObject:self.subtitle forKey:@"subtitle"];
    }
    [returnDic setObject:[NSString stringWithFormat:@"%.16f",self.coordinate.latitude] forKey:@"latitude"];
    [returnDic setObject:[NSString stringWithFormat:@"%.16f",self.coordinate.longitude] forKey:@"longitude"];
    
    if (returnDic.allKeys.count > 0) {
        return returnDic;
    }
    return nil;
}

@end

