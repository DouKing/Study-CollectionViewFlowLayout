//
//  LVMCollectionViewWaterFlowLayout.h
//  DDCollectionViewFlowLayout
//
//  Created by WuYikai on 15/5/25.
//  Copyright (c) 2015年 secoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LVMCollectionViewWaterFlowLayout;
@protocol LVMCollectionViewDelegateWaterFlowLayout <UICollectionViewDelegateFlowLayout>

@required
/// 指定列数
- (NSInteger)lvm_collectionView:(UICollectionView *)collectionView
                         layout:(LVMCollectionViewWaterFlowLayout *)layout
       numberOfColumnsInSection:(NSInteger)section;

@end

@interface LVMCollectionViewWaterFlowLayout : UICollectionViewFlowLayout
@property (nonatomic, weak) id<LVMCollectionViewDelegateWaterFlowLayout> delegate;
@end
