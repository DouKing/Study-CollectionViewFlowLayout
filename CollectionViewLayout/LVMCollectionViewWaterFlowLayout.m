//
//  LVMCollectionViewWaterFlowLayout.m
//  DDCollectionViewFlowLayout
//
//  Created by WuYikai on 15/5/25.
//  Copyright (c) 2015年 secoo. All rights reserved.
//

#import "LVMCollectionViewWaterFlowLayout.h"

@interface LVMCollectionViewWaterFlowLayout () {
  NSMutableArray      *_lvm_sectionRects;
  NSMutableArray			*_lvm_columnRectsInSection;
  
  NSMutableArray			*_lvm_layoutItemAttributes;
  NSDictionary        *_lvm_headerFooterItemAttributes;
}

@end

@implementation LVMCollectionViewWaterFlowLayout

- (CGSize)collectionViewContentSize {
  [super collectionViewContentSize];
  
  CGRect lastSectionRect = [[_lvm_sectionRects lastObject] CGRectValue];
  CGSize lastsize = CGSizeMake(CGRectGetWidth(self.collectionView.frame),CGRectGetMaxY(lastSectionRect));
  return lastsize;
}

- (void)prepareLayout {
  NSUInteger numberOfSections = self.collectionView.numberOfSections;
  _lvm_sectionRects = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
  _lvm_columnRectsInSection = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
  _lvm_layoutItemAttributes = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
  _lvm_headerFooterItemAttributes = @{UICollectionElementKindSectionHeader:[NSMutableArray array], UICollectionElementKindSectionFooter:[NSMutableArray array]};
  
  for (NSUInteger section = 0; section < numberOfSections; ++section) {
    NSUInteger itemsInSection = [self.collectionView numberOfItemsInSection:section];
    [_lvm_layoutItemAttributes addObject:[NSMutableArray array]];
    [self _lvm_prepareSectionLayout:section withNumberOfItems:itemsInSection];
  }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind
                                                                     atIndexPath:(NSIndexPath *)indexPath {
  return _lvm_headerFooterItemAttributes[kind][indexPath.section];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
  return _lvm_layoutItemAttributes[indexPath.section][indexPath.item];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)visibleRect {
  return [self _lvm_searchVisibleLayoutAttributesInRect:visibleRect];
}

#pragma mark - Pravite Methods
- (void)_lvm_prepareSectionLayout:(NSUInteger)section withNumberOfItems:(NSUInteger)numberOfItems {
  UICollectionView *cView = self.collectionView;
  UIEdgeInsets sectionInsets = self.sectionInset;
  if([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]){
    sectionInsets = [self.delegate collectionView:cView layout:self insetForSectionAtIndex:section];
  }
  
  CGFloat lineSpacing = self.minimumLineSpacing;
  CGFloat interitemSpacing = self.minimumInteritemSpacing;
  if([self.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]){
    interitemSpacing = [self.delegate collectionView:cView layout:self minimumInteritemSpacingForSectionAtIndex:section];
  }
  if([self.delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]){
    lineSpacing = [self.delegate collectionView:cView layout:self minimumLineSpacingForSectionAtIndex:section];
  }
  
  NSIndexPath *sectionPath = [NSIndexPath indexPathForItem:0 inSection:section];
  
  // #1: Define the rect of the section
  CGRect previousSectionRect = [self _lvm_rectForSectionAtIndex:section - 1];
  CGRect sectionRect;
  sectionRect.origin.x = sectionInsets.left;
  sectionRect.origin.y = CGRectGetMaxY(previousSectionRect)+sectionInsets.top;
  
  NSUInteger numberOfColumns = [self.delegate lvm_collectionView:cView layout:self numberOfColumnsInSection:section];
  sectionRect.size.width = CGRectGetWidth(cView.frame) - (sectionInsets.left + sectionInsets.right);
  
  CGFloat columnSpace = sectionRect.size.width - (interitemSpacing * (numberOfColumns-1));
  CGFloat columnWidth = (columnSpace/numberOfColumns);
  
  // store space for each column
  [_lvm_columnRectsInSection addObject:[NSMutableArray arrayWithCapacity:numberOfColumns]];
  for (NSUInteger colIdx = 0; colIdx < numberOfColumns; ++colIdx)
    [_lvm_columnRectsInSection[section] addObject:[NSMutableArray array]];
  
  // #2: Define the rect of the header
  CGRect headerFrame;
  headerFrame.origin = sectionRect.origin;
  headerFrame.origin.x = 0.0f;
  headerFrame.size.width = cView.contentSize.width;
  headerFrame.size.height = 0.0f;
  
  if([self.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]){
    CGSize headerSize = [self.delegate collectionView:cView layout:self referenceSizeForHeaderInSection:section];
    headerFrame.size.height = headerSize.height;
    headerFrame.size.width = headerSize.width;
  }
  
  UICollectionViewLayoutAttributes *headerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:sectionPath];
  headerAttributes.frame = headerFrame;
  [_lvm_headerFooterItemAttributes[UICollectionElementKindSectionHeader] addObject:headerAttributes];
  
  // add headerAttributes to layoutItemAttributes arrays
  if (headerFrame.size.height > 0)
    [_lvm_layoutItemAttributes[section] addObject:headerAttributes];
  
  // #3: Define the rect of the of each item
  for (NSInteger itemIdx = 0; itemIdx < numberOfItems; ++itemIdx) {
    NSIndexPath *itemPath = [NSIndexPath indexPathForItem:itemIdx inSection:section];
    CGSize itemSize = [self.delegate collectionView:cView layout:self sizeForItemAtIndexPath:itemPath];
    
    NSInteger destColumnIdx = [self _lvm_preferredColumnIndexInSection:section];
    NSInteger destRowInColumn = [self _lvm_numberOfItemsInColumn:destColumnIdx ofSection:section];
    CGFloat lastItemInColumnOffset = [self _lvm_lastItemOffsetInColumn:destColumnIdx inSection:section];
    
    CGRect itemRect;
    itemRect.origin.x = sectionRect.origin.x + destColumnIdx * (interitemSpacing + columnWidth);
    itemRect.origin.y = lastItemInColumnOffset + (destRowInColumn > 0 ? lineSpacing: 0.0f);
    itemRect.size.width = columnWidth;
    itemRect.size.height = itemSize.height;
    
    UICollectionViewLayoutAttributes *itemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:itemPath];
    itemAttributes.frame = itemRect;
    [_lvm_layoutItemAttributes[section] addObject:itemAttributes];
    [_lvm_columnRectsInSection[section][destColumnIdx] addObject:[NSValue valueWithCGRect:itemRect]];
  }
  
  // #3 Define the rect of the footer
  CGRect footerFrame;
  footerFrame.origin.x = headerFrame.origin.x;
  footerFrame.origin.y = [self _lvm_heightOfItemsInSection:section] + lineSpacing;
  footerFrame.size.width = headerFrame.size.width;
  footerFrame.size.height = 0.0f;
  
  if([self.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)]){
    CGSize footerSize = [self.delegate collectionView:cView layout:self referenceSizeForFooterInSection:section];
    footerFrame.size.height = footerSize.height;
    footerFrame.size.width = footerSize.width;
  }
  
  UICollectionViewLayoutAttributes *footerAttributes = [UICollectionViewLayoutAttributes
                                                        layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                        withIndexPath:sectionPath];
  footerAttributes.frame = footerFrame;
  [_lvm_headerFooterItemAttributes[UICollectionElementKindSectionFooter] addObject:footerAttributes];
  
  // add headerAttributes to layoutItemAttributes arrays.
  if (footerFrame.size.height)
    [_lvm_layoutItemAttributes[section] addObject:footerAttributes];
  
  sectionRect.size.height = (CGRectGetMaxY(footerFrame) - CGRectGetMinY(headerFrame)) + sectionInsets.bottom;
  [_lvm_sectionRects addObject:[NSValue valueWithCGRect:sectionRect]];
}

