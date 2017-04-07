//
//  wjRecognizeCardManager.h
//  opencvTSET
//
//  Created by gouzi on 2017/3/29.
//  Copyright © 2017年 王钧. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIImage;

typedef void (^CompleateBlock)(NSString *text);

@interface wjRecognizeCardManager : NSObject


/**
 *  初始化一个单例
 *
 *  @return 返回一个RecogizeCardManager的实例对象
 */
+ (instancetype)recognizeCardManager;


/**
 根据身份证照片得到身份证名字

 @param cardImage 传入的身份证照片
 @param compleate 识别完成后的回调
 */
- (void)recognizeCardNameWithImage:(UIImage *)cardImage compleate:(CompleateBlock)compleate;

/**
 *  根据身份证照片得到身份证号码
 *
 *  @param cardImage 传入的身份证照片
 *  @param compleate 识别完成后的回调
 */
- (void)recognizeCardNumberWithImage:(UIImage *)cardImage compleate:(CompleateBlock)compleate;

/**
 识别身份证名字

 @param image 传入的身份证的照片
 @return 识别完成后返回的身份证名字的图片
 */
- (UIImage *)opencvScanCardWithName:(UIImage *)image;

/**
 识别身份证号码

 @param image 传入的图片
 @return 返回的已经被处理的身份证号码的图片
 */
- (UIImage *)opencvScanCardWithNumber:(UIImage *)image;




@end
