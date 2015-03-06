//
//  FloatingActionMenu.m
//  ControlSystem
//
//  Created by KeithEllis on 14/12/10.
//  Copyright (c) 2014 keith. All rights reserved.
//

#import "FloatingActionMenu.h"

#define FloatingActionMenuItemWidth 200.f
#define FloatingActionMenuDefaultMarginRight 50.f
#define FloatingActionMenuDefaultMarginBottom 40.f
#define FloatingActionButtonSize 60.f
#define FloatingActionMenuHeight 80.f
#define FloatingActionSubmenuHeight 60.f

// Degrees to radians
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

@interface FloatingActionMenu ()

@property (nonatomic, strong) UIViewController* viewController;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) UIImage* expandedImage;
@property (nonatomic, copy) NSString* titleText;
@property (nonatomic, strong) UIColor* color;
@property (nonatomic, strong) NSArray* expandedItems;

@property (nonatomic, strong) UIView* maskView;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, assign) CGFloat marginRight;
@property (nonatomic, assign) CGFloat marginBottom;

@property (nonatomic, strong) MenuItem* mainItem;
@property (nonatomic, copy) NSMutableArray* itemContainer;

@end

@implementation FloatingActionMenu

+ (FloatingActionMenu*)createMenuInViewController:(UIViewController*)viewController
                                            image:(UIImage*)image
                                    expandedImage:(UIImage*)expandedImage
                                        titleText:(NSString*)titleText
                                            color:(UIColor*)color
                                    expandedItems:(NSArray*)expandedItems
{
    return [[self alloc] initWithViewController:viewController
                                          image:image
                                  expandedImage:expandedImage
                                      titleText:titleText
                                          color:color
                                  expandedItems:expandedItems];
}

+ (FloatingActionMenu*)createMenuInScrollView:(UIScrollView*)scrollView
                                        image:(UIImage*)image
                                expandedImage:(UIImage*)expandedImage
                                    titleText:(NSString*)titleText
                                        color:(UIColor*)color
                                expandedItems:(NSArray*)expandedItems
{
#pragma mark - TODO
    return nil;
}

- (id)initWithViewController:(UIViewController*)viewController
                       image:(UIImage*)image
               expandedImage:(UIImage*)expandedImage
                   titleText:(NSString*)titleText
                       color:(UIColor*)color
               expandedItems:(NSArray*)expandedItems
{
    if (self = [super init]) {
        self.viewController = viewController;
        self.image = image;
        self.expandedImage = expandedImage;
        self.titleText = titleText;
        self.color = color;
        self.expandedItems = expandedItems;

        self.isExpanded = NO;
        self.itemContainer = [NSMutableArray array];
        self.marginRight = FloatingActionMenuDefaultMarginRight;
        self.marginBottom = FloatingActionMenuDefaultMarginBottom;

        [self.viewController.view addSubview:self];

        CGFloat width = MAX(viewController.view.bounds.size.width, viewController.view.bounds.size.height);
        CGFloat height = MIN(viewController.view.bounds.size.width, viewController.view.bounds.size.height);
        CGRect rect;
        rect.origin.x = width - FloatingActionMenuItemWidth - FloatingActionMenuDefaultMarginRight;
        rect.origin.y = height - FloatingActionMenuHeight - FloatingActionMenuDefaultMarginBottom;
        rect.size = CGSizeMake(FloatingActionMenuItemWidth, FloatingActionMenuHeight);
        self.mainItem = [[MenuItem alloc] initWithFrame:rect
                                                  image:image
                                          expandedImage:expandedImage
                                              titleText:titleText
                                                  color:color];
        self.mainItem.delegate = self;
        [self.viewController.view addSubview:self.mainItem];

        rect.origin.x = CGRectGetMinX(viewController.view.bounds);
        rect.origin.y = CGRectGetMinY(viewController.view.bounds);
        rect.size = CGSizeMake(width, height);
        self.maskView = [[UIView alloc] initWithFrame:rect];
        self.maskView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer* recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(maskViewTapSelector:)];
        [self.maskView addGestureRecognizer:recognizer];
    }
    return self;
}

- (void)maskViewTapSelector:(id)sender
{
    if (!self.isExpanded) {
        [self expandFloatingMenuAnimated];
    }
    else {
        [self foldFloatingMenuAnimated];
    }
}

