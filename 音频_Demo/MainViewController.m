//
//  MainViewController.m
//  音频_Demo
//
//  Created by 马金丽 on 17/10/11.
//  Copyright © 2017年 majinli. All rights reserved.
//

#import "MainViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "RecordViewController.h"
@interface MainViewController ()
@property(nonatomic,strong)AVPlayer *player;
@property(nonatomic,strong)NSMutableArray *musicUrlArray;
@property(nonatomic,assign)NSInteger currentIndex;
@property(nonatomic,strong)NSMutableArray *musicNameArray;
@property(nonatomic,strong)AVPlayerItem *playItem;
@end

@implementation MainViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self setupUI];
    //默认播放第一个
    [self playLocalResoucewithIndex:0];
    [self startAnimationWithImageView:self.mainImageView];
    self.musicNameLabel.text = [self.musicNameArray objectAtIndex:0];

    //监听播放进度
    __weak typeof(self) weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        CGFloat current = CMTimeGetSeconds(time);
        CGFloat total = CMTimeGetSeconds(weakSelf.playItem.duration);
        weakSelf.musicProgressView.progress = current/total;
    }];
}

//播放
- (IBAction)playMusic:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.player pause];
        [sender setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [self pauseAnimationWithImageView:self.mainImageView];
    }else{
        [self.player play];
          [sender setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [self startAnimationWithImageView:self.mainImageView];

    }
}

//上一首
- (IBAction)lastBtn:(id)sender {
    if (self.currentIndex <= 0) {
        return;
    }
    self.currentIndex -= 1;
    if (self.currentIndex <= 0) {
        return;
    }
    [self playLocalResoucewithIndex:self.currentIndex];
    self.musicNameLabel.text = [self.musicNameArray objectAtIndex:self.currentIndex];

    
}

//下一首
- (IBAction)nextBtn:(id)sender {
    
    self.currentIndex +=1;
    if (self.currentIndex >= self.musicUrlArray.count) {
        return;
    }
    [self playLocalResoucewithIndex:self.currentIndex];
    self.musicNameLabel.text = [self.musicNameArray objectAtIndex:self.currentIndex];

}

//从后台回到前台
- (void)applicationWillEnterForeground
{
    [self initAnimationWithImageView:self.mainImageView onSpeed:0.05];
    [self startAnimationWithImageView:self.mainImageView];
}
//播放完成
- (void)playBackFinish:(NSNotification *)notice
{
    [self nextBtn:nil];
}

//初始化数据
- (void)initData
{
    self.currentIndex = 0;
    NSArray *nameArr = @[@"暗杠-童话镇",@"Taylor Swift-You Belong With Me (52届格莱美提名歌曲)",@"G.E.M. 邓紫棋-喜欢你 (原唱: Beyond)",@"庄心妍-以后的以后"];
    self.musicNameArray = [nameArr mutableCopy];
    for (NSString *nameStr in nameArr) {
        NSString *lacalStr = [[NSBundle mainBundle] pathForResource:nameStr ofType:@"mp3"];
        NSURL *fileUrl = [NSURL fileURLWithPath:lacalStr];
        [self.musicUrlArray addObject:fileUrl];
    }
    
}

//初始化UI
- (void)setupUI
{
    self.playBtn.layer.cornerRadius = 25;
    self.playBtn.layer.masksToBounds = YES;
    [self.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    self.mainImageView.layer.cornerRadius = 80;
    self.mainImageView.layer.masksToBounds = YES;
    
    [self initAnimationWithImageView:self.mainImageView onSpeed:0.05];
}

//初始化动画
- (void)initAnimationWithImageView:(UIImageView *)imageView onSpeed:(CGFloat)speed
{
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI *speed];
    rotationAnimation.duration = 0.2;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = FLT_MAX;
    [imageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];

}

//启动动画
- (void)startAnimationWithImageView:(UIImageView *)imageView
{
    CFTimeInterval pausedTime = [imageView.layer timeOffset];
    imageView.layer.speed = 1.0;
    imageView.layer.timeOffset = 0.0;
    imageView.layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [imageView.layer convertTime:CACurrentMediaTime() fromLayer:nil]-pausedTime;
    imageView.layer.beginTime = timeSincePause;
}

//暂停动画
- (void)pauseAnimationWithImageView:(UIImageView *)imageView
{
    CFTimeInterval pausedTime = [imageView.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    imageView.layer.speed = 0.0;
    imageView.layer.timeOffset = pausedTime;
}

- (AVPlayer *)player
{
    if (!_player) {
        _player = [[AVPlayer alloc]init];
        _player.volume = 1.0;
    }
    return _player;
}

- (NSMutableArray *)musicUrlArray
{
    if (!_musicUrlArray) {
        _musicUrlArray = [[NSMutableArray alloc]init];
    }
    return _musicUrlArray;
}

- (NSMutableArray *)musicNameArray
{
    if (!_musicNameArray) {
        _musicNameArray = [[NSMutableArray alloc]init];
    }
    return _musicNameArray;
}

- (void)playLocalResoucewithIndex:(NSInteger)currentIndex
{
    [self.playItem removeObserver:self forKeyPath:@"status"];

    _playItem = [[AVPlayerItem alloc]initWithURL:[self.musicUrlArray objectAtIndex:currentIndex]];
    [self.player replaceCurrentItemWithPlayerItem:_playItem];
    [self.player play];
    //监听AVPlayer播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playBackFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playItem];
    //监听播放器状态
    [_playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
}

//获取播放器status的状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        switch (self.player.status) {
            case AVPlayerStatusUnknown:
            {
                
                NSLog(@"未知状态,此时不能播放");
                break;
            }
             case AVPlayerStatusReadyToPlay:
            {
                NSLog(@"准备完毕,可以播放");
                break;
            }
            case AVPlayerStatusFailed:
            {
                NSLog(@"加载失败");
                break;
            }
            default:
                break;
        }
    }
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)recordBtn:(id)sender {
    
    RecordViewController *recordVC = [[RecordViewController alloc]init];
    [self presentViewController:recordVC animated:YES completion:nil];
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
