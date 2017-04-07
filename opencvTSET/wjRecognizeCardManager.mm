//
//  wjRecognizeCardManager.m
//  opencvTSET
//
//  Created by gouzi on 2017/3/29.
//  Copyright © 2017年 王钧. All rights reserved.
//

#import "wjRecognizeCardManager.h"
#import <TesseractOCR/TesseractOCR.h>


@implementation wjRecognizeCardManager

+ (instancetype)recognizeCardManager {
    static wjRecognizeCardManager *recognizeCardManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recognizeCardManager = [[wjRecognizeCardManager alloc] init];
    });
    return recognizeCardManager;
}


#pragma mark - 得到身份证的的信息(姓名以及号码)
/**
 识别身份证名字
 */
- (void)recognizeCardNameWithImage:(UIImage *)cardImage compleate:(CompleateBlock)compleate {
    // 扫描身份证，并且预处理得到身份证名字的图片
    UIImage *nameImage = [self opencvScanCardWithName:cardImage];
    if (nameImage == nil) {
        compleate(nil);
    }
    // 利用TesseractOCR识别身份证名字
    [self tesseractRecognizeImage:nameImage compleate:^(NSString *nameText) {
        compleate(nameText);
    }];
}

/**
 识别身份证号码
 */
- (void)recognizeCardNumberWithImage:(UIImage *)cardImage compleate:(CompleateBlock)compleate {
    //扫描身份证图片，并进行预处理，定位号码区域图片并返回
    UIImage *numberImage = [self opencvScanCardWithNumber:cardImage];
    if (numberImage == nil) {
        compleate(nil);
    }
    //利用TesseractOCR识别身份证号码
    [self tesseractRecognizeImage:numberImage compleate:^(NSString *numbaerText) {
        compleate(numbaerText);
    }];
}


#pragma mark - 处理图片得到身份证名字图片
- (UIImage *)opencvScanCardWithName:(UIImage *)image {
    cv::Mat resultImage;
    UIImageToMat(image, resultImage);
    cvtColor(resultImage, resultImage, cv::COLOR_BGR2GRAY);
    cv::threshold(resultImage, resultImage, 100, 255, CV_THRESH_BINARY);
    cv::Mat erodeElement = getStructuringElement(cv::MORPH_RECT, cv::Size(27, 27));
    cv::erode(resultImage, resultImage, erodeElement);
    std::vector<std::vector<cv::Point>> contours;//定义一个容器来存储所有检测到的轮廊
    cv::findContours(resultImage, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cvPoint(0, 0));

    //取出身份证名字区域
    std::vector<cv::Rect> nameRects;
    cv::Rect nameRect = cv::Rect(0,0,0,0);
    std::vector<std::vector<cv::Point>>::const_iterator itContours = contours.begin();
    for ( ; itContours != contours.end(); ++itContours) {
        cv::Rect rect = cv::boundingRect(*itContours);
        nameRects.push_back(rect);
        //算法原理
        if (rect.width > rect.height && rect.width < rect.height * 4) {
            nameRect = rect;
        }
    }
    
    // 地址: rect.width > nameRect.width && rect.width > rect.height && rect.width < rect.height * 4
    // 姓名: rect.width > rect.height && rect.width < rect.height * 4
    
    //身份证名字定位失败
    if (nameRect.width == 0 || nameRect.height == 0) {
        return nil;
    }
    //定位成功成功，去原图截取身份证号码区域，并转换成灰度图、进行二值化处理
    cv::Mat matImage;
    UIImageToMat(image, matImage);
    resultImage = matImage(nameRect);
    cvtColor(resultImage, resultImage, cv::COLOR_BGR2GRAY);
    cv::threshold(resultImage, resultImage, 100, 255, CV_THRESH_BINARY);
    //将Mat转换成UIImage
    UIImage *nameImage = MatToUIImage(resultImage);
    return nameImage;
}


#pragma mark - 处理图片得到身份证号码图片
//扫描身份证图片，并进行预处理，定位号码区域图片并返回
- (UIImage *)opencvScanCardWithNumber:(UIImage *)image {
    //将UIImage转换成Mat
    cv::Mat resultImage;
    UIImageToMat(image, resultImage);
    
    //转为灰度图
    cvtColor(resultImage, resultImage, cv::COLOR_BGR2GRAY);
    
    //利用阈值二值化
    cv::threshold(resultImage, resultImage, 100, 255, CV_THRESH_BINARY);
    
    //腐蚀，填充（腐蚀是让黑色点变大）
    cv::Mat erodeElement = getStructuringElement(cv::MORPH_RECT, cv::Size(27,27));
    cv::erode(resultImage, resultImage, erodeElement);
   
    //轮廊检测
    std::vector<std::vector<cv::Point>> contours;//定义一个容器来存储所有检测到的轮廊
    cv::findContours(resultImage, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cvPoint(0, 0));
    //cv::drawContours(resultImage, contours, -1, cv::Scalar(255),4);
    //取出身份证号码区域
    std::vector<cv::Rect> rects;
    cv::Rect numberRect = cv::Rect(0,0,0,0);
    std::vector<std::vector<cv::Point>>::const_iterator itContours = contours.begin();
    for ( ; itContours != contours.end(); ++itContours) {
        cv::Rect rect = cv::boundingRect(*itContours);
        rects.push_back(rect);
        //算法原理
        if (rect.width > numberRect.width && rect.width > rect.height * 5) {
            numberRect = rect;
        }
    }
    
    //身份证号码定位失败
    if (numberRect.width == 0 || numberRect.height == 0) {
        return nil;
    }
    //定位成功成功，去原图截取身份证号码区域，并转换成灰度图、进行二值化处理
    cv::Mat matImage;
    UIImageToMat(image, matImage);
    resultImage = matImage(numberRect);
    cvtColor(resultImage, resultImage, cv::COLOR_BGR2GRAY);
    cv::threshold(resultImage, resultImage, 80, 255, CV_THRESH_BINARY);
    //将Mat转换成UIImage
    UIImage *numberImage = MatToUIImage(resultImage);
    return numberImage;
}


#pragma mark - 识别文字或者数字
//利用TesseractOCR识别文字
- (void)tesseractRecognizeImage:(UIImage *)image compleate:(CompleateBlock)compleate {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"chi_sim"];
//        tesseract.image = [image g8_blackAndWhite];
        if (image == nil) {
            NSLog(@"图片没有处理成功");
            return;
        }
        tesseract.image = image;
        // Start the recognition
        BOOL done = [tesseract recognize];
        //执行回调
        compleate(tesseract.recognizedText);
    });
}


@end
