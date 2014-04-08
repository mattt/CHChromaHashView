// CHChromaHashView.m
// 
// Copyright (c) 2014 Mattt Thompson
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "CHChromaHashView.h"

#import <CommonCrypto/CommonCrypto.h>

#ifndef _CHROMA_HASH_SALT_
#define _CHROMA_HASH_SALT_ (__DATE__ " " __TIME__)
#endif

static NSUInteger const CHDefaultNumberOfValues = 3;
static NSUInteger const CHMinimumCharacterThreshold = 6;

static NSArray * CHColorsFromDigestOfString(NSString *string) {
    if (!string || [string isEqualToString:@""]) {
        return @[];
    }

    uint8_t output[CC_SHA1_DIGEST_LENGTH];
    NSData *data = [[string stringByAppendingString:[NSString stringWithCString:(_CHROMA_HASH_SALT_) encoding:NSASCIIStringEncoding]] dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA1(data.bytes, data.length, output);

    NSMutableArray *mutableArray = [NSMutableArray array];
    NSUInteger offset = 0;
    while (offset + 3 < CC_SHA1_DIGEST_LENGTH) {
        unsigned char r = output[offset++];
        unsigned char g = output[offset++];
        unsigned char b = output[offset++];

        UIColor *color;
        if ([string length] < CHMinimumCharacterThreshold) {
            color = [UIColor colorWithWhite:(r / 255.0f) alpha:1.0f];
        } else {
            color = [UIColor colorWithRed:(r / 255.0f) green:(g / 255.0f) blue:(b / 255.0f) alpha:1.0];
        }

        [mutableArray addObject:color];
     }

    return [NSArray arrayWithArray:mutableArray];
}

@interface CHChromaHashView ()
@end

@implementation CHChromaHashView

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (void)commonInit {
    self.backgroundColor = [UIColor clearColor];

    self.numberOfValues = CHDefaultNumberOfValues;

    [(CAGradientLayer *)self.layer setStartPoint:CGPointMake(0.0f, 0.0f)];
    [(CAGradientLayer *)self.layer setEndPoint:CGPointMake(1.0f, 0.0f)];
}

- (void)awakeFromNib {
    [self commonInit];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    [self commonInit];

    return self;
}

- (void)setNumberOfValues:(NSUInteger)numberOfValues {
    _numberOfValues = numberOfValues;

    CGFloat step = 1.0f / numberOfValues;
    CGFloat const epsilon = 0.01f;
    NSMutableArray *mutableLocations = [NSMutableArray arrayWithCapacity:numberOfValues * 2];
    [mutableLocations addObject:@(0.0f)];
    for (CGFloat location = step; location < 1.0f; location += (step + epsilon)) {
        [mutableLocations addObject:@(location)];
        [mutableLocations addObject:@(location + epsilon)];
    }
    [mutableLocations addObject:@(1.0f)];

    [(CAGradientLayer *)self.layer setLocations:mutableLocations];
}

- (void)setTextInput:(UIControl <UITextInput> *)textInput {
    _textInput = textInput;

    [self.textInput addTarget:self action:@selector(update:) forControlEvents:UIControlEventEditingChanged];
}

#pragma mark - IBAction

- (IBAction)update:(id)sender {
    if (sender != self.textInput) {
        return;
    }

    NSString *text = [self.textInput textInRange:[self.textInput textRangeFromPosition:[self.textInput beginningOfDocument] toPosition:[self.textInput endOfDocument]]];

    NSArray *colors = CHColorsFromDigestOfString(text);
    NSMutableArray *mutableColors = [NSMutableArray arrayWithCapacity:[colors count] * 2];
    for (UIColor *color in colors) {
        [mutableColors addObjectsFromArray:@[(id)[color CGColor], (id)[color CGColor]]];
    }

    NSTimeInterval duration = self.animationDuration;
    [UIView animateWithDuration:duration animations:^{
        [CATransaction begin];
        {
            [CATransaction setAnimationDuration:duration];
            [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            [(CAGradientLayer *)self.layer setColors:mutableColors];
        }
        [CATransaction commit];
    }];
}

#pragma mark - CALayerDelegate

- (id <CAAction>)actionForLayer:(CALayer *)layer
                        forKey:(NSString *)event
{
    id <CAAction> action = [super actionForLayer:layer forKey:event];
    if ((!action || [(id)action isEqual:[NSNull null]]) && [event isEqualToString:@"colors"]) {
        action = [CABasicAnimation animationWithKeyPath:event];
    }

    return action;
}

@end
