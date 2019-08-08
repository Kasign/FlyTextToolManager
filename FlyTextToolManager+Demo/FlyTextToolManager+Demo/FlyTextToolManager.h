//
//  FlyTextToolManager.h
//  FlyTextToolManager+Demo
//
//  Created by Fly on 2019/4/30.
//  Copyright © 2019 Fly. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FlyTextAllOriRangeKey  @"ori_range"
#define FlyTextAllShowRangeKey @"show_range"

NS_ASSUME_NONNULL_BEGIN

@interface FlyTextToolManager : NSObject

///两个NSRange是否相交（不包括相邻）
+ (BOOL)fly_isIntersectRange:(NSRange)range1 range:(NSRange)range2;


/**
 输入框更改文本时，调用此方法
 
 @param ori_text 原本的文本，#v[1]12312@[嘻嘻哈哈哈]
 @param selected_range 更改文本后光标应该停留的位置
 @param show_attributedStr 应该显示的富文本
 @param ori_rangeDic 存储的原本的文本中特殊块文本的Range
 @param show_rangeDic 存储的显示的文本中特殊块文本的Range
 @param replaceRange 要替换的区域
 @param replaceText 要替换的文本
 @param symbolsDic 需要对应的符号类型，是个字典类型 eg: @{@[@"#v[", @"]"] : @(0)}
 @param configDic 颜色，字号等对应富文本的配置 eg:
 {
 normal = {NSColor = UIExtendedSRGBColorSpace 0.207843 0.254902 0.407843 0.8, NSFont = <UICTFont: 0x7fd9fbc0e0d0> font-family: ".SFUIText"; font-weight: normal; font-style: normal; font-size: 14.00pt,},
 #v[] = {NSColor = UIExtendedSRGBColorSpace 0.294118 0.521569 1 1,
 NSFont = <UICTFont: 0x7fd9fbc0e0d0> font-family: ".SFUIText"; font-weight: normal; font-style: normal; font-size: 14.00pt,},
 }
 "normal" 是正常的的属性配置
 @param converBlock 要转换的文字的block
 */
+ (void)fly_base_changStringWithOriText:(NSString **)ori_text
                            selectRange:(NSRange *)selected_range
                          attributedStr:(NSAttributedString **)show_attributedStr
                            oriRangeDic:(NSDictionary **)ori_rangeDic
                           showRangeDic:(NSDictionary **)show_rangeDic
                            allRangeDic:(NSDictionary **)all_rangeDict
                           replaceRange:(NSRange)replaceRange
                            replaceText:(NSString *)replaceText
                             symbolsDic:(NSDictionary *)symbolsDic
                             configDict:(NSDictionary *)configDic
                            converBlock:(NSString *(^)(NSString * contentStr, NSInteger inputType))converBlock;

/**
 可以更改局部的str到块字符
 
 @param ori_str 要更改的原始的string
 @param ori_rangeDic 更改区域原始range的变化
 @param show_rangeDict 更改区域显示range的变化
 @param show_attributedStr 更改区域显示show_attributedStr，可以用来替换原始的
 @param symbolsDic 对应的块字符的样式字典  {样式数组：样式类型}
 @param configDic 颜色字号配置@{@"normal":@{}, @"#v[]":@{}, @"#?[]":@{}}
 @param converBlock 获取要替换的字符
 */
+ (void)fly_base_rangsWithString:(NSString *)ori_str
                     oriRangeDic:(NSDictionary **)ori_rangeDic
                    showRangeDic:(NSDictionary **)show_rangeDict
                     allRangeDic:(NSDictionary **)all_rangeDict
                   attributedStr:(NSAttributedString **)show_attributedStr
                      symbolsDic:(NSDictionary *)symbolsDic
                      configDict:(NSDictionary *)configDic
                     converBlock:(NSString *(^)(NSString * contentStr, NSInteger inputType))converBlock;

@end

NS_ASSUME_NONNULL_END