- (void)willMoveToWindow:(UIWindow*)newWindow
{
    [super willMoveToWindow:newWindow];
    if (newWindow == nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:[UIDevice currentDevice]];
    [self createExpandMenuItems];
}

- (void)createExpandMenuItems
{
    self.itemContainer = [NSMutableArray array];
    CGFloat width = MAX(self.viewController.view.bounds.size.width, self.viewController.view.bounds.size.height);
    CGFloat height = MIN(self.viewController.view.bounds.size.width, self.viewController.view.bounds.size.height);
    CGRect rect;
    CGFloat startY = height - FloatingActionMenuHeight - FloatingActionMenuDefaultMarginBottom;
    rect.origin.x = width - FloatingActionMenuItemWidth - FloatingActionMenuDefaultMarginRight;
    rect.size = CGSizeMake(FloatingActionMenuItemWidth, FloatingActionSubmenuHeight);
    NSInteger index = 0;
    NSInteger count = self.expandedItems.count;
    for (NSDictionary* item in self.expandedItems) {
        UIImage* image = [item objectForKey:FloatingActionMenuImage];
        NSString* text = [item objectForKey:FloatingActionMenuText];
        UIColor* color = [item objectForKey:FloatingActionMenuColor];
        assert(image != nil);
        assert(text != nil);
        assert(color != nil);
        rect.origin.y = startY - FloatingActionSubmenuHeight * (count - index);
        MenuItem* item = [[MenuItem alloc] initWithFrame:rect image:image titleText:text color:color];
        item.delegate = self;
        item.hidden = YES;
        [self.viewController.view addSubview:item];
        [self.itemContainer addObject:item];
        index++;
    }
}

- (void)setMenuItems:(NSArray*)items
{
    for (MenuItem* item in self.itemContainer) {
        [item removeFromSuperview];
    }
    self.itemContainer = [NSMutableArray array];
    self.expandedItems = items;
    [self createExpandMenuItems];
}

- (void)setMargin:(CGFloat)marginRight marginBottom:(CGFloat)marginBottom
{
    self.marginRight = marginRight;
    self.marginBottom = marginBottom;
}

- (void)orientationChanged:(NSNotification*)notification
{
    NSLog(@"Orientation has changed: %d", [[notification object] orientation]);
#pragma mark - TODO Change FloatingActionMenu view animated according to orientation change
}

#pragma mark - MenuItemDelegate

- (void)didPressMainItem
{
    if (!self.isExpanded) {
        [self expandFloatingMenuAnimated];
    }
    else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectMainItem)]) {
            [self.delegate didSelectMainItem];
        }
        [self foldFloatingMenuAnimated];
    }
}

- (void)didPressSubmenuItem:(MenuItem*)item
{
    NSUInteger index = [self.itemContainer indexOfObject:item];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectItemAtIndex:)]) {
        [self.delegate didSelectItemAtIndex:index];
    }
    if (!self.isExpanded) {
        [self expandFloatingMenuAnimated];
    }
    else {
        [self foldFloatingMenuAnimated];
    }
}

- (void)expandFloatingMenuAnimated
{
    [self.viewController.view addSubview:self.maskView];
    [self.viewController.view bringSubviewToFront:self.maskView];
    [self.viewController.view bringSubviewToFront:self.mainItem];
    [self.mainItem animateMainItemToState:ExpandedState];
    for (MenuItem* item in self.itemContainer) {
        [self.viewController.view bringSubviewToFront:item];
        [item animateToState:ExpandedState];
    }
    self.isExpanded = YES;
}

- (void)foldFloatingMenuAnimated
{
    [self.mainItem animateMainItemToState:FoldingState];
    for (MenuItem* item in self.itemContainer) {
        [item animateToState:FoldingState];
    }
    [self.maskView removeFromSuperview];
    self.isExpanded = NO;
}

@end

// ========================================= FloatingActionMenuItem ============================================= //

typedef enum {
    LabelButtonType,
    ActionButtonType
} ButtonViewType;

@interface MenuItem ()

