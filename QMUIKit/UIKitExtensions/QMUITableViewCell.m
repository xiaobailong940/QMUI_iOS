//
//  QMUITableViewCell.m
//  qmui
//
//  Created by QQMail on 14-7-7.
//  Copyright (c) 2014年 QMUI Team. All rights reserved.
//

#import "QMUITableViewCell.h"
#import "QMUICommonDefines.h"
#import "QMUIConfiguration.h"
#import "UITableView+QMUI.h"

@interface QMUITableViewCell() <UIScrollViewDelegate>

@property(nonatomic, assign, readwrite) QMUITableViewCellPosition cellPosition;
@property(nonatomic, assign, readwrite) UITableViewCellStyle style;
@property(nonatomic, strong) UIImageView *defaultAccessoryImageView;
@end

@implementation QMUITableViewCell

- (void)dealloc {
    self.parentTableView = nil;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        // 如果不指定初始值<0，那在setCellUIByPosition:时就会因为默认值是0而被识别为“无需更新”，从而导致背景图错误
        _cellPosition = QMUITableViewCellPositionNone;
        
        _style = style;
        _enabled = YES;
        _imageEdgeInsets = UIEdgeInsetsZero;
        _textLabelEdgeInsets = UIEdgeInsetsZero;
        _detailTextLabelEdgeInsets = UIEdgeInsetsZero;
        _accessoryHitTestEdgeInsets = UIEdgeInsetsMake(-12, -12, -12, -12);
        
        self.textLabel.font = UIFontMake(16);
        self.textLabel.textColor = TableViewCellTitleLabelColor;
        self.textLabel.backgroundColor = UIColorClear;
        
        self.detailTextLabel.font = UIFontMake(15);
        self.detailTextLabel.textColor = TableViewCellDetailLabelColor;
        self.detailTextLabel.backgroundColor = UIColorClear;
        
        // iOS7下背景色默认白色，之前的版本背景色继承tableView，这里统一设置为白色
        // iOS6其实下面这几句是没用的，会被自己绘制的覆盖了
        self.backgroundColor = TableViewCellBackgroundColor;
        UIView *selectedBackgroundView = [[UIView alloc] init];
        selectedBackgroundView.backgroundColor = TableViewCellSelectedBackgroundColor;
        self.selectedBackgroundView = selectedBackgroundView;
        
        // 因为在hitTest里扩大了accessoryView的响应范围，因此提高了系统一个与此相关的bug的出现几率，所以又在scrollView.delegate里做一些补丁性质的东西来修复
        if ([[self.subviews objectAtIndex:0] isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)[self.subviews objectAtIndex:0];
            scrollView.delegate = self;
        }
    }
    return self;
}

- (instancetype)initForTableView:(QMUITableView *)tableView withStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [self initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.parentTableView = tableView;
    }
    return self;
}

- (instancetype)initForTableView:(QMUITableView *)tableView withReuseIdentifier:(NSString *)reuseIdentifier {
    return [self initForTableView:tableView withStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
}

// 解决iOS8的cell中得separatorInset受layoutMargins影响的bug
- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect contentViewOldFrame = self.contentView.frame; // oldFrame是在[super layoutSubviews]里算过的frame
    self.contentView.frame = CGRectMake(CGRectGetMinX(contentViewOldFrame) + self.layoutMargins.left, CGRectGetMinY(contentViewOldFrame) + self.layoutMargins.top, CGRectGetWidth(contentViewOldFrame) - UIEdgeInsetsGetHorizontalValue(self.layoutMargins), CGRectGetHeight(contentViewOldFrame) - UIEdgeInsetsGetVerticalValue(self.layoutMargins));

    if (self.style == UITableViewCellStyleDefault || self.style == UITableViewCellStyleSubtitle) {
        
        BOOL hasCustomImageEdgeInsets = self.imageView.image && !UIEdgeInsetsEqualToEdgeInsets(self.imageEdgeInsets, UIEdgeInsetsZero);
        
        BOOL hasCustomTextLabelEdgeInsets = self.textLabel.text.length > 0 && !UIEdgeInsetsEqualToEdgeInsets(self.textLabelEdgeInsets, UIEdgeInsetsZero);
        
        BOOL shouldChangeDetailTextLabelFrame = self.style == UITableViewCellStyleSubtitle;
        BOOL hasCustomDetailLabelEdgeInsets = shouldChangeDetailTextLabelFrame && self.detailTextLabel.text.length > 0 && !UIEdgeInsetsEqualToEdgeInsets(self.detailTextLabelEdgeInsets, UIEdgeInsetsZero);
        
        CGRect imageViewFrame = self.imageView.frame;
        CGRect textLabelFrame = self.textLabel.frame;
        CGRect detailTextLabelFrame = self.detailTextLabel.frame;
        
        if (hasCustomImageEdgeInsets) {
            imageViewFrame.origin.x += self.imageEdgeInsets.left - self.imageEdgeInsets.right;
            imageViewFrame.origin.y += self.imageEdgeInsets.top - self.imageEdgeInsets.bottom;
            
            textLabelFrame.origin.x += self.imageEdgeInsets.left;
            textLabelFrame.size.width = fminf(CGRectGetWidth(textLabelFrame), CGRectGetWidth(self.contentView.bounds) - CGRectGetMinX(textLabelFrame));
            
            if (shouldChangeDetailTextLabelFrame) {
                detailTextLabelFrame.origin.x += self.imageEdgeInsets.left;
                detailTextLabelFrame.size.width = fminf(CGRectGetWidth(detailTextLabelFrame), CGRectGetWidth(self.contentView.bounds) - CGRectGetMinX(detailTextLabelFrame));
            }
        }
        if (hasCustomTextLabelEdgeInsets) {
            textLabelFrame.origin.x += self.textLabelEdgeInsets.left - self.imageEdgeInsets.right;
            textLabelFrame.origin.y += self.textLabelEdgeInsets.top - self.textLabelEdgeInsets.bottom;
            textLabelFrame.size.width = fminf(CGRectGetWidth(textLabelFrame), CGRectGetWidth(self.contentView.bounds) - CGRectGetMinX(textLabelFrame));
        }
        if (hasCustomDetailLabelEdgeInsets) {
            detailTextLabelFrame.origin.x += self.detailTextLabelEdgeInsets.left - self.detailTextLabelEdgeInsets.right;
            detailTextLabelFrame.origin.y += self.detailTextLabelEdgeInsets.top - self.detailTextLabelEdgeInsets.bottom;
            detailTextLabelFrame.size.width = fminf(CGRectGetWidth(detailTextLabelFrame), CGRectGetWidth(self.contentView.bounds) - CGRectGetMinX(detailTextLabelFrame));
        }
        
        self.imageView.frame = imageViewFrame;
        self.textLabel.frame = textLabelFrame;
        self.detailTextLabel.frame = detailTextLabelFrame;
        
        // `layoutSubviews`这里不可以拿textLabel的minX来设置separatorInset，如果要设置只能写死一个值
        // 否则会导致textLabel的minX逐渐叠加从而使textLabel被移出屏幕外
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    if (self.backgroundView) {
        self.backgroundView.backgroundColor = backgroundColor;
    }
}

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != enabled) {
        if (enabled) {
            self.userInteractionEnabled = YES;
            self.textLabel.textColor = TableViewCellTitleLabelColor;
            self.detailTextLabel.textColor = TableViewCellDetailLabelColor;
        } else {
            self.userInteractionEnabled = NO;
            self.textLabel.textColor = UIColorDisabled;
            self.detailTextLabel.textColor = UIColorDisabled;
        }
        _enabled = enabled;
    }
}