- (CGFloat)_lvm_heightOfItemsInSection:(NSUInteger)sectionIdx {
  CGFloat maxHeightBetweenColumns = 0.0f;
  NSArray *columnsInSection = _lvm_columnRectsInSection[sectionIdx];
  for (NSUInteger columnIdx = 0; columnIdx < columnsInSection.count; ++columnIdx) {
    CGFloat heightOfColumn = [self _lvm_lastItemOffsetInColumn:columnIdx inSection:sectionIdx];
    maxHeightBetweenColumns = MAX(maxHeightBetweenColumns,heightOfColumn);
  }
  return maxHeightBetweenColumns;
}

- (NSInteger)_lvm_numberOfItemsInColumn:(NSInteger)columnIdx ofSection:(NSInteger)sectionIdx {
  return [_lvm_columnRectsInSection[sectionIdx][columnIdx] count];
}

- (CGFloat)_lvm_lastItemOffsetInColumn:(NSInteger)columnIdx inSection:(NSInteger)sectionIdx {
  NSArray *itemsInColumn = _lvm_columnRectsInSection[sectionIdx][columnIdx];
  if (itemsInColumn.count == 0) {
    CGRect headerFrame = [_lvm_headerFooterItemAttributes[UICollectionElementKindSectionHeader][sectionIdx] frame];
    return CGRectGetMaxY(headerFrame);
  } else {
    CGRect lastItemRect = [[itemsInColumn lastObject] CGRectValue];
    return CGRectGetMaxY(lastItemRect);
  }
}

