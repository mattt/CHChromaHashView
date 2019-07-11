// CHChromaHashView.m
//
// Copyright (c) 2014 Mattt (https://mat.tt/)
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

static NSArray *CHColorsFromDigestOfString(NSString *string) {
  if (!string || [string isEqualToString:@""]) {
    return @[];
  }

  uint8_t output[CC_SHA256_DIGEST_LENGTH];
  NSData *data = [[string
      stringByAppendingString:[NSString
                                  stringWithCString:(_CHROMA_HASH_SALT_)
                                           encoding:NSASCIIStringEncoding]]
      dataUsingEncoding:NSUTF8StringEncoding];
  CC_SHA256(data.bytes, (CC_LONG)data.length, output);

  NSMutableArray *mutableArray = [NSMutableArray array];
  NSUInteger offset = 0;
  while (offset + 3 < CC_SHA256_DIGEST_LENGTH) {
    unsigned char r = output[offset++];
    unsigned char g = output[offset++];
    unsigned char b = output[offset++];

    UIColor *color = nil;
    if ([string length] < CHMinimumCharacterThreshold) {
      color = [UIColor colorWithWhite:(r / 255.0f) alpha:1.0f];
    } else {
      color = [UIColor colorWithRed:(r / 255.0f)
                              green:(g / 255.0f)
                               blue:(b / 255.0f)
                              alpha:1.0];
    }

    [mutableArray addObject:color];
  }

  return [NSArray arrayWithArray:mutableArray];
}

@interface CHChromaHashView ()
@property (readonly) CAGradientLayer *gradientLayer;
@end

@implementation CHChromaHashView

+ (Class)layerClass {
  return [CAGradientLayer class];
}

- (CAGradientLayer *)gradientLayer {
    return (CAGradientLayer *)self.layer;
}

- (void)commonInit {
  self.backgroundColor = [UIColor clearColor];

  self.numberOfValues = CHDefaultNumberOfValues;

  [self.gradientLayer setStartPoint:CGPointMake(0.0f, 0.0f)];
  [self.gradientLayer setEndPoint:CGPointMake(1.0f, 0.0f)];
}

- (void)awakeFromNib {
    [super awakeFromNib];
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
  NSMutableArray *mutableLocations =
      [NSMutableArray arrayWithCapacity:numberOfValues * 2];
  [mutableLocations addObject:@(0.0f)];
  for (CGFloat location = step; location < 1.0f; location += (step + epsilon)) {
    [mutableLocations addObject:@(location)];
    [mutableLocations addObject:@(location + epsilon)];
  }
  [mutableLocations addObject:@(1.0f)];

  [self.gradientLayer setLocations:mutableLocations];
}

- (void)setTextInput:(UIControl<UITextInput> *)textInput {
  _textInput = textInput;

  [self.textInput addTarget:self
                     action:@selector(update:)
           forControlEvents:UIControlEventEditingChanged];
}

#pragma mark - IBAction

- (IBAction)update:(id)sender {
  if (sender != self.textInput) {
    return;
  }

  NSString *text = [self.textInput
      textInRange:[self.textInput
                      textRangeFromPosition:[self.textInput beginningOfDocument]
                                 toPosition:[self.textInput endOfDocument]]];

  NSArray *colors = CHColorsFromDigestOfString(text);
  NSMutableArray *mutableColors =
      [NSMutableArray arrayWithCapacity:[colors count] * 2];
  for (UIColor *color in colors) {
    [mutableColors
        addObjectsFromArray:@[ (id)[color CGColor], (id)[color CGColor] ]];
  }

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"colors"];
    animation.duration = self.animationDuration;
    animation.removedOnCompletion = YES;
    animation.fillMode = kCAFillModeForwards;
    [self.gradientLayer addAnimation:animation forKey:nil];

    [self.gradientLayer setColors:mutableColors];
}

@end
