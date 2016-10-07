//
//  BTCProgressView.m
//  BTCWallet
//
//  Created by Admin on 8/26/16.
//

#import "BTCProgressView.h"

@interface BTCProgressView ()

@property (nonatomic, strong)UIView *progressIndicatorView;
@property (nonatomic, strong)UILabel *progressPercentLabel;

@end

@implementation BTCProgressView

- (void)awakeFromNib{
    [super awakeFromNib];
    [self setUp];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    _progressIndicatorView.frame = self.bounds;
    self.layer.cornerRadius = self.bounds.size.height / 2.0;
    self.progress = self.progress;
}

- (void)setUp{
    ///*
    self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    
    _progressIndicatorView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:_progressIndicatorView];
    _progressIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _progressIndicatorView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    
    
    self.layer.cornerRadius = self.bounds.size.height / 2.0;
    self.layer.masksToBounds = YES;
    
    
    _progressPercentLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _progressPercentLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_progressPercentLabel];
    self.progressPercentLabel.textColor = [UIColor whiteColor];
    _progressPercentLabel.textAlignment = NSTextAlignmentCenter;
    
    
    
    self.progress = 0.0;
     //*/
}

- (void)setProgress:(CGFloat)progress{
    _progress = progress;
    if (_progress  == 0.f) {
        _progress = 0.001;
    }
    _progressPercentLabel.text = [NSString stringWithFormat:@"%.2f%%", _progress * 100.0];
    _progressIndicatorView.frame = CGRectMake(0, 0, self.bounds.size.width * _progress, self.bounds.size.height);
    if (_progress == 1.f) {
        self.hidden = YES;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