- (void)initDefaultAccessoryImageViewIfNeeded {
    if (!self.defaultAccessoryImageView) {
        self.defaultAccessoryImageView = [[UIImageView alloc] init];
        self.defaultAccessoryImageView.contentMode = UIViewContentModeCenter;
    }
}

// 重写accessoryType，如果是UITableViewCellAccessoryDisclosureIndicator类型的，则使用 QMUIConfigurationTemplate.m 配置表里的图片
- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType {
    [super setAccessoryType:accessoryType];
    if (accessoryType == UITableViewCellAccessoryDisclosureIndicator) {
        [self initDefaultAccessoryImageViewIfNeeded];
        self.defaultAccessoryImageView.image = TableViewCellDisclosureIndicatorImage;
        [self.defaultAccessoryImageView sizeToFit];
        self.accessoryView = self.defaultAccessoryImageView;
    } else if (accessoryType == UITableViewCellAccessoryCheckmark) {
        [self initDefaultAccessoryImageViewIfNeeded];
        self.defaultAccessoryImageView.image = TableViewCellCheckmarkImage;
        self.accessoryView = self.defaultAccessoryImageView;
    } else {
        self.accessoryView = nil;
    }
}

- (UIView *)separatorViewInCell:(UITableViewCell *)cell {
    for (UIView *subview in cell.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"_UITableViewCellSeparatorView")]) {
            return subview;
        }
    }
    return nil;
}

#pragma mark - UIScrollView Delegate

// 为了修复因优化accessoryView导致的向左滑动cell容易触发accessoryView事件 a little dirty by molice
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.accessoryView.userInteractionEnabled = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.accessoryView.userInteractionEnabled = YES;
}

#pragma mark - touch event

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (!view) {
        return nil;
    }
    // 对于使用自定义的accessoryView的情况，扩大其响应范围。最小范围至少是一个靠在屏幕右边缘的“宽高都为cell高度”的正方形区域
    if (self.accessoryView
        && !self.accessoryView.hidden
        && self.accessoryView.userInteractionEnabled
        && !self.editing
        // UISwitch被点击时，[super hitTest:point withEvent:event]返回的不是UISwitch，而是它的一个subview，如果这里直接返回UISwitch会导致控件无法使用，因此对UISwitch做特殊屏蔽
        && ![self.accessoryView isKindOfClass:[UISwitch class]]
        ) {
        
        CGRect accessoryViewFrame = self.accessoryView.frame;
        CGRect responseEventFrame;
        responseEventFrame.origin.x = CGRectGetMinX(accessoryViewFrame) + self.accessoryHitTestEdgeInsets.left;
        responseEventFrame.origin.y = CGRectGetMinY(accessoryViewFrame) + self.accessoryHitTestEdgeInsets.top;
        responseEventFrame.size.width = CGRectGetWidth(accessoryViewFrame) + UIEdgeInsetsGetHorizontalValue(self.accessoryHitTestEdgeInsets);
        responseEventFrame.size.height = CGRectGetHeight(accessoryViewFrame) + UIEdgeInsetsGetVerticalValue(self.accessoryHitTestEdgeInsets);
        if (CGRectContainsPoint(responseEventFrame, point)) {
            return self.accessoryView;
        }
    }
    return view;
}

@end

@implementation QMUITableViewCell(QMUISubclassingHooks)

- (void)updateCellAppearanceWithIndexPath:(NSIndexPath *)indexPath {
    // 子类继承
    if (indexPath && self.parentTableView) {
        QMUITableViewCellPosition position = [self.parentTableView qmui_positionForRowAtIndexPath:indexPath];
        self.cellPosition = position;
    }
}

@end
