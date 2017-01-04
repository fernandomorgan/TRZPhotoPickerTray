//
//  NSIndexSet+TRZPhotoPickerTray.m
//  TRZPhotoPickerTray
//
//  Created by Fernando Pereira on 1/3/17.
//  Copyright © 2017 Troezen. All rights reserved.
//

#import "NSIndexSet+TRZPhotoPickerTray.h"

@implementation NSIndexSet (TRZPhotoPickerTray)

- (nonnull NSArray*) arrayOfNSIndexPathInSection:(NSUInteger)section
{
    NSMutableArray* arr = [NSMutableArray new];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:idx inSection:section];
        [arr addObject:indexPath];
    }];
    return arr.copy;
}

@end
