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
@property(nonatomic,strong)NSTimer *timer;  //录音声波监控定时器
@property(nonatomic,strong)AVAudioPlayer *audioPlayer;  //录音播放器
@property(nonatomic,strong)NSURL *recordLocalPath;   //录音路径
@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setAudioSession];
    [self imageAniamtion];
}


/**
 设置音频会话
 */
- (void)setAudioSession
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //设置为播放和录音状态,以便可以在录制完成之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
}



/**
 获取录音文件保存路径

 @return url
 */
- (NSURL *)createRecordFilePath
{
    NSString *documenDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingString:@"/MJLPathMainAudioCacheFile"];
    NSString *fileName = [NSString stringWithFormat:@"%@.mp4",[self currentTimeTerval]];
    
    NSString *localFilePath = [documenDirectory stringByAppendingPathComponent:fileName];
    NSLog(@"本次语音路径:%@",localFilePath);
    
    //判断是否存在
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:documenDirectory]) {
        [manager createDirectoryAtPath:documenDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSURL *url = [NSURL fileURLWithPath:localFilePath];
    return url;
}


/**
 获取录音文件设置

 @return 设置
 */
- (NSDictionary *)createRecordSettings
{
    //录音设置
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc]init];
    //1.设置编码格式
    [recordSettings setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    //2.采样频率
    [recordSettings setValue:[NSNumber numberWithFloat:11025.0] forKey:AVSampleRateKey];
    
    //3.声道数
    [recordSettings setValue:[NSNumber numberWithUnsignedInt:2] forKey:AVNumberOfChannelsKey];
    //4.采样位数
    [recordSettings setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSettings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    return recordSettings;
}


- (NSString *)currentTimeTerval
{
    NSDate *now = [NSDate date];
    NSTimeInterval timeInterval = [now timeIntervalSinceReferenceDate];
    
    NSString *timeString = [NSString stringWithFormat:@"%lf",timeInterval];
    timeString = [timeString stringByReplacingOccurrencesOfString:@"." withString:@""];
    
    return timeString;
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
    
    if (!self.recorder.isRecording) {
        [self.recorder record];
        [self.recordImageView startAnimating];
        self.timer.fireDate = [NSDate distantPast];
    }
 
}


//录音结束
- (IBAction)stopRecordBtn:(id)sender {
    [self.recorder stop];
    [self.recordImageView stopAnimating];
    self.timer.fireDate = [NSDate distantFuture];
    self.powerProgressView.progress = 0.0;
}

//暂停录音
- (IBAction)pauseRecord:(id)sender {
    
    
    if ([self.recorder isRecording]) {
        [self.recorder pause];
        self.timer.fireDate = [NSDate distantFuture];
    }
    
}
//恢复录音
//恢复录音只需要再次调用record,Session会帮助你记录上次录音位置并追加录音
- (IBAction)resumeRecord:(id)sender {
    
    [self startRecordBtn:sender];
}


- (void)audioPowerChange
{
    [self.recorder updateMeters];
    float power = [self.recorder averagePowerForChannel:0];
    CGFloat progress = (1.0/160.0)*(power + 160.0);
    self.powerProgressView.progress = progress;
}

- (AVAudioRecorder *)recorder
{
    if (!_recorder) {
        
        NSURL *url = [self createRecordFilePath];
        self.recordLocalPath = url;
        NSDictionary *settings = [self createRecordSettings];
        NSError *error = nil;
        _recorder = [[AVAudioRecorder alloc]initWithURL:url settings:settings error:&error];
        [_recorder prepareToRecord];

        _recorder.delegate = self;
        _recorder.meteringEnabled = YES;    //如果需要监控声波
        if (error) {
            NSLog(@"初始化录音时失败:%@",error);
            return nil;
        }
    }
    return _recorder;
}

- (NSTimer *)timer
{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(audioPowerChange) userInfo:nil repeats:YES];
    }
    return _timer;
}


- (AVAudioPlayer *)audioPlayer
{
    if (!_audioPlayer) {
        NSError *error = nil;
        _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:self.recordLocalPath error:&error];
        _audioPlayer.numberOfLoops = 0;
        [_audioPlayer prepareToPlay];
        if (error) {
            NSLog(@"创建录音播放器失败:%@",error.localizedDescription);
            return nil;
        }
        
        
    }
    return _audioPlayer;
}

#pragma mark -AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSLog(@"录音完成后播放");
    if (![self.audioPlayer isPlaying]) {
        [self.audioPlayer play];
    }
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