@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) UIImage* expandedImage;
@property (nonatomic, copy) NSString* titleText;
@property (nonatomic, strong) UIColor* color;
@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UIImageView* imageView;
@property (nonatomic, strong) LabelButton* labelButton;
@property (nonatomic, strong) CAShapeLayer* labelShadowLayer;
@property (nonatomic, strong) ActionButton* actionButton;

@end

@implementation MenuItem

static CGFloat LabelPadding = 5.f;
static CGFloat LabelMarginRight = 22.f;
static CGFloat SubmenuButtonSize = 40.f;

- (id)initWithFrame:(CGRect)frame
              image:(UIImage*)image
      expandedImage:(UIImage*)expandedImage
          titleText:(NSString*)titleText
              color:(UIColor*)color
{
    self = [self initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        self.image = image;
        self.expandedImage = expandedImage;
        self.titleText = titleText;
        self.color = color;

        self.labelButton = [self createLabelButton:titleText];
        self.actionButton = [self createActionButtonWithImage:image color:color size:FloatingActionButtonSize];

        [self bindButtonEvent];

        [self.labelButton addTarget:self action:@selector(mainButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.actionButton addTarget:self action:@selector(mainButtonAction:) forControlEvents:UIControlEventTouchUpInside];

        self.labelButton.hidden = YES;

        [self addSubview:self.labelButton];
        [self addSubview:self.actionButton];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
              image:(UIImage*)image
          titleText:(NSString*)titleText
              color:(UIColor*)color
{
    self = [self initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        self.image = image;
        self.titleText = titleText;
        self.color = color;

        self.labelButton = [self createLabelButton:titleText];
        self.actionButton = [self createActionButtonWithImage:image color:color size:SubmenuButtonSize];

        [self bindButtonEvent];

        [self.labelButton addTarget:self action:@selector(selectItemAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.actionButton addTarget:self action:@selector(selectItemAction:) forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:self.labelButton];
        [self addSubview:self.actionButton];
    }
    return self;
}

- (void)animateMainItemToState:(MainItemState)state
{
    switch (state) {
    case ExpandedState: {
        CABasicAnimation* rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotation.duration = 0.2;
        rotation.delegate = self;
        rotation.removedOnCompletion = NO;
        rotation.fillMode = kCAFillModeRemoved;
        rotation.fromValue = [NSNumber numberWithFloat:DEGREES_TO_RADIANS(0)];
        rotation.toValue = [NSNumber numberWithFloat:DEGREES_TO_RADIANS(0 + 90)];
        [rotation setValue:@"expandImage" forKey:@"expandMenu"];

        [self.actionButton.imageView.layer addAnimation:rotation forKey:@"rotation"];

        [self addShowLabelButtonAnimation];
    } break;
    case FoldingState: {
        CABasicAnimation* rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotation.duration = 0.2;
        rotation.delegate = self;
        rotation.removedOnCompletion = NO;
        rotation.fillMode = kCAFillModeRemoved;
        rotation.fromValue = [NSNumber numberWithFloat:DEGREES_TO_RADIANS(0)];
        rotation.toValue = [NSNumber numberWithFloat:DEGREES_TO_RADIANS(0 - 90)];
        [rotation setValue:@"foldImage" forKey:@"foldMenu"];

        [self.actionButton.imageView.layer addAnimation:rotation forKey:@"rotation"];

        [self addHideLabelButtonAnimation];

    } break;
    default:
        break;
    }
}

- (void)animateToState:(MainItemState)state
{
    switch (state) {
    case ExpandedState: {
        self.hidden = NO;
        [self addShowLabelButtonAnimation];

        CABasicAnimation* scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scale.duration = 0.2f;
        scale.delegate = self;
        scale.removedOnCompletion = NO;
        scale.fillMode = kCAFillModeForwards;
        scale.fromValue = [NSNumber numberWithDouble:0.5];
        scale.toValue = [NSNumber numberWithDouble:1.f];
        [scale setValue:@"show" forKey:@"showActionButton"];

        CABasicAnimation* opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacity.duration = 0.2;
        opacity.removedOnCompletion = NO;
        opacity.fillMode = kCAFillModeForwards;
        opacity.fromValue = [NSNumber numberWithFloat:0.f];
        opacity.toValue = [NSNumber numberWithFloat:1.f];
        [opacity setValue:@"show" forKey:@"showActionButton"];

        [self.actionButton.layer addAnimation:scale forKey:@"scale"];
        [self.actionButton.layer addAnimation:opacity forKey:@"opacity"];
    } break;
    case FoldingState: {
        [self addHideLabelButtonAnimation];

        CABasicAnimation* scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scale.duration = 0.2f;
        scale.delegate = self;
        scale.removedOnCompletion = NO;
        scale.fillMode = kCAFillModeForwards;
        scale.fromValue = [NSNumber numberWithDouble:1.f];
        scale.toValue = [NSNumber numberWithDouble:0.5];
        [scale setValue:@"hide" forKey:@"hideActionButton"];

        CABasicAnimation* opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacity.duration = 0.2;
        opacity.removedOnCompletion = NO;
        opacity.fillMode = kCAFillModeForwards;
        opacity.fromValue = [NSNumber numberWithFloat:1.f];
        opacity.toValue = [NSNumber numberWithFloat:0.f];
        [opacity setValue:@"hide" forKey:@"hideActionButton"];

        [self.actionButton.layer addAnimation:scale forKey:@"scale"];
        [self.actionButton.layer addAnimation:opacity forKey:@"opacity"];
    } break;
    default:
        break;
    }
}

- (void)addShowLabelButtonAnimation
{
    self.labelButton.alpha = 0.f;
    self.labelButton.hidden = NO;

    CABasicAnimation* opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.duration = 0.2;
    opacity.delegate = self;
    opacity.removedOnCompletion = NO;
    opacity.fillMode = kCAFillModeForwards;
    opacity.fromValue = [NSNumber numberWithFloat:0.f];
    opacity.toValue = [NSNumber numberWithFloat:1.f];
    [opacity setValue:@"show" forKey:@"showLabelButton"];

    [self.labelButton.layer addAnimation:opacity forKey:@"opacity"];
}

- (void)addHideLabelButtonAnimation
{
    CABasicAnimation* opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.duration = 0.2;
    opacity.delegate = self;
    opacity.removedOnCompletion = NO;
    opacity.fillMode = kCAFillModeForwards;
    opacity.fromValue = [NSNumber numberWithFloat:1.f];
    opacity.toValue = [NSNumber numberWithFloat:0.f];
    [opacity setValue:@"hide" forKey:@"hideLabelButton"];

    [self.labelButton.layer addAnimation:opacity forKey:@"opacity"];
}

- (void)animationDidStop:(CAAnimation*)theAnimation finished:(BOOL)flag
{
    if ([[theAnimation valueForKey:@"expandMenu"] isEqualToString:@"expandImage"]) {
        [self.actionButton setImage:self.expandedImage forState:UIControlStateNormal];
        [self.actionButton setImage:self.expandedImage forState:UIControlStateHighlighted];
        [self.actionButton setImage:self.expandedImage forState:UIControlStateSelected];
    }
    if ([[theAnimation valueForKey:@"foldMenu"] isEqualToString:@"foldImage"]) {
        [self.actionButton setImage:self.image forState:UIControlStateNormal];
        [self.actionButton setImage:self.image forState:UIControlStateHighlighted];
        [self.actionButton setImage:self.image forState:UIControlStateSelected];
    }
    if ([[theAnimation valueForKey:@"hideLabelButton"] isEqualToString:@"hide"]) {
        self.labelButton.alpha = 0.f;
        self.labelButton.hidden = YES;
    }
    if ([[theAnimation valueForKey:@"showLabelButton"] isEqualToString:@"show"]) {
        self.labelButton.alpha = 1.f;
        self.labelButton.hidden = NO;
    }
    if ([[theAnimation valueForKey:@"showActionButton"] isEqualToString:@"show"]) {
        self.actionButton.alpha = 1.f;
        self.hidden = NO;
    }
    if ([[theAnimation valueForKey:@"hideActionButton"] isEqualToString:@"hide"]) {
        self.actionButton.alpha = 0.f;
        self.hidden = YES;
    }
}

- (void)mainButtonAction:(id)button
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didPressMainItem)]) {
        [self.delegate didPressMainItem];
    }
}

