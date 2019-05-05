//
//  FlyTextToolManager.m
//  FlyTextToolManager+Demo
//
//  Created by Fly on 2019/4/30.
//  Copyright © 2019 Fly. All rights reserved.
//

#import "FlyTextToolManager.h"

@implementation FlyTextToolManager

+ (BOOL)fly_isIntersectRange:(NSRange)range1 range:(NSRange)range2 {
    
    BOOL result = NO;
    if (((range1.location > range2.location) && (range1.location - range2.location) < range2.length) || ((range2.location > range1.location) && (range2.location - range1.location) < range1.length)) {
        result = YES;
    }
    return result;
}

+ (void)fly_changStringWithOriText:(NSString **)ori_text
                       selectRange:(NSRange *)selected_range
                     attributedStr:(NSAttributedString **)show_attributedStr
                       oriRangeDic:(NSDictionary **)ori_rangeDic
                      showRangeDic:(NSDictionary **)show_rangeDic
                      replaceRange:(NSRange)replaceRange
                       replaceText:(NSString *)replaceText
                        symbolsDic:(NSDictionary *)symbolsDic
                        configDict:(NSDictionary *)configDic
                       converBlock:(NSString *(^)(NSString * contentStr, NSInteger inputType))converBlock {
    
    NSString * oriText = [*ori_text copy];
    NSMutableDictionary * oriRangeDic  = [*ori_rangeDic mutableCopy];
    NSMutableDictionary * showRangeDic = [*show_rangeDic mutableCopy];
    NSMutableAttributedString * showAttributedString = [*show_attributedStr mutableCopy];
    
    if (!oriRangeDic) {
        oriRangeDic = [NSMutableDictionary dictionary];
    }
    if (!showRangeDic) {
        showRangeDic = [NSMutableDictionary dictionary];
    }
    if (!oriRangeDic) {
        oriRangeDic = [NSMutableDictionary dictionary];
    }
    
    if ([oriText isKindOfClass:[NSString class]] && [replaceText isKindOfClass:[NSString class]]) {
        
        NSRange showReplaceRange = replaceRange;
        NSRange oriReplaceRange  = replaceRange;
        NSRange selectedRange    = NSMakeRange(replaceRange.location, 0);
        NSRange should_showReplaceRange = NSMakeRange(0, showAttributedString.length + replaceText.length - replaceRange.length);
        
        NSArray * keyArr = showRangeDic.allKeys;
        for (NSString * key in keyArr) {
            
            @autoreleasepool {
                
                NSArray * tmp_oriArr  = [[oriRangeDic  objectForKey:key] copy];
                NSArray * tmp_showArr = [[showRangeDic objectForKey:key] copy];
                
                //因为用户一般都是继续输入，为了减少遍历次数，此处选用倒序
                for (NSInteger index = (tmp_showArr.count - 1); index >= 0; index --) {
                    
                    NSValue * tmp_oriValue  = [tmp_oriArr objectAtIndex:index];
                    NSValue * tmp_showValue = [tmp_showArr objectAtIndex:index];
                    NSRange tmp_oriRange    = [tmp_oriValue rangeValue];
                    NSRange tmp_showRange   = [tmp_showValue rangeValue];
                    if ([self fly_isIntersectRange:replaceRange range:tmp_showRange]) {//在中间
                        oriReplaceRange.location  = MIN(replaceRange.location - tmp_showRange.location + tmp_oriRange.location, tmp_oriRange.location);
                        oriReplaceRange.length    = MAX(NSMaxRange(oriReplaceRange), NSMaxRange(tmp_oriRange)) - oriReplaceRange.location;
                        
                        NSLog(@" 中\n--->>>>\ncurrentText : %@\nreplaceText : %@\nreplaceRange : %@\ntmp_showRange : %@\noriReplaceRange : %@\n----->>>\n",[[showAttributedString string] substringWithRange:tmp_showRange],replaceText,[NSValue valueWithRange:replaceRange],[NSValue valueWithRange:tmp_showRange],[NSValue valueWithRange:oriReplaceRange]);
                        
                        showReplaceRange.location = MIN(showReplaceRange.location, tmp_showRange.location);
                        showReplaceRange.length   = MAX(NSMaxRange(showReplaceRange), NSMaxRange(tmp_showRange)) - showReplaceRange.location;
                        should_showReplaceRange   = showReplaceRange;
                        
                        NSMutableArray * tmp_oriRangeArr = [tmp_oriArr mutableCopy];
                        [tmp_oriRangeArr removeObjectAtIndex:index];
                        [oriRangeDic setObject:tmp_oriRangeArr forKey:key];
                        
                        NSMutableArray * tmp_showRangeArr = [tmp_showArr mutableCopy];
                        [tmp_showRangeArr removeObjectAtIndex:index];
                        [showRangeDic setObject:tmp_showRangeArr forKey:key];
                        
                        break;
                    } else {
                        
                        if (NSMaxRange(tmp_showRange) <= replaceRange.location) {//在后面
                            
                            NSInteger tmp_oriPlaceLocal = replaceRange.location - NSMaxRange(tmp_showRange) + NSMaxRange(tmp_oriRange);
                            oriReplaceRange.location = MIN(tmp_oriPlaceLocal, oriReplaceRange.location);
                            
                            NSLog(@" 后\n--->>>>\ncurrentText : %@\nreplaceText : %@\nreplaceRange : %@\ntmp_showRange : %@\noriReplaceRange : %@\n----->>>\n",[[showAttributedString string] substringWithRange:tmp_showRange],replaceText,[NSValue valueWithRange:replaceRange],[NSValue valueWithRange:tmp_showRange],[NSValue valueWithRange:oriReplaceRange]);
                            
                            //更新后面这些文字是否有可变的,此时showReplaceRange不变
                            NSInteger tmp_should_location  = MAX(NSMaxRange(tmp_showRange), should_showReplaceRange.location);
                            should_showReplaceRange.length = NSMaxRange(should_showReplaceRange) - tmp_should_location;
                            should_showReplaceRange.location = tmp_should_location;
                            
                            break;
                        } else {//在前面
                            //更新前面这些文字是否有可变的,此时showReplaceRange不变
                            should_showReplaceRange.length = MIN(should_showReplaceRange.length, tmp_showRange.location - should_showReplaceRange.location);
                        }
                    }
                }
            }
            
            if (!NSEqualRanges(showReplaceRange, replaceRange)) {
                break;
            }
        }
        
        NSLog(@"转换前\n------>>>>\noriRangeDic:\n%@\nshowRangeDic:\n%@\nselectedRange:\n%@\n------>>>>\n",oriRangeDic,showRangeDic,[NSValue valueWithRange:selectedRange]);
        
        if (NSMaxRange(oriReplaceRange) > oriText.length) {
            oriReplaceRange.location = oriText.length - oriReplaceRange.length;
        }
        if (NSMaxRange(showReplaceRange) > showAttributedString.length) {
            showReplaceRange.location = showAttributedString.length - showReplaceRange.length;
        }
        
        oriText = [oriText stringByReplacingCharactersInRange:oriReplaceRange withString:replaceText];
        [showAttributedString replaceCharactersInRange:showReplaceRange withString:replaceText];
        
        //        NSLog(@"\n---->>>>\noriText:\n  %@\nshowString:\n  %@\n---->>>>\n",oriText,showAttributedString.string);
        
        selectedRange.location = showReplaceRange.location + replaceText.length;
        
        should_showReplaceRange.length = should_showReplaceRange.length + replaceText.length - replaceRange.length;
        
        //前或后
        if (NSEqualRanges(showReplaceRange, replaceRange) && replaceText.length > 0 && NSMaxRange(should_showReplaceRange) <= showAttributedString.length) {
            
            NSInteger oriLength  = oriText.length;
            NSInteger showLength = showAttributedString.length;
            NSDictionary * replaceOriDic  = nil;
            NSDictionary * replaceShowDic = nil;
            NSAttributedString * replaceAttri = [showAttributedString attributedSubstringFromRange:should_showReplaceRange];
            
            NSString * replaceOriStr = [replaceAttri string];
            
            [self fly_symbolRangsWithString:replaceOriStr oriRangeDic:&replaceOriDic showRangeDic:&replaceShowDic attributedStr:&replaceAttri symbolsDic:symbolsDic configDict:configDic converBlock:converBlock];
            
            [showAttributedString replaceCharactersInRange:should_showReplaceRange withAttributedString:replaceAttri];
            
            selectedRange.location += replaceAttri.length - should_showReplaceRange.length;
            
            //更新range字典内数据
            NSMutableArray * keyArr = [oriRangeDic.allKeys mutableCopy];
            for (NSString * replaceKey in replaceOriDic.allKeys) {
                if (![keyArr containsObject:replaceKey]) {
                    [keyArr addObject:replaceKey];
                }
            }
            
            for (NSString * key in keyArr) {
                
                NSMutableArray * tmpShowArr = [[showRangeDic objectForKey:key] mutableCopy];
                NSMutableArray * tmpOriArr  = [[oriRangeDic objectForKey:key] mutableCopy];
                
                if (!tmpShowArr) {
                    tmpShowArr = [NSMutableArray array];
                }
                if (!tmpOriArr) {
                    tmpOriArr = [NSMutableArray array];
                }
                
                NSMutableArray * tmpReplaceShowArr = [[replaceShowDic objectForKey:key] mutableCopy];
                NSMutableArray * tmpReplaceOriArr  = [[replaceOriDic objectForKey:key] mutableCopy];
                
                for (NSInteger i = 0; i < tmpReplaceShowArr.count; i ++) {
                    
                    NSValue * tmp_showValue = [tmpReplaceShowArr objectAtIndex:i];
                    NSValue * tmp_oriValue  = [tmpReplaceOriArr objectAtIndex:i];
                    
                    NSRange tmp_showRange = [tmp_showValue rangeValue];
                    NSRange tmp_oriRange  = [tmp_oriValue rangeValue];
                    
                    tmp_showRange.location = tmp_showRange.location + should_showReplaceRange.location;
                    tmp_oriRange.location  = tmp_oriRange.location + should_showReplaceRange.location + (oriLength - showLength);
                    
                    tmp_showValue = [NSValue valueWithRange:tmp_showRange];
                    tmp_oriValue  = [NSValue valueWithRange:tmp_oriRange];
                    
                    [tmpReplaceShowArr replaceObjectAtIndex:i withObject:tmp_showValue];
                    [tmpReplaceOriArr replaceObjectAtIndex:i withObject:tmp_oriValue];
                }
                
                NSInteger totalCount = tmpOriArr.count + tmpReplaceOriArr.count;
                for (NSInteger i = 0; i < totalCount; i ++) {
                    
                    if (i < tmpOriArr.count) {
                        
                        NSValue * tmp_showValue = [tmpShowArr objectAtIndex:i];
                        NSValue * tmp_oriValue  = [tmpOriArr objectAtIndex:i];
                        
                        NSRange tmp_showRange = [tmp_showValue rangeValue];
                        NSRange tmp_oriRange  = [tmp_oriValue rangeValue];
                        
                        if (tmp_oriRange.location >= NSMaxRange(oriReplaceRange)) {
                            tmp_showRange.location = tmp_showRange.location + replaceAttri.length - should_showReplaceRange.length + replaceText.length - showReplaceRange.length;
                            tmp_oriRange.location  = tmp_oriRange.location - oriReplaceRange.length + replaceText.length;
                            
                            tmp_showValue = [NSValue valueWithRange:tmp_showRange];
                            tmp_oriValue  = [NSValue valueWithRange:tmp_oriRange];
                            [tmpShowArr replaceObjectAtIndex:i withObject:tmp_showValue];
                            [tmpOriArr  replaceObjectAtIndex:i withObject:tmp_oriValue];
                        }
                        
                        if (tmpReplaceShowArr.count > 0 && tmpReplaceOriArr.count > 0) {
                            NSValue * tmp_replace_showValue = tmpReplaceShowArr.firstObject;
                            NSValue * tmp_replace_oriValue  = tmpReplaceOriArr.firstObject;
                            
                            NSRange tmp_replace_showRange = [tmp_replace_showValue rangeValue];
                            NSRange tmp_replace_oriRange  = [tmp_replace_oriValue rangeValue];
                            
                            if (tmp_replace_oriRange.location < tmp_oriRange.location) {
                                [tmpOriArr  insertObject:tmp_replace_oriValue  atIndex:i];
                                [tmpShowArr insertObject:tmp_replace_showValue atIndex:i];
                                [tmpReplaceShowArr removeObjectAtIndex:0];
                                [tmpReplaceOriArr  removeObjectAtIndex:0];
                                i ++;
                            } else {
                                if (i == tmpOriArr.count - 1) {
                                    [tmpOriArr addObjectsFromArray:tmpReplaceOriArr];
                                    [tmpShowArr addObjectsFromArray:tmpReplaceShowArr];
                                    [tmpReplaceOriArr removeAllObjects];
                                    [tmpReplaceShowArr removeAllObjects];
                                }
                            }
                        }
                    }
                }
                
                //将整合后的数据重新存起来
                [showRangeDic setObject:tmpShowArr forKey:key];
                [oriRangeDic  setObject:tmpOriArr  forKey:key];
            }
        }
        
        selectedRange.location = MIN(showAttributedString.length - selectedRange.length, selectedRange.location);
        
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
        
        NSLog(@"转换后\n------>>>>\noriRangeDic:\n%@\nshowRangeDic:\n%@\nselectedRange:\n%@\n------>>>>\n",oriRangeDic,showRangeDic,[NSValue valueWithRange:selectedRange]);
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
+ (void)fly_symbolRangsWithString:(NSString *)ori_str
                      oriRangeDic:(NSDictionary **)ori_rangeDic
                     showRangeDic:(NSDictionary **)show_rangeDict
                    attributedStr:(NSAttributedString **)show_attributedStr
                       symbolsDic:(NSDictionary *)symbolsDic
                       configDict:(NSDictionary *)configDic
                      converBlock:(NSString *(^)(NSString * contentStr, NSInteger inputType))converBlock {
    
    NSString * resultStr = ori_str;
    NSMutableAttributedString * attributedString = nil;
    if (!resultStr) {
        resultStr = [*show_attributedStr string];
    }
    if ([resultStr isKindOfClass:[NSString class]] && [symbolsDic isKindOfClass:[NSDictionary class]] && symbolsDic.count > 0) {
        NSMutableDictionary * showRangeDic = [NSMutableDictionary dictionary];
        NSMutableDictionary * oriRangeDic  = [NSMutableDictionary dictionary];
        
        NSString * firstSymbol = @"";
        NSString * lastSymbol  = @"";
        NSString * symString   = @"";
        NSString * showStr     = @"";
        NSString * textStr     = resultStr;
        
        NSRange firstRang = NSMakeRange(0, 0);
        NSRange lastRang  = NSMakeRange(0, 0);
        NSRange oriFirstRang = firstRang;
        NSRange oriLastRang  = lastRang;
        
        NSInteger insertType = 0;
        
        if (ori_str) {
            attributedString = [[NSMutableAttributedString alloc] initWithString:resultStr attributes:[configDic objectForKey:@"normal"]];
        } else if (show_attributedStr && *show_attributedStr) {
            attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:*show_attributedStr];
        }
        do {
            @autoreleasepool {
                
                NSRange currentRang = NSMakeRange(firstRang.location, NSMaxRange(lastRang) - firstRang.location);//需要替换的range
                NSRange oriRange    = NSMakeRange(oriFirstRang.location, NSMaxRange(oriLastRang) - oriFirstRang.location);
                NSRange showRang    = NSMakeRange(NSMaxRange(firstRang), lastRang.location - NSMaxRange(firstRang));
                
                NSString * contentStr = [textStr substringWithRange:showRang];
                if (converBlock && contentStr.length > 0 && insertType != 0) {
                    showStr = converBlock(contentStr, insertType);
                }
                if (![showStr isKindOfClass:[NSString class]]) {
                    showStr = @"";
                }
                
                textStr = [textStr stringByReplacingCharactersInRange:currentRang withString:showStr];
                
                showRang.location = showRang.location - firstSymbol.length;
                showRang.length   = showStr.length;
                
                //存数据
                if (symString.length && NSMaxRange(showRang) > 0 && NSMaxRange(oriRange) > 0) {
                    
                    NSMutableArray * tmp_oriRangeArr  = [oriRangeDic  objectForKey:symString];
                    NSMutableArray * tmp_showRangeArr = [showRangeDic objectForKey:symString];
                    
                    if (!tmp_oriRangeArr) {
                        tmp_oriRangeArr = [NSMutableArray array];
                        [oriRangeDic setObject:tmp_oriRangeArr forKey:symString];
                    }
                    if (!tmp_showRangeArr) {
                        tmp_showRangeArr = [NSMutableArray array];
                        [showRangeDic setObject:tmp_showRangeArr forKey:symString];
                    }
                    
                    [tmp_oriRangeArr  addObject:[NSValue valueWithRange:oriRange]];
                    [tmp_showRangeArr addObject:[NSValue valueWithRange:showRang]];
                    
                    if (![configDic.allKeys containsObject:symString]) {
                        symString = @"normal";
                    }
                    
                    [attributedString replaceCharactersInRange:currentRang withAttributedString:[[NSAttributedString alloc] initWithString:showStr attributes:[configDic objectForKey:symString]]];
                }
                
                //重新赋值，准备下一次循环
                firstRang = NSMakeRange(NSIntegerMax, 0);
                lastRang  = NSMakeRange(NSIntegerMax, 0);
                
                for (NSArray * subSymbolArr in symbolsDic.allKeys) {
                    
                    NSString * tmp_firstSymbol = subSymbolArr.firstObject;
                    NSString * tmp_lastSymbol  = subSymbolArr.lastObject;
                    
                    NSRange tmp_firstRang = [textStr rangeOfString:tmp_firstSymbol];
                    NSRange tmp_lastRang  = [textStr rangeOfString:tmp_lastSymbol];
                    
                    if (tmp_lastRang.location < tmp_firstRang.location && textStr.length > NSMaxRange(tmp_firstRang)) {
                        tmp_lastRang = [textStr rangeOfString:tmp_lastSymbol options:NSLiteralSearch range:NSMakeRange(NSMaxRange(tmp_firstRang), textStr.length - NSMaxRange(tmp_firstRang))];
                    }
                    //                                        NSLog(@"111111\n---->>>>\nfirstRang:%@\nlastRang:%@\nfirstSymbol:%@\nlastSymbol:%@\ntextStr:%@\n---->>>>\n",[NSValue valueWithRange:firstRang],[NSValue valueWithRange:lastRang],firstSymbol,lastSymbol,textStr);
                    if ((firstRang.location > tmp_firstRang.location) && NSMaxRange(tmp_lastRang) > 0) {
                        firstRang   = tmp_firstRang;
                        lastRang    = tmp_lastRang;
                        firstSymbol = tmp_firstSymbol;
                        lastSymbol  = tmp_lastSymbol;
                        insertType  = [[symbolsDic objectForKey:subSymbolArr] integerValue];
                        //                                            NSLog(@"2222222\n---->>>>\nfirstRang:%@\nlastRang:%@\nfirstSymbol:%@\nlastSymbol:%@\ntextStr:%@\n---->>>>\n",[NSValue valueWithRange:firstRang],[NSValue valueWithRange:lastRang],firstSymbol,lastSymbol,textStr);
                    }
                }
                symString = [firstSymbol stringByAppendingString:lastSymbol];
                //                                NSLog(@"33333\n---->>>>\nfirstRang:%@\nlastRang:%@\nfirstSymbol:%@\nlastSymbol:%@\ntextStr:%@\n---->>>>\n",[NSValue valueWithRange:firstRang],[NSValue valueWithRange:lastRang],firstSymbol,lastSymbol,textStr);
                if (firstRang.location < textStr.length && resultStr.length > NSMaxRange(oriFirstRang)) {
                    
                    oriFirstRang = [resultStr rangeOfString:firstSymbol options:NSLiteralSearch range:NSMakeRange(NSMaxRange(oriFirstRang), resultStr.length - NSMaxRange(oriFirstRang))];
                    oriLastRang  = [resultStr rangeOfString:lastSymbol options:NSLiteralSearch range:NSMakeRange(NSMaxRange(oriFirstRang), resultStr.length - NSMaxRange(oriFirstRang))];
                    //                                        NSLog(@"44444\n---->>>>\noriFirstRang:%@\noriLastRang:%@\nsymString:%@\nresultStr:%@\n---->>>>\n",[NSValue valueWithRange:oriFirstRang],[NSValue valueWithRange:oriLastRang],symString,resultStr);
                }
            }
        } while (firstRang.length != 0 && lastRang.length != 0 && lastRang.location > NSMaxRange(firstRang));
        
        resultStr = textStr;
        
        if (ori_rangeDic) {
            *ori_rangeDic = [oriRangeDic copy];
        }
        if (show_rangeDict) {
            *show_rangeDict = [showRangeDic copy];
        }
        if (show_attributedStr) {
            *show_attributedStr = [attributedString copy];
        }
    }
}

@end
