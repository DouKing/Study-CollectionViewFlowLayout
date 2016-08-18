//
//  STMDynamicFlowLayout.h
//  Study-CollectionViewDynamic
//
//  Created by WuYikai on 16/8/18.
//  Copyright © 2016年 secoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface STMDynamicFlowLayout : UICollectionViewFlowLayout
@property (nonatomic, assign) CGFloat springDamping;
@property (nonatomic, assign) CGFloat springFrequency;
@property (nonatomic, assign) CGFloat resistanceFactor;
@end