- (NSInteger)_lvm_preferredColumnIndexInSection:(NSInteger)sectionIdx {
  NSUInteger shortestColumnIdx = 0;
  CGFloat heightOfShortestColumn = CGFLOAT_MAX;
  for (NSUInteger columnIdx = 0; columnIdx < [_lvm_columnRectsInSection[sectionIdx] count]; ++columnIdx) {
    CGFloat columnHeight = [self _lvm_lastItemOffsetInColumn:columnIdx inSection:sectionIdx];
    if (columnHeight < heightOfShortestColumn) {
      shortestColumnIdx = columnIdx;
      heightOfShortestColumn = columnHeight;
    }
  }
  return shortestColumnIdx;
}

- (CGRect)_lvm_rectForSectionAtIndex:(NSInteger)sectionIdx {
  if (sectionIdx < 0 || sectionIdx >= _lvm_sectionRects.count)
    return CGRectZero;
  return [_lvm_sectionRects[sectionIdx] CGRectValue];
}

- (NSArray *)_lvm_searchVisibleLayoutAttributesInRect:(CGRect)visibleRect {
  NSMutableArray *itemAttrs = [[NSMutableArray alloc] init];
  NSIndexSet *visibleSections = [self _lvm_sectionIndexesInRect:visibleRect];
  [visibleSections enumerateIndexesUsingBlock:^(NSUInteger sectionIdx, BOOL *stop) {
    for (UICollectionViewLayoutAttributes *itemAttr in _lvm_layoutItemAttributes[sectionIdx]) {
      CGRect itemRect = itemAttr.frame;
      BOOL isVisible = CGRectIntersectsRect(visibleRect, itemRect);
      if (isVisible)
        [itemAttrs addObject:itemAttr];
    }
  }];
  return itemAttrs;
}

- (NSIndexSet *)_lvm_sectionIndexesInRect:(CGRect)aRect {
  CGRect theRect = aRect;
  NSMutableIndexSet *visibleIndexes = [[NSMutableIndexSet alloc] init];
  NSUInteger numberOfSections = self.collectionView.numberOfSections;
  for (NSUInteger sectionIdx = 0; sectionIdx < numberOfSections; ++sectionIdx) {
    CGRect sectionRect = [_lvm_sectionRects[sectionIdx] CGRectValue];
    BOOL isVisible = CGRectIntersectsRect(theRect, sectionRect);
    if (isVisible)
      [visibleIndexes addIndex:sectionIdx];
  }
  return visibleIndexes;
}

@end
