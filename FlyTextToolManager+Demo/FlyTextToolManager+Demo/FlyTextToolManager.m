//
//  FlyTextToolManager.m
//  FlyTextToolManager+Demo
//
//  Created by Fly on 2019/4/30.
//  Copyright © 2019 Fly. All rights reserved.
//

#import "FlyTextToolManager.h"

#define FlyTextLog1(...)
#define FlyTextLog2(...)
#define FlyTextLog3(...)
#define FlyTextLog4(...)

@interface FlyRange : NSObject

@property (nonatomic, assign) NSInteger       location;
@property (nonatomic, assign) NSInteger       length;

@property (readonly) NSRange       toRange;

@end

@implementation FlyRange

- (void)setLocation:(NSInteger)location {
    
    _location = MAX(0, location);
}

- (void)setLength:(NSInteger)length {
    
    _length = MAX(0, length);
}

- (NSRange)toRange {
    
    return NSMakeRange(self.location, self.length);
}

@end

NS_INLINE FlyRange * FlyMakeRange(NSUInteger loc, NSUInteger len) {
    
    FlyRange * r = [[FlyRange alloc] init];
    r.location = loc;
    r.length = len;
    return r;
}

NS_INLINE FlyRange * FlyRangeWithRange(NSRange range) {
    
    FlyRange * r = [[FlyRange alloc] init];
    r.location = range.location;
    r.length   = range.length;
    return r;
}

NS_INLINE NSUInteger FlyMaxRange(FlyRange * range) {
    return (range.location + range.length);
}

//NS_INLINE BOOL NSLocationInRange(NSUInteger loc, NSRange range) {
//    return (!(loc < range.location) && (loc - range.location) < range.length) ? YES : NO;
//}
//
//NS_INLINE BOOL FlyEqualRanges(FlyRange * range1, FlyRange * range2) {
//    return (range1.location == range2.location && range1.length == range2.length);
//}

@interface NSValue (FlyValueRangeExtensions)

+ (NSValue *)valueWithFlyRange:(FlyRange *)range;
@property (readonly) FlyRange * flyRangeValue;

@end

@implementation NSValue (FlyValueRangeExtensions)

+ (NSValue *)valueWithFlyRange:(FlyRange *)range {
    
    NSRange r = NSMakeRange(range.location, range.length);
    return [self valueWithRange:r];
}

- (FlyRange *)flyRangeValue {
    
    NSRange r = [self rangeValue];
    return FlyMakeRange(r.location, r.length);
}

@end

@implementation FlyTextToolManager

+ (BOOL)fly_isIntersectRange:(NSRange)range1 range:(NSRange)range2 {
    
    BOOL result = NO;
    
    if (((range1.location > range2.location) && (range1.location - range2.location) < range2.length) || ((range2.location > range1.location) && (range2.location - range1.location) < range1.length)) {
        result = YES;
    }
    return result;
}

+ (BOOL)fly_isIntersectFlyRange:(FlyRange *)range1 FlyRange:(FlyRange *)range2 {
    
    BOOL result = NO;
    
    if (((range1.location > range2.location) && (range1.location - range2.location) < range2.length) || ((range2.location > range1.location) && (range2.location - range1.location) < range1.length)) {
        result = YES;
    }
    return result;
}