- (void)selectItemAction:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didPressSubmenuItem:)]) {
        [self.delegate didPressSubmenuItem:self];
    }
}

- (LabelButton*)createLabelButton:(NSString*)titleText
{
    LabelButton* button = [[LabelButton alloc] initWithFrame:CGRectZero];
    button.tag = LabelButtonType;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:13.f];
    CGSize size = [titleText sizeWithAttributes:@{ NSFontAttributeName : button.titleLabel.font }];
    CGFloat padding = LabelPadding;
    UIBezierPath* shadowPath;
    CGRect rect;
    rect.size = CGSizeMake(size.width + padding * 2, size.height + padding * 2);
    rect.origin.x = CGRectGetWidth(self.bounds) - FloatingActionButtonSize - LabelMarginRight - CGRectGetWidth(rect);
    rect.origin.y = roundf((CGRectGetHeight(self.bounds) - CGRectGetHeight(rect)) / 2);
    button.frame = rect;
    [button setTitle:titleText forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:0.49 green:0.49 blue:0.49 alpha:1] forState:UIControlStateNormal];
    button.backgroundColor = [UIColor whiteColor];
    button.color = [UIColor whiteColor];
    button.highlightedColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.f];
    button.layer.cornerRadius = 3.f;
    button.layer.masksToBounds = NO;
    button.layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.36].CGColor;
    button.layer.shadowOffset = CGSizeMake(0.f, 1.0f);
    button.layer.shadowRadius = 1.0f;
    button.layer.shadowOpacity = 0.8f;
    shadowPath = [UIBezierPath bezierPathWithRoundedRect:button.bounds
                                            cornerRadius:button.layer.cornerRadius];
    button.layer.shadowPath = shadowPath.CGPath;
    return button;
}

