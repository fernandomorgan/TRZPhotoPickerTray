//
//  TRZShutterControl.m
//  TRZPhotoPickerTray
//
//  Created by Fernando Pereira on 1/4/17.
//  Copyright © 2017 Troezen. All rights reserved.
//

#import "TRZShutterControl.h"

@interface TRZShutterControl ()

@property (nonatomic) CALayer* bezel;
@property (nonatomic) CALayer* button;

@end

@implementation TRZShutterControl

- (instancetype) initWithFrame:(CGRect)frame
{
    if ( self = [super initWithFrame:frame] ) {
        _bezel = [[CALayer alloc] init];
        _bezel.masksToBounds = YES;
        _bezel.borderColor = [UIColor whiteColor].CGColor;
        _bezel.borderWidth = 2.0;
        [self.layer addSublayer:_bezel];
        
        _button = [[CALayer alloc] init];
        _button.masksToBounds = YES;
        _button.backgroundColor = [UIColor whiteColor].CGColor;
        [self.layer addSublayer:_button];
    }
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    self.bezel.frame = self.bounds;
    self.bezel.cornerRadius = CGRectGetWidth(self.bounds) / 2;
    
    CGFloat buttonInset = self.bezel.borderWidth + 1.5;
    self.button.frame = CGRectInset(self.bounds, buttonInset, buttonInset);
    self.button.cornerRadius = CGRectGetHeight(self.button.bounds) / 2;
}

- (void) setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.button.backgroundColor = (highlighted ? [UIColor lightGrayColor].CGColor : [UIColor whiteColor].CGColor);
}

@end
