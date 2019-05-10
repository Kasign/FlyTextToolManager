//
//  FlyTextView.h
//  FlyTextToolManager+Demo
//
//  Created by Fly on 2019/5/10.
//  Copyright © 2019 Fly. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FlyTextView;
@protocol FlyTextViewDelegate <NSObject>

@optional

- (BOOL)fly_textViewShouldEndEditing:(FlyTextView *)textView;
- (BOOL)fly_textViewShouldBeginEditing:(FlyTextView *)textView;
- (void)fly_textViewWillChange:(FlyTextView *)textView replaceText:(NSString *)text inRange:(NSRange)range;
- (void)fly_textViewDidChange:(FlyTextView *)textView text:(NSString *)text;
- (void)fly_textViewDidChangeSelection:(FlyTextView *)textView selectedRange:(NSRange)selectedRange;

@end

@interface FlyTextView : UITextView

@property (nonatomic, weak)   id<FlyTextViewDelegate> fly_delegate;
@property (nonatomic, assign) BOOL isLimitEmoji;
@property (nonatomic, strong) NSDictionary   *   markAttriDic;

@end

NS_ASSUME_NONNULL_END
