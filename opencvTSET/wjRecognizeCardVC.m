//
//  wjRecognizeCardVC.m
//  opencvTSET
//
//  Created by gouzi on 2017/3/29.
//  Copyright © 2017年 王钧. All rights reserved.
//

#import "wjRecognizeCardVC.h"
#import "wjRecognizeCardManager.h"

@interface wjRecognizeCardVC () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *darkNumberImageView;
@property (weak, nonatomic) IBOutlet UILabel *genderLabel;
@property (nonatomic, strong) UIImagePickerController *imgagePickController;

@end

@implementation wjRecognizeCardVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self someBasicSettings];
}

- (void)someBasicSettings {
    self.imgagePickController = [[UIImagePickerController alloc] init];
    self.imgagePickController.delegate = self;
    self.imgagePickController.allowsEditing = YES;
}


/**
 打开相册
 */
- (IBAction)photoGraphAction:(UIButton *)sender {
    self.imgagePickController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:self.imgagePickController animated:YES completion:nil];
}


/**
 打开照相机
 */
- (IBAction)takePhoto:(UIButton *)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imgagePickController.sourceType = UIImagePickerControllerSourceTypeCamera;
        //设置摄像头模式（拍照，录制视频）为拍照
        self.imgagePickController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        [self presentViewController:self.imgagePickController animated:YES completion:nil];
    } else {
        NSLog(@"不能打开摄像机");
    }
}


#pragma mark - delegate 
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
//    NSLog(@"info is %@", info);
    NSString *mediaType=[info objectForKey:UIImagePickerControllerMediaType];
    UIImage *srcImage = nil;
    //判断资源类型
    if ([mediaType isEqualToString:@"public.image"]){
        srcImage = info[UIImagePickerControllerEditedImage];
        self.imageView.image = srcImage;
        [self.view bringSubviewToFront:self.textLabel];
        self.darkNumberImageView.image = [[wjRecognizeCardManager recognizeCardManager] opencvScanCardWithNumber:srcImage];
        //识别身份证
        self.textLabel.text = @"图片插入成功，正在识别中...";
        // 识别身份证号码
        [[wjRecognizeCardManager recognizeCardManager] recognizeCardNumberWithImage:srcImage compleate:^(NSString *text) {
            if (text.length) {
                if ([text isValidIdCardNum]) {
                    self.textLabel.text = [NSString stringWithFormat:@"识别结果：%@",text];
                    self.genderLabel.text = [self judgeGenderWithIdNumber:text];
                    
                } else {
                    self.textLabel.text = [NSString stringWithFormat:@"识别结果:识别的号码并不是身份证号码\n 号码为 : %@\n", text];
                }
                
            }else {
                self.textLabel.text = @"请选择照片";
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"照片识别失败，请选择清晰、没有复杂背景的身份证照片重试！" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles: nil];
//                [alert show];
            }
        }];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - 判断性别
- (NSString *)judgeGenderWithIdNumber:(NSString *)idNumber {
    NSInteger genderNumber = [[idNumber substringWithRange:NSMakeRange(16, 1)] integerValue];
    if (genderNumber % 2 == 0) {
        return [NSString stringWithFormat:@"性别:%@", @"女"];
    } else {
        return [NSString stringWithFormat:@"性别:%@", @"男"];
    }
}





//进入拍摄页面点击取消按钮
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
