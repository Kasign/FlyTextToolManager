//
//  ViewController.m
//  FlyTextToolManager+Demo
//
//  Created by Fly on 2019/4/30.
//  Copyright © 2019 Fly. All rights reserved.
//

#import "ViewController.h"
#import "FlyTextToolManager.h"
#import "FlyTextView.h"

@interface ViewController ()<FlyTextViewDelegate>

@property (nonatomic, copy) NSString   *   fly_oriTextStr;

@property (nonatomic, strong) NSMutableDictionary  *   fly_oriBlockRangDic; //块字符 rang arr
@property (nonatomic, strong) NSMutableDictionary  *   fly_showBlockRangDic;//块字符 rang arr
@property (nonatomic, strong) NSAttributedString   *   fly_attributeString;//要显示的文本样式

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.fly_oriTextStr = @"怎么呢？#?[001]哈哈哈哈#v [003]你呢#v[004]#v[005]怎么呢？#?[001]哈哈哈哈#v[003]你呢#v[004]#v[005]";
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    FlyTextView * textView = [[FlyTextView alloc] initWithFrame:CGRectMake(40.f, 300, width - 80.f, 80.f)];
    textView.fly_delegate = self;
    [textView setBackgroundColor:[UIColor cyanColor]];
    textView.layer.cornerRadius = 8.f;
    [textView.layer setMasksToBounds:YES];
    [textView setAttributedText:self.fly_attributeString];
    [self.view addSubview:textView];
}

- (NSAttributedString *)fly_attributeString {
    
    if (!_fly_attributeString) {
        
        NSDictionary * oriDic  = nil;
        NSDictionary * showDic = nil;
        NSString * ori_str     = self.fly_oriTextStr;
        NSAttributedString * attri = nil;
        
        [FlyTextToolManager fly_symbolRangsWithString:ori_str oriRangeDic:&oriDic showRangeDic:&showDic attributedStr:&attri symbolsDic:FlyTextSymbolConfig() configDict:FlyTextAttributedConfig() converBlock:^NSString * _Nonnull(NSString * _Nonnull contentStr, NSInteger inputType) {
            
            NSString * resultStr = nil;
            if (inputType == 100) { // 对应 FlyTextSymbolConfig 中的100
                resultStr = [NSString stringWithFormat:@"【数值%@:%@】", contentStr, @"呵呵呵"];
            } else if (inputType == 101) { // 对应 FlyTextSymbolConfig 中的101
                resultStr = [NSString stringWithFormat:@"【字符%@:%@】", contentStr, @"哈哈哈"];
            }
            return resultStr;
        }];
        
        self.fly_oriBlockRangDic  = [oriDic mutableCopy];
        self.fly_showBlockRangDic = [showDic mutableCopy];
        _fly_attributeString = attri;
    }
    return _fly_attributeString;
}

- (void)fly_textViewWillChange:(FlyTextView *)textView replaceText:(NSString *)text inRange:(NSRange)range {
    
    NSRange selectRange = NSMakeRange(0, 0);
    NSString * ori_str = self.fly_oriTextStr;
    NSDictionary * ori_dic = self.fly_oriBlockRangDic;
    NSDictionary * show_dic = self.fly_showBlockRangDic;
    NSAttributedString * attri = self.fly_attributeString;
    
    [FlyTextToolManager fly_changStringWithOriText:&ori_str selectRange:&selectRange attributedStr:&attri oriRangeDic:&ori_dic showRangeDic:&show_dic replaceRange:range replaceText:text symbolsDic:FlyTextSymbolConfig() configDict:FlyTextAttributedConfig() converBlock:^NSString * _Nonnull(NSString * _Nonnull contentStr, NSInteger inputType) {
        
        NSString * resultStr = nil;
        if (inputType == 100) { // 对应 FlyTextSymbolConfig 中的100
            resultStr = [NSString stringWithFormat:@"【数值%@:%@】", contentStr, @"呵呵呵"];
        } else if (inputType == 101) { // 对应 FlyTextSymbolConfig 中的101
            resultStr = [NSString stringWithFormat:@"【字符%@:%@】", contentStr, @"哈哈哈"];
        }
        return resultStr;
    }];
    
    self.fly_attributeString = attri;
    self.fly_oriTextStr = ori_str;
    self.fly_oriBlockRangDic  = [ori_dic mutableCopy];
    self.fly_showBlockRangDic = [show_dic mutableCopy];

    [textView setAttributedText:self.fly_attributeString];
    [textView setSelectedRange:selectRange];
}

- (void)fly_textViewDidChangeSelection:(FlyTextView *)textView selectedRange:(NSRange)selectedRange {
    
    for (NSArray * valueArr in self.fly_showBlockRangDic.allValues) {
        if ([valueArr isKindOfClass:[NSArray class]]) {
            for (NSValue * value in valueArr) {
                NSRange showRange = [value rangeValue];
                if ([FlyTextToolManager fly_isIntersectRange:showRange range:selectedRange]) {
                    selectedRange.location = NSMaxRange(showRange);
                    if (!NSEqualRanges(selectedRange, textView.selectedRange) && textView.attributedText.length >= NSMaxRange(selectedRange)) {
                        [textView setSelectedRange:selectedRange];
                    }
                    return;
                }
            }
        }
    }
}

#pragma mark - 配置文件
NS_INLINE NSDictionary * FlyTextAttributedConfig() {
   
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:4];
    
    NSMutableDictionary * normalDic = [NSMutableDictionary dictionaryWithCapacity:2];
    UIFont * normalFont   = [UIFont systemFontOfSize:14.f];
    UIColor * normalColor = [UIColor blackColor];
    
    if (normalFont) {
        [normalDic setObject:normalFont forKey:NSFontAttributeName];
    }
    if (normalColor) {
        [normalDic setObject:normalColor forKey:NSForegroundColorAttributeName];
    }
    
    NSMutableDictionary * numDic = [NSMutableDictionary dictionaryWithCapacity:2];
    UIFont * numberFont   = [UIFont systemFontOfSize:12.f];
    UIColor * numberColor = [UIColor blueColor];
    if (numberFont) {
        [numDic setObject:numberFont forKey:NSFontAttributeName];
    }
    if (numberColor) {
        [numDic setObject:numberColor forKey:NSForegroundColorAttributeName];
    }
    
    NSMutableDictionary * charDic = [NSMutableDictionary dictionaryWithCapacity:2];
    UIFont * charFont   = [UIFont systemFontOfSize:12.f];
    UIColor * charColor = [UIColor redColor];
    if (charFont) {
        [charDic setObject:charFont forKey:NSFontAttributeName];
    }
    if (charColor) {
        [charDic setObject:charColor forKey:NSForegroundColorAttributeName];
    }
    
    [dict setObject:normalDic forKey:@"normal"];
    [dict setObject:numDic    forKey:@"#v[]"];
    [dict setObject:charDic   forKey:@"#?[]"];
    
    return dict;
}

NS_INLINE NSDictionary * FlyTextSymbolConfig(void) {
    
    return @{@[@"#v[", @"]"]: @(100), @[@"#?[", @"]"]: @(101)};
}

@end
