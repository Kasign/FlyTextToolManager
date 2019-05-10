//
//  FlyTextView.m
//  FlyTextToolManager+Demo
//
//  Created by Fly on 2019/5/10.
//  Copyright © 2019 Fly. All rights reserved.
//

#import "FlyTextView.h"

@interface FlyTextView ()<UITextViewDelegate>

@property (nonatomic, copy) NSString   *   oldText;
@property (nonatomic, copy) NSString   *   replaceText;
@property (nonatomic, assign) NSRange      replaceRange;

@end

@implementation FlyTextView

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
    }
    return self;
}

- (void)setText:(NSString *)text {
    
    NSString * oldText = self.text;
    [super setText:text];
    if (![oldText isEqualToString:text]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
    }
}

- (NSString *)text {
    
    if (![super text]) {
        return [[super attributedText] string];
    }
    return [super text];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    
    NSAttributedString * oldAttri = self.attributedText;
    [super setAttributedText:attributedText];
    if (![oldAttri isEqualToAttributedString:attributedText]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
    }
}

- (NSRange)markedRang {
    
    UITextPosition  * beginning   = self.beginningOfDocument;
    UITextRange     * markedRang  = self.markedTextRange;
    UITextPosition  * markedStart = markedRang.start;
    UITextPosition  * markedEnd   = markedRang.end;
    NSInteger location = [self offsetFromPosition:beginning   toPosition:markedStart];
    NSInteger length   = [self offsetFromPosition:markedStart toPosition:markedEnd];
    return NSMakeRange(location, length);
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    BOOL result = YES;
    if ([self canResponseDelegate:@selector(fly_textViewShouldBeginEditing:)]) {
        result = [_fly_delegate fly_textViewShouldBeginEditing:self];
    }
    return result;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    
    BOOL result = YES;
    if ([self canResponseDelegate:@selector(fly_textViewShouldEndEditing:)]) {
        result = [_fly_delegate fly_textViewShouldEndEditing:self];
    }
    return result;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    BOOL result  = YES;
    _replaceText = text;
    if (!textView.markedTextRange) {
        _replaceRange = range;
        _oldText = textView.text;
    }
    return result;
}

- (void)textViewDidChange:(UITextView *)textView {
    
    if (!self.markedTextRange) {
        
        NSRange replaceRange   = _replaceRange;
        NSString * replaceText = _replaceText;
        //9的系统在字母转换到汉字的时候会少调用shouldChangeTextInRange，此处做特殊处理
        if ([UIDevice currentDevice].systemVersion.floatValue < 10.0) {
            NSInteger subCount      = textView.text.length - _oldText.length;
            NSInteger rangeLength   = _replaceRange.length;
            rangeLength   = MAX(0, rangeLength + subCount);
            NSInteger rangeLocation = _replaceRange.location;
            rangeLocation = MIN(textView.text.length - rangeLength, rangeLocation);
            NSRange didReplaceRange = NSMakeRange(rangeLocation, rangeLength);
            replaceText = [textView.text substringWithRange:didReplaceRange];
            _replaceRange = NSMakeRange(textView.text.length, 0);
            _oldText = textView.text;
        }

        //将限制的字符处理掉
        if (_isLimitEmoji) {
//            replaceText = [replaceText stringByRemoveEmoji];
        }
        
        if ([self canResponseDelegate:@selector(fly_textViewWillChange:replaceText:inRange:)]) {
            [_fly_delegate fly_textViewWillChange:self replaceText:replaceText inRange:replaceRange];
        }
    }
}


- (void)setMarkAttriDic:(NSDictionary *)markAttriDic {
    
    _markAttriDic = markAttriDic;
    if ([markAttriDic isKindOfClass:[NSDictionary class]]) {
        [self setMarkedTextStyle:markAttriDic];//不生效
    }
}

- (BOOL)canResponseDelegate:(SEL)sele {
    
    if ([_fly_delegate conformsToProtocol:@protocol(FlyTextViewDelegate)] && [_fly_delegate respondsToSelector:sele]) {
        return YES;
    }
    return NO;
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    
    if ([self canResponseDelegate:@selector(fly_textViewDidChangeSelection:selectedRange:)]) {
        [self.fly_delegate fly_textViewDidChangeSelection:self selectedRange:textView.selectedRange];
    }
}

- (void)dealloc {
    
    NSLog(@"--*-%@ dealloc-*--" , [self class]);
}

@end