/**
 输入框更改文本时，调用此方法
 
 @param ori_text 原本的文本，#v[1]12312@[嘻嘻哈哈哈]
 @param selected_range 更改文本后光标应该停留的位置
 @param show_attributedStr 应该显示的富文本
 @param ori_rangeDic 存储的原本的文本中特殊块文本的Range
 @param show_rangeDic 存储的显示的文本中特殊块文本的Range
 @param replaceRange 要替换的区域
 @param replaceText 要替换的文本
 @param symbolsDic 需要对应的符号类型，是个字典类型
 @param configDic 颜色，字号等对应富文本的配置
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
                            converBlock:(NSString *(^)(NSString * contentStr, NSInteger inputType))converBlock {
    
    NSString * oriText = [*ori_text copy];
    NSMutableDictionary * oriRangeDic  = [*ori_rangeDic mutableCopy];
    NSMutableDictionary * showRangeDic = [*show_rangeDic mutableCopy];
    NSMutableDictionary * allRangeDic  = [*all_rangeDict mutableCopy];
    NSMutableAttributedString * showAttributedString = [*show_attributedStr mutableCopy];
    
    NSMutableArray * oriAllRangeArr  = [[allRangeDic objectForKey:FlyTextAllOriRangeKey]  mutableCopy];
    NSMutableArray * showAllRangeArr = [[allRangeDic objectForKey:FlyTextAllShowRangeKey] mutableCopy];
    
    if (!showAttributedString && oriText) {
        showAttributedString = [[NSMutableAttributedString alloc] initWithString:oriText attributes:[configDic objectForKey:@"normal"]];
    }
    
    if (!oriRangeDic) {
        oriRangeDic = [NSMutableDictionary dictionary];
    }
    if (!showRangeDic) {
        showRangeDic = [NSMutableDictionary dictionary];
    }
    if (!oriRangeDic) {
        oriRangeDic = [NSMutableDictionary dictionary];
    }
    if (!allRangeDic) {
        allRangeDic = [NSMutableDictionary dictionary];
    }
    if (!oriAllRangeArr) {
        oriAllRangeArr = [NSMutableArray array];
    }
    if (!showAllRangeArr) {
        showAllRangeArr = [NSMutableArray array];
    }
    [allRangeDic setObject:oriAllRangeArr  forKey:FlyTextAllOriRangeKey];
    [allRangeDic setObject:showAllRangeArr forKey:FlyTextAllShowRangeKey];
    
    FlyTextLog3(@"---------------------Change Start---------------------");
    if ([oriText isKindOfClass:[NSString class]] && [replaceText isKindOfClass:[NSString class]] && [showAttributedString isKindOfClass:[NSAttributedString class]] && [showAttributedString length] >= NSMaxRange(replaceRange)) {
        
        FlyRange * showReplaceRange = FlyRangeWithRange(replaceRange);
        FlyRange * oriReplaceRange  = FlyRangeWithRange(replaceRange);
        FlyRange * selectedRange    = FlyMakeRange(replaceRange.location, 0);
        FlyRange * should_showReplaceRange = FlyMakeRange(0, showAttributedString.length + replaceText.length - replaceRange.length);
        FlyRange * should_oriReplaceRange  = FlyMakeRange(0, oriText.length + replaceText.length - replaceRange.length);
        FlyTextLog2(@"初始\n----->>>>\noriRangeDic：%@\nshowRangeDic：%@\noriText:%@\nshowAttributedString:%@\nshould_showReplaceRange:%@\n----->>>>\n", oriRangeDic, showRangeDic, oriText, [showAttributedString string], [NSValue valueWithFlyRange:should_showReplaceRange]);
        
        if ((oriText.length + replaceText.length) > 0) {
            
            NSArray * keyArr = showRangeDic.allKeys;
            for (NSString * key in keyArr) {
                
                @autoreleasepool {
                    
                    NSArray * tmp_oriArr  = [[oriRangeDic  objectForKey:key] copy];
                    NSArray * tmp_showArr = [[showRangeDic objectForKey:key] copy];
                    
                    //因为用户一般都是继续输入，为了减少遍历次数，此处选用倒序
                    for (NSInteger index = (tmp_showArr.count - 1); index >= 0; index --) {
                        
                        NSValue * tmp_oriValue  = [tmp_oriArr  objectAtIndex:index];
                        NSValue * tmp_showValue = [tmp_showArr objectAtIndex:index];
                        FlyRange * tmp_oriRange  = [tmp_oriValue flyRangeValue];
                        FlyRange * tmp_showRange = [tmp_showValue flyRangeValue];
                        if ([self fly_isIntersectFlyRange:FlyRangeWithRange(replaceRange) FlyRange:tmp_showRange]) {//在中间
                            
                            oriReplaceRange.location  = MIN(replaceRange.location - tmp_showRange.location + tmp_oriRange.location, tmp_oriRange.location);
                            oriReplaceRange.length    = MAX(FlyMaxRange(oriReplaceRange), FlyMaxRange(tmp_oriRange)) - oriReplaceRange.location;
                            
                            showReplaceRange.location = MIN(showReplaceRange.location, tmp_showRange.location);
                            showReplaceRange.length   = MAX(FlyMaxRange(showReplaceRange), FlyMaxRange(tmp_showRange)) - showReplaceRange.location;
                            
                            should_showReplaceRange.length = 0;
                            should_oriReplaceRange.length  = 0;
                            
                            FlyTextLog2(@" 之中\n--->>>>\nreplaceText : %@\nreplaceRange : %@\ntmp_showRange : %@\noriReplaceRange : %@\nshould_showReplaceRange : %@\n----->>>\n",replaceText,[NSValue valueWithRange:replaceRange],[NSValue valueWithFlyRange:tmp_showRange],[NSValue valueWithFlyRange:oriReplaceRange],[NSValue valueWithFlyRange:should_showReplaceRange]);
                            
                            NSMutableArray * tmp_oriRangeArr = [tmp_oriArr mutableCopy];
                            [tmp_oriRangeArr removeObjectAtIndex:index];
                            [oriRangeDic setObject:tmp_oriRangeArr forKey:key];
                            
                            NSMutableArray * tmp_showRangeArr = [tmp_showArr mutableCopy];
                            [tmp_showRangeArr removeObjectAtIndex:index];
                            [showRangeDic setObject:tmp_showRangeArr forKey:key];
                            
                            [oriAllRangeArr  removeObject:tmp_oriValue];
                            [showAllRangeArr removeObject:tmp_showValue];
                            
                            break;
                        } else {
                            
                            if (FlyMaxRange(tmp_showRange) <= replaceRange.location) {//在后面
                                
                                NSInteger tmp_oriPlaceLocal = replaceRange.location - FlyMaxRange(tmp_showRange) + FlyMaxRange(tmp_oriRange);
                                oriReplaceRange.location = MIN(tmp_oriPlaceLocal, oriReplaceRange.location);
                                
                                //更新后面这些文字是否有可变的,此时showReplaceRange不变
                                NSInteger tmp_should_show_location = MAX(FlyMaxRange(tmp_showRange), should_showReplaceRange.location);
                                
                                should_showReplaceRange.length   = FlyMaxRange(should_showReplaceRange) - tmp_should_show_location;;
                                should_showReplaceRange.location = tmp_should_show_location;
                                
                                //更新后面这些文字是否有可变的,此时showReplaceRange不变
                                NSInteger tmp_should_ori_location = MAX(FlyMaxRange(tmp_oriRange), should_oriReplaceRange.location);
                                
                                should_oriReplaceRange.length   = FlyMaxRange(should_oriReplaceRange) - tmp_should_ori_location;;
                                should_oriReplaceRange.location = tmp_should_ori_location;
                                
                                FlyTextLog2(@" 之后\n--->>>>\nreplaceText : %@\nreplaceRange : %@\ntmp_showRange : %@\noriReplaceRange : %@\nshould_showReplaceRange : %@\n----->>>\n",replaceText,[NSValue valueWithRange:replaceRange],[NSValue valueWithFlyRange:tmp_showRange],[NSValue valueWithFlyRange:oriReplaceRange],[NSValue valueWithFlyRange:should_showReplaceRange]);
                                
                                break;
                            } else {//在前面
                                
                                //更新前面这些文字是否有可变的,此时showReplaceRange不变
                                
                                NSInteger show_length = MIN(should_showReplaceRange.length, tmp_showRange.location - should_showReplaceRange.location + replaceText.length - showReplaceRange.length);
                                should_showReplaceRange.length = show_length;
                                
                                NSInteger ori_length = MIN(should_oriReplaceRange.length, tmp_oriRange.location - should_oriReplaceRange.location + replaceText.length - oriReplaceRange.length);
                                should_oriReplaceRange.length = ori_length;
                                
                                FlyTextLog2(@" 之前\n--->>>>\nreplaceText : %@\nreplaceRange : %@\ntmp_showRange : %@\noriReplaceRange : %@\nshould_showReplaceRange : %@\n----->>>\n",replaceText,[NSValue valueWithRange:replaceRange],[NSValue valueWithFlyRange:tmp_showRange],[NSValue valueWithFlyRange:oriReplaceRange],[NSValue valueWithFlyRange:should_showReplaceRange]);
                            }
                        }
                    }
                }
                
                if (!NSEqualRanges(showReplaceRange.toRange, replaceRange)) {
                    FlyTextLog2(@" 最终break\n--->>>>\nreplaceText : %@\nreplaceRange : %@\nshowReplaceRange : %@\noriReplaceRange : %@\nshould_showReplaceRange : %@\n----->>>\n",replaceText,[NSValue valueWithRange:replaceRange],[NSValue valueWithFlyRange:showReplaceRange],[NSValue valueWithFlyRange:oriReplaceRange],[NSValue valueWithFlyRange:should_showReplaceRange]);
                    break;
                }
            }
            
            if (FlyMaxRange(oriReplaceRange) > oriText.length) {
                FlyTextLog2(@"转换前超了---\noriReplaceRange:%@\n", [NSValue valueWithFlyRange:oriReplaceRange]);
                oriReplaceRange.location = oriText.length - oriReplaceRange.length;
                if (FlyMaxRange(oriReplaceRange) > oriText.length) {
                    oriReplaceRange.length = oriText.length - oriReplaceRange.location;
                }
                if (FlyMaxRange(oriReplaceRange) > oriText.length) {
                    oriReplaceRange.location = 0;
                    oriReplaceRange.length = oriText.length;
                }
            }
            
            if (FlyMaxRange(showReplaceRange) > showAttributedString.length) {
                FlyTextLog2(@"转换前超了---\nshowReplaceRange:%@\n", [NSValue valueWithFlyRange:showReplaceRange]);
                showReplaceRange.location = showAttributedString.length - showReplaceRange.length;
                if (FlyMaxRange(showReplaceRange) > showAttributedString.length) {
                    showReplaceRange.length = showAttributedString.length - showReplaceRange.location;
                }
                if (FlyMaxRange(showReplaceRange) > showAttributedString.length) {
                    showReplaceRange.location = 0;
                    showReplaceRange.length = showAttributedString.length;
                }
            }
            FlyTextLog2(@"转换前\n------>>>>\noriRangeDic:\n%@\nshowRangeDic:\n%@\nselectedRange:%@\nshould_showReplaceRange:%@\noriReplaceRange:%@\nshowReplaceRange:%@\noriText:%@\nshowAttributedString:%@\n------>>>>\n", oriRangeDic, showRangeDic, [NSValue valueWithFlyRange:selectedRange], [NSValue valueWithFlyRange:should_showReplaceRange],[NSValue valueWithFlyRange:oriReplaceRange],[NSValue valueWithFlyRange:showReplaceRange], oriText, [showAttributedString string]);
            
            oriText = [oriText stringByReplacingCharactersInRange:oriReplaceRange.toRange withString:replaceText];
            [showAttributedString replaceCharactersInRange:showReplaceRange.toRange withString:replaceText];
            selectedRange.location = showReplaceRange.location + replaceText.length;
            FlyTextLog2(@"转换后\n------>>>>\noriRangeDic:\n%@\nshowRangeDic:\n%@\nselectedRange:%@\nshould_showReplaceRange:%@\noriReplaceRange:%@\nshowReplaceRange:%@\noriText:%@\nshowAttributedString:%@\n------>>>>\n", oriRangeDic, showRangeDic, [NSValue valueWithFlyRange:selectedRange], [NSValue valueWithFlyRange:should_showReplaceRange],[NSValue valueWithFlyRange:oriReplaceRange],[NSValue valueWithFlyRange:showReplaceRange], oriText, [showAttributedString string]);
            
            //前或后
            if (replaceText.length >= 0 && FlyMaxRange(should_showReplaceRange) <= showAttributedString.length && FlyMaxRange(should_showReplaceRange) < NSIntegerMax) {
                
                FlyTextLog2(@"进行重新排列");
                NSDictionary * replaceOriDic  = nil;
                NSDictionary * replaceShowDic = nil;
                NSDictionary * replaceAllRangeDic = nil;
                NSString * showStr = [[showAttributedString string] copy];
                NSAttributedString * replaceAttri = nil;
                NSString * replaceOriStr = [showStr substringWithRange:should_showReplaceRange.toRange];
                FlyTextLog2(@"重新排列前\n------>>>>\noriRangeDic:\n%@\nshowRangeDic:\n%@\nselectedRange:%@\nshould_showReplaceRange:%@\nreplaceOriStr:%@\noriText:%@\nshowAttributedString:\n%@\n------>>>>\n", oriRangeDic, showRangeDic, [NSValue valueWithFlyRange:selectedRange], [NSValue valueWithFlyRange:should_showReplaceRange], replaceOriStr, oriText, [showAttributedString string]);
                
                [self fly_base_rangsWithString:replaceOriStr oriRangeDic:&replaceOriDic showRangeDic:&replaceShowDic allRangeDic:&replaceAllRangeDic attributedStr:&replaceAttri symbolsDic:symbolsDic configDict:configDic converBlock:converBlock];
                
                FlyTextLog2(@"重新排列后\n------>>>>\noriRangeDic:\n%@\nshowRangeDic:\n%@\nselectedRange:%@\nshould_showReplaceRange:%@\nreplaceAttri:%@\noriText:%@\nshowAttributedString:\n%@\n------>>>>\n", oriRangeDic, showRangeDic, [NSValue valueWithFlyRange:selectedRange], [NSValue valueWithFlyRange:should_showReplaceRange],[replaceAttri string], oriText, [showAttributedString string]);
                
                [showAttributedString replaceCharactersInRange:should_showReplaceRange.toRange withAttributedString:replaceAttri];
                
                selectedRange.location += replaceAttri.length - should_showReplaceRange.length;
                
                //计算总的range数组
                [self fly_base_resetRangesWithOriAllRangeArr:oriAllRangeArr
                                             showAllRangeArr:showAllRangeArr
                                               replaceOriArr:[replaceAllRangeDic objectForKey:FlyTextAllOriRangeKey]
                                              replaceShowArr:[replaceAllRangeDic objectForKey:FlyTextAllShowRangeKey]
                                                 replaceText:replaceText
                                                replaceAttri:[replaceAttri string]
                                             oriReplaceRange:oriReplaceRange
                                            showReplaceRange:showReplaceRange
                                      should_oirReplaceRange:should_oriReplaceRange
                                     should_showReplaceRange:should_showReplaceRange];
                
                //更新range字典内数据
                NSMutableArray * keyArr = [oriRangeDic.allKeys mutableCopy];
                for (NSString * replaceKey in replaceOriDic.allKeys) {
                    if (![keyArr containsObject:replaceKey]) {
                        [keyArr addObject:replaceKey];
                    }
                }
                
                for (NSString * key in keyArr) {
                    
                    NSMutableArray * tmpShowArr = [[showRangeDic objectForKey:key] mutableCopy];
                    NSMutableArray * tmpOriArr  = [[oriRangeDic  objectForKey:key] mutableCopy];
                    
                    if (!tmpShowArr) {
                        tmpShowArr = [NSMutableArray array];
                    }
                    if (!tmpOriArr) {
                        tmpOriArr = [NSMutableArray array];
                    }
                    
                    NSMutableArray * tmpReplaceShowArr = [[replaceShowDic objectForKey:key] mutableCopy];
                    NSMutableArray * tmpReplaceOriArr  = [[replaceOriDic  objectForKey:key] mutableCopy];
                    
                    if (!tmpReplaceShowArr) {
                        tmpReplaceShowArr = [NSMutableArray array];
                    }
                    if (!tmpReplaceOriArr) {
                        tmpReplaceOriArr = [NSMutableArray array];
                    }
                    
                    [self fly_base_resetRangesWithOriAllRangeArr:tmpOriArr
                                                 showAllRangeArr:tmpShowArr
                                                   replaceOriArr:tmpReplaceOriArr
                                                  replaceShowArr:tmpReplaceShowArr
                                                     replaceText:replaceText
                                                    replaceAttri:[replaceAttri string]
                                                 oriReplaceRange:oriReplaceRange
                                                showReplaceRange:showReplaceRange
                                          should_oirReplaceRange:should_oriReplaceRange
                                         should_showReplaceRange:should_showReplaceRange];
                    //将整合后的数据重新存起来
                    [showRangeDic setObject:tmpShowArr forKey:key];
                    [oriRangeDic  setObject:tmpOriArr  forKey:key];
                }
                
                FlyTextLog2(@"最终\n----->>>>\noriText:%@\nshowAttributedString:%@\nreplaceOriStr ：%@\nshould_showReplaceRange：%@\noriRangeDic：%@\nshowRangeDic：%@\nallRangeDic:%@\n----->>>>\n",oriText,showAttributedString.string,replaceOriStr, [NSValue valueWithFlyRange:should_showReplaceRange], oriRangeDic, showRangeDic, allRangeDic);///此处allRangeDic应包含oriRangeDic和showRangeDic，不然就是出错了
            } else {
                FlyTextLog2(@"未进行重新排列");
            }
        }
        selectedRange.location = MIN(showAttributedString.length - selectedRange.length, selectedRange.location);
        
        if (oriText.length == 0) {
            [showAttributedString replaceCharactersInRange:NSMakeRange(0, showAttributedString.length) withString:@""];
            [showRangeDic removeAllObjects];
            [oriRangeDic  removeAllObjects];
            selectedRange.location = 0;
        }
        
        FlyTextLog2(@"\noriText:%@\nselectedRange:%@\nshowAttributedString:%@\n",oriText,[NSValue valueWithFlyRange:selectedRange], [showAttributedString string]);
        
        FlyTextLog2(@"---------------------Change End---------------------");
        
        if (selected_range) {
            *selected_range = NSMakeRange(selectedRange.location, 0);
        }
        if (show_attributedStr) {
            *show_attributedStr = showAttributedString;
        }
        if (ori_text) {
            *ori_text = oriText;
        }
        if (show_rangeDic) {
            *show_rangeDic = showRangeDic;
        }
        if (ori_rangeDic) {
            *ori_rangeDic = oriRangeDic;
        }
        if (all_rangeDict) {
            *all_rangeDict = allRangeDic;
        }
    }
}

+ (void)fly_base_resetRangesWithOriAllRangeArr:(NSMutableArray *)oriAllRangeArr
                               showAllRangeArr:(NSMutableArray *)showAllRangeArr
                                 replaceOriArr:(NSMutableArray *)replaceOriArr
                                replaceShowArr:(NSMutableArray *)replaceShowArr
                                   replaceText:(NSString *)replaceText
                                  replaceAttri:(NSString *)replaceAttri
                               oriReplaceRange:(FlyRange *)oriReplaceRange
                              showReplaceRange:(FlyRange *)showReplaceRange
                        should_oirReplaceRange:(FlyRange *)should_oriReplaceRange
                       should_showReplaceRange:(FlyRange *)should_showReplaceRange {
    
    if ([oriAllRangeArr isKindOfClass:[NSMutableArray class]] && [showAllRangeArr isKindOfClass:[NSMutableArray class]] && [oriReplaceRange isKindOfClass:[FlyRange class]] && [showReplaceRange isKindOfClass:[FlyRange class]] && [should_oriReplaceRange isKindOfClass:[FlyRange class]] && [should_showReplaceRange isKindOfClass:[FlyRange class]]) {
        
        if ([replaceOriArr isKindOfClass:[NSMutableArray class]] && [replaceShowArr isKindOfClass:[NSMutableArray class]]) {
            for (NSInteger i = 0; i < replaceShowArr.count; i ++) {
                @autoreleasepool {
                    NSValue * tmp_showValue = [replaceShowArr objectAtIndex:i];
                    NSValue * tmp_oriValue  = [replaceOriArr  objectAtIndex:i];
                    
                    FlyRange * tmp_showRange = [tmp_showValue flyRangeValue];
                    FlyRange * tmp_oriRange  = [tmp_oriValue  flyRangeValue];
                    
                    tmp_showRange.location = tmp_showRange.location + should_showReplaceRange.location;
                    tmp_oriRange.location  = tmp_oriRange.location  + should_oriReplaceRange.location;
                    
                    [replaceShowArr replaceObjectAtIndex:i withObject:[NSValue valueWithFlyRange:tmp_showRange]];
                    [replaceOriArr  replaceObjectAtIndex:i withObject:[NSValue valueWithFlyRange:tmp_oriRange]];
                }
            }
        }
        
        //replaceOriArr 和 replaceShowArr 或者为空或者是可变数组
        if (([replaceOriArr isKindOfClass:[NSMutableArray class]] || !replaceOriArr) && ([replaceShowArr isKindOfClass:[NSMutableArray class]] || !replaceShowArr)) {
            
            NSInteger totalCount = oriAllRangeArr.count + replaceOriArr.count;
            for (NSInteger i = 0; i < totalCount; i ++) {
                
                if (i < oriAllRangeArr.count) {
                    @autoreleasepool {
                        NSValue * tmp_showValue = [showAllRangeArr objectAtIndex:i];
                        NSValue * tmp_oriValue  = [oriAllRangeArr  objectAtIndex:i];
                        
                        FlyRange * tmp_showRange = [tmp_showValue flyRangeValue];
                        FlyRange * tmp_oriRange  = [tmp_oriValue  flyRangeValue];
                        FlyTextLog3(@"遍历\n----->>>>>\ntmp_oriValue:%@\noriReplaceRange:%@\n----->>>>>\n",tmp_oriValue,[NSValue valueWithFlyRange:oriReplaceRange]);
                        //对原来的数据重新计算位置
                        if (tmp_oriRange.location >= FlyMaxRange(oriReplaceRange)) {
                            
                            FlyTextLog3(@"计算位置前：\n---->>>>\ntmp_showRange:%@\ntmp_oriRange%@\n----->>>>\n",[NSValue valueWithFlyRange:tmp_showRange],[NSValue valueWithFlyRange:tmp_oriRange]);
                            
                            tmp_showRange.location = tmp_showRange.location + replaceAttri.length - should_showReplaceRange.length + replaceText.length - showReplaceRange.length;
                            
                            tmp_oriRange.location  = tmp_oriRange.location - oriReplaceRange.length + replaceText.length;
                            
                            FlyTextLog3(@"计算位置后：\n---->>>>\ntmp_showRange:%@\ntmp_oriRange%@\n----->>>>\n",[NSValue valueWithFlyRange:tmp_showRange],[NSValue valueWithFlyRange:tmp_oriRange]);
                            
                            tmp_showValue = [NSValue valueWithFlyRange:tmp_showRange];
                            tmp_oriValue  = [NSValue valueWithFlyRange:tmp_oriRange];
                            [showAllRangeArr replaceObjectAtIndex:i withObject:tmp_showValue];
                            [oriAllRangeArr  replaceObjectAtIndex:i withObject:tmp_oriValue];
                        }
                        
                        if (replaceShowArr.count > 0 && replaceOriArr.count > 0) {
                            NSValue * tmp_replace_showValue = replaceShowArr.firstObject;
                            NSValue * tmp_replace_oriValue  = replaceOriArr.firstObject;
                            FlyRange * tmp_replace_oriRange  = [tmp_replace_oriValue flyRangeValue];
                            
                            if (tmp_replace_oriRange.location < tmp_oriRange.location) {
                                [oriAllRangeArr  insertObject:tmp_replace_oriValue  atIndex:i];
                                [showAllRangeArr insertObject:tmp_replace_showValue atIndex:i];
                                [replaceShowArr removeObjectAtIndex:0];
                                [replaceOriArr  removeObjectAtIndex:0];
                                i ++;
                            } else {
                                if (i == oriAllRangeArr.count - 1) {
                                    [oriAllRangeArr  addObjectsFromArray:replaceOriArr];
                                    [showAllRangeArr addObjectsFromArray:replaceShowArr];
                                    [replaceOriArr  removeAllObjects];
                                    [replaceShowArr removeAllObjects];
                                    i ++;
                                }
                            }
                        }
                    }
                } else {
                    [oriAllRangeArr  addObjectsFromArray:replaceOriArr];
                    [showAllRangeArr addObjectsFromArray:replaceShowArr];
                    [replaceOriArr  removeAllObjects];
                    [replaceShowArr removeAllObjects];
                }
            }
        }
        FlyTextLog3(@"----封装--->>>\noriAllRangeArr：%@\nshowAllRangeArr：%@\n---------",oriAllRangeArr, showAllRangeArr);
    }
}

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
                     converBlock:(NSString *(^)(NSString * contentStr, NSInteger inputType))converBlock {
    
    NSString * oriString = ori_str;
    NSMutableAttributedString * attributedString = nil;
    if (!oriString) {
        oriString = [*show_attributedStr string];
    }
    
    NSMutableDictionary * allRangeDict = [NSMutableDictionary dictionary];
    FlyTextLog4(@"----Start------->>>>>>>>>\nori_str : %@\n-----------------",oriString);
    
    if ([oriString isKindOfClass:[NSString class]] && [symbolsDic isKindOfClass:[NSDictionary class]] && symbolsDic.count > 0) {
        NSMutableDictionary * showRangeDic = [NSMutableDictionary dictionary];
        NSMutableDictionary * oriRangeDic  = [NSMutableDictionary dictionary];
        
        NSString * currentShowStr = oriString;
        
        if (ori_str) {
            attributedString = [[NSMutableAttributedString alloc] initWithString:oriString attributes:[configDic objectForKey:@"normal"]];
        } else if (show_attributedStr && *show_attributedStr) {
            attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:*show_attributedStr];
        }
        
        if (oriString.length > 0) {
            NSInteger currentOriIndex  = 0;
            NSInteger currentShowIndex = 0;
            do {
                @autoreleasepool {
                    
                    FlyTextLog4(@"--------------begin--------------");
                    NSInteger  insertType  = 0;
                    NSString * firstSymbol = @"";
                    NSString * lastSymbol  = @"";
                    NSString * symString   = @"";
                    
                    FlyRange * currentFirstRange = FlyMakeRange(NSIntegerMax, 0);
                    FlyRange * currentLastRange  = FlyMakeRange(NSIntegerMax, 0);
                    FlyRange * oriFirstRange = currentFirstRange;
                    FlyRange * oriLastRange  = currentLastRange;
                    
                    //匹配下一对值
                    if (currentShowStr.length > currentShowIndex) {
                        
                        for (NSArray * subSymbolArr in symbolsDic.allKeys) {
                            
                            NSString * tmp_firstSymbol = subSymbolArr.firstObject;
                            NSString * tmp_lastSymbol  = subSymbolArr.lastObject;
                            
                            FlyRange * tmp_firstRang = FlyRangeWithRange([currentShowStr rangeOfString:tmp_firstSymbol options:NSLiteralSearch range:NSMakeRange(currentShowIndex, currentShowStr.length - currentShowIndex)]);
                            FlyRange * tmp_lastRang  = FlyRangeWithRange([currentShowStr rangeOfString:tmp_lastSymbol options:NSLiteralSearch range:NSMakeRange(currentShowIndex, currentShowStr.length - currentShowIndex)]);
                            
                            if (tmp_lastRang.location < tmp_firstRang.location && currentShowStr.length > FlyMaxRange(tmp_firstRang)) {
                                tmp_lastRang = FlyRangeWithRange([currentShowStr rangeOfString:tmp_lastSymbol options:NSLiteralSearch range:NSMakeRange(FlyMaxRange(tmp_firstRang), currentShowStr.length - FlyMaxRange(tmp_firstRang))]);
                            }
                            
                            FlyTextLog4(@"1111\n---->>>>\noriFirstRange:%@\noriLastRange:%@\ncurrentFirstRange:%@\ncurrentLastRange:%@\nfirstSymbol:%@\n lastSymbol:%@\nsymString:%@\noriString:%@\ncurrentShowStr:%@\n---->>>>\n", [NSValue valueWithFlyRange:oriFirstRange], [NSValue valueWithFlyRange:oriLastRange], [NSValue valueWithFlyRange:currentFirstRange], [NSValue valueWithFlyRange:currentLastRange], firstSymbol, lastSymbol, symString, oriString, currentShowStr);
                            
                            if ((currentFirstRange.location > tmp_firstRang.location) && FlyMaxRange(tmp_lastRang) > 0) {
                                currentFirstRange  = tmp_firstRang;
                                currentLastRange   = tmp_lastRang;
                                firstSymbol = tmp_firstSymbol;
                                lastSymbol  = tmp_lastSymbol;
                                insertType  = [[symbolsDic objectForKey:subSymbolArr] integerValue];
                                FlyTextLog4(@"2222\n---->>>>\noriFirstRange:%@\noriLastRange:%@\ncurrentFirstRange:%@\ncurrentLastRange:%@\nfirstSymbol:%@\n lastSymbol:%@\nsymString:%@\noriString:%@\ncurrentShowStr:%@\n---->>>>\n", [NSValue valueWithFlyRange:oriFirstRange], [NSValue valueWithFlyRange:oriLastRange], [NSValue valueWithFlyRange:currentFirstRange], [NSValue valueWithFlyRange:currentLastRange], firstSymbol, lastSymbol, symString, oriString, currentShowStr);
                            }
                        }
                        symString = [firstSymbol stringByAppendingString:lastSymbol];
                    } FlyTextLog4(@"3333\n---->>>>\noriFirstRange:%@\noriLastRange:%@\ncurrentFirstRange:%@\ncurrentLastRange:%@\nfirstSymbol:%@\n lastSymbol:%@\nsymString:%@\noriString:%@\ncurrentShowStr:%@\n---->>>>\n", [NSValue valueWithFlyRange:oriFirstRange], [NSValue valueWithFlyRange:oriLastRange], [NSValue valueWithFlyRange:currentFirstRange], [NSValue valueWithFlyRange:currentLastRange], firstSymbol, lastSymbol, symString, oriString, currentShowStr);
                    
                    
                    if (oriString.length > currentOriIndex) {
                        
                        oriFirstRange = FlyRangeWithRange([oriString rangeOfString:firstSymbol options:NSLiteralSearch range:NSMakeRange(currentOriIndex, oriString.length - currentOriIndex)]);
                        if (oriString.length > FlyMaxRange(oriFirstRange)) {
                            oriLastRange = FlyRangeWithRange([oriString rangeOfString:lastSymbol options:NSLiteralSearch range:NSMakeRange(FlyMaxRange(oriFirstRange), oriString.length - FlyMaxRange(oriFirstRange))]);
                        } else {
                            oriLastRange = oriFirstRange;
                        }
                        FlyTextLog4(@"4444\n---->>>>\noriFirstRange:%@\noriLastRange:%@\ncurrentFirstRange:%@\ncurrentLastRange:%@\nfirstSymbol:%@\n lastSymbol:%@\nsymString:%@\noriString:%@\ncurrentShowStr:%@\n---->>>>\n", [NSValue valueWithFlyRange:oriFirstRange], [NSValue valueWithFlyRange:oriLastRange], [NSValue valueWithFlyRange:currentFirstRange], [NSValue valueWithFlyRange:currentLastRange], firstSymbol, lastSymbol, symString, oriString, currentShowStr);
                    }
                    
                    currentOriIndex  = FlyMaxRange(oriFirstRange);
                    currentShowIndex = FlyMaxRange(currentFirstRange);
                    FlyTextLog4(@"5555\n---->>>>\noriFirstRange:%@\noriLastRange:%@\ncurrentFirstRange:%@\ncurrentLastRange:%@\nfirstSymbol:%@\n lastSymbol:%@\nsymString:%@\noriString:%@\ncurrentShowStr:%@\n---->>>>\n", [NSValue valueWithFlyRange:oriFirstRange], [NSValue valueWithFlyRange:oriLastRange], [NSValue valueWithFlyRange:currentFirstRange], [NSValue valueWithFlyRange:currentLastRange], firstSymbol, lastSymbol, symString, oriString, currentShowStr);
                    
                    //保存并替换
                    if (FlyMaxRange(oriLastRange) <= oriString.length && FlyMaxRange(currentLastRange) <= currentShowStr.length && FlyMaxRange(oriLastRange) > 0 && FlyMaxRange(currentLastRange) > 0 && currentLastRange.location > FlyMaxRange(currentFirstRange)) {
                        
                        FlyRange * currentRange = FlyMakeRange(currentFirstRange.location, FlyMaxRange(currentLastRange) - currentFirstRange.location);//需要替换的range
                        FlyRange * oriRange     = FlyMakeRange(oriFirstRange.location, FlyMaxRange(oriLastRange) - oriFirstRange.location);
                        FlyRange * showRang     = FlyMakeRange(FlyMaxRange(currentFirstRange), currentLastRange.location - FlyMaxRange(currentFirstRange));
                        
                        NSString * contentStr = [currentShowStr substringWithRange:showRang.toRange];
                        
                        NSString * showStr    = @"";
                        if (converBlock && contentStr.length > 0 && insertType != 0) {
                            showStr = converBlock(contentStr, insertType);
                        }
                        
                        //替换保存
                        if ([showStr isKindOfClass:[NSString class]]) {
                            
                            currentShowStr = [currentShowStr stringByReplacingCharactersInRange:currentRange.toRange withString:showStr];
                            
                            showRang.location = showRang.location - firstSymbol.length;
                            showRang.length   = showStr.length;
                            
                            //存数据
                            if (symString.length && FlyMaxRange(showRang) > 0 && FlyMaxRange(oriRange) > 0) {
                                
                                NSMutableArray * tmp_oriRangeArr  = [oriRangeDic  objectForKey:symString];
                                NSMutableArray * tmp_showRangeArr = [showRangeDic objectForKey:symString];
                                
                                NSMutableArray * tmp_ori_Arr  = [allRangeDict objectForKey:FlyTextAllOriRangeKey];
                                NSMutableArray * tmp_show_Arr = [allRangeDict objectForKey:FlyTextAllShowRangeKey];
                                
                                if (!tmp_oriRangeArr) {
                                    tmp_oriRangeArr = [NSMutableArray array];
                                    [oriRangeDic setObject:tmp_oriRangeArr forKey:symString];
                                }
                                if (!tmp_showRangeArr) {
                                    tmp_showRangeArr = [NSMutableArray array];
                                    [showRangeDic setObject:tmp_showRangeArr forKey:symString];
                                }
                                
                                if (!tmp_ori_Arr) {
                                    tmp_ori_Arr = [NSMutableArray array];
                                    [allRangeDict setObject:tmp_ori_Arr forKey:FlyTextAllOriRangeKey];
                                }
                                if (!tmp_show_Arr) {
                                    tmp_show_Arr = [NSMutableArray array];
                                    [allRangeDict setObject:tmp_show_Arr forKey:FlyTextAllShowRangeKey];
                                }
                                
                                [tmp_ori_Arr  addObject:[NSValue valueWithFlyRange:oriRange]];
                                [tmp_show_Arr addObject:[NSValue valueWithFlyRange:showRang]];
                                
                                [tmp_oriRangeArr  addObject:[NSValue valueWithFlyRange:oriRange]];
                                [tmp_showRangeArr addObject:[NSValue valueWithFlyRange:showRang]];
                                
                                currentOriIndex  = FlyMaxRange(oriRange);
                                currentShowIndex = FlyMaxRange(showRang);
                                
                                if (![configDic.allKeys containsObject:symString]) {
                                    symString = @"normal";
                                }
                                
                                NSAttributedString * replaceAttri = [[NSAttributedString alloc] initWithString:showStr attributes:[configDic objectForKey:symString]];
                                [attributedString replaceCharactersInRange:currentRange.toRange withAttributedString:replaceAttri];
                            }
                        }
                    }
                    
                    FlyTextLog4(@"6666\ncurrentOriIndex:%ld\ncurrentShowIndex:%ld\n-----------",currentOriIndex,currentShowIndex);
                    
                    FlyTextLog4(@"--------------end--------------");
                }
            } while (currentShowStr.length >= currentShowIndex && oriString.length >= currentOriIndex);
        }
        
        if (ori_rangeDic) {
            *ori_rangeDic = [oriRangeDic copy];
        }
        if (show_rangeDict) {
            *show_rangeDict = [showRangeDic copy];
        }
        if (all_rangeDict) {
            *all_rangeDict = [allRangeDict copy];
        }
        if (show_attributedStr) {
            *show_attributedStr = [attributedString copy];
        }
        FlyTextLog4(@"\n-----------\nori_str:%@\noriRangeDic:%@\nshowRangeDic:%@\nallRange:%@\n-----------",ori_str,oriRangeDic,showRangeDic,allRangeDict);
    }
}

@end
