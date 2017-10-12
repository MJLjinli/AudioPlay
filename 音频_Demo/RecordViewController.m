//
//  RecordViewController.m
//  音频_Demo
//
//  Created by 马金丽 on 17/10/11.
//  Copyright © 2017年 majinli. All rights reserved.
//

#import "RecordViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface RecordViewController ()<AVAudioRecorderDelegate>


@property(nonatomic,strong)AVAudioRecorder *recorder;//录音对象
@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self createRecorder];
    [self imageAniamtion];
}


- (void)createRecorder
{
    //录音文件的路径
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"recordFile.wav"];
    NSURL *url = [NSURL URLWithString:path];
    NSLog(@"录音地址:%@",url);
    //录音设置
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc]init];
    //1.设置编码格式
    [recordSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    //2.采样频率
    [recordSettings setValue:[NSNumber numberWithFloat:11025.0] forKey:AVSampleRateKey];
    
    //3.声道数
    [recordSettings setValue:[NSNumber numberWithUnsignedInt:2] forKey:AVNumberOfChannelsKey];
    //4.采样位数
    [recordSettings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    //创建录音对象
    self.recorder = [[AVAudioRecorder alloc]initWithURL:url settings:recordSettings error:nil];
    self.recorder.delegate = self;
    //准备录音
    [self.recorder prepareToRecord];
}



-(void)imageAniamtion
{
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    for (int i = 0; i < 4; i++) {
        NSString *imageName = [NSString stringWithFormat:@"recorda0%d",i];
        UIImage *image = [UIImage imageNamed:imageName];
        [arr addObject:image];
    }
    self.recordImageView.animationImages = arr;
    self.recordImageView.animationRepeatCount = 0;
    self.recordImageView.animationDuration = 3.0;
}
//返回
- (IBAction)backBtn:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

//录音开始
- (IBAction)startRecordBtn:(id)sender {
    
    [self.recorder record];
    [self.recordImageView startAnimating];
}


//录音结束
- (IBAction)stopRecordBtn:(id)sender {
    [self.recorder stop];
    
}


#pragma mark -AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSLog(@"录音完成");
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"录音出错");
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