- (ActionButton*)createActionButtonWithImage:(UIImage*)image color:(UIColor*)color size:(CGFloat)size
{
    CGRect rect;
    rect.size = CGSizeMake(size, size);
    rect.origin.x = CGRectGetWidth(self.bounds)
                    - FloatingActionButtonSize
                    + roundf((FloatingActionButtonSize - CGRectGetWidth(rect)) / 2);
    rect.origin.y = roundf((CGRectGetHeight(self.bounds) - CGRectGetHeight(rect)) / 2);
    ActionButton* button = [[ActionButton alloc] initWithFrame:rect raised:YES];
    button.backgroundColor = color;
    button.tag = ActionButtonType;
    button.color = color;
    button.highlightedColor = [self darkerColor:color];
    button.cornerRadius = roundf(CGRectGetHeight(rect) / 2);
    button.rippleFromTapLocation = NO;
    button.backgroundColor = color;
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:image forState:UIControlStateHighlighted];
    [button setImage:image forState:UIControlStateSelected];
    return button;
}

- (UIColor*)darkerColor:(UIColor*)color
{
    CGFloat hue, saturation, brightness, alpha;
    if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        return [UIColor colorWithHue:hue
                          saturation:saturation
                          brightness:brightness * 0.85
                               alpha:alpha];
    }
    return color;
}

- (void)bindButtonEvent
{
    [self.labelButton addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
    [self.labelButton addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchDragOutside];
    [self.labelButton addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchDragExit];
    [self.labelButton addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchUpInside];
    [self.labelButton addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchUpOutside];
    [self.labelButton addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchCancel];

    [self.actionButton addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
    [self.actionButton addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchDragOutside];
    [self.actionButton addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchDragExit];
    [self.actionButton addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionButton addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchUpOutside];
    [self.actionButton addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchCancel];
}

- (void)buttonDown:(UIButton*)button
{
    self.actionButton.highlighted = YES;
    self.labelButton.highlighted = YES;
}

- (void)buttonUp:(UIButton*)button
{
    self.labelButton.highlighted = NO;
    self.actionButton.highlighted = NO;
}

@end

@implementation LabelButton

- (void)setHighlighted:(BOOL)highlighted
{
    if (highlighted) {
        self.backgroundColor = self.highlightedColor;
    }
    else {
        [UIView animateWithDuration:0.3
                         animations:^{
            self.backgroundColor = self.color;
                         }];
    }
}

@end

@implementation ActionButton

- (void)setHighlighted:(BOOL)highlighted
{
    if (highlighted) {
        self.backgroundColor = self.highlightedColor;
    }
    else {
        self.backgroundColor = self.color;
    }
}

@end
