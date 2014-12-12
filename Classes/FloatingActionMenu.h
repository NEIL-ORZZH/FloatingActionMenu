//
//  FloatingActionMenu.h
//  ControlSystem
//
//  Created by KeithEllis on 14/12/10.
//  Copyright (c) 2014 keith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFPaperButton.h"

#define FloatingActionMenuImage @"MenuImage"
#define FloatingActionMenuText @"MenuText"
#define FloatingActionMenuColor @"MenuColor"

typedef enum {
    ExpandedState,
    FoldingState
} MainItemState;

@class MenuItem;

@protocol FloatingActionMenuDelegate <NSObject>

@optional
- (void)didSelectItemAtIndex:(NSUInteger)index;
- (void)didSelectMainItem;

@end

@protocol MenuItemDelegate <NSObject>

@required
- (void)didPressMainItem;
- (void)didPressSubmenuItem:(MenuItem*)item;

@end

@interface FloatingActionMenu : UIView <MenuItemDelegate>

@property (nonatomic, weak) id<FloatingActionMenuDelegate> delegate;
+ (FloatingActionMenu*)createMenuInViewController:(UIViewController*)viewController
                                            image:(UIImage*)image
                                    expandedImage:(UIImage*)expandedImage
                                        titleText:(NSString*)titleText
                                            color:(UIColor*)color
                                    expandedItems:(NSArray*)expandedItems;
+ (FloatingActionMenu*)createMenuInScrollView:(UIScrollView*)scrollView
                                        image:(UIImage*)image
                                expandedImage:(UIImage*)expandedImage
                                    titleText:(NSString*)titleText
                                        color:(UIColor*)color
                                expandedItems:(NSArray*)expandedItems;
- (void)setMenuItems:(NSArray*)items;
- (void)setMargin:(CGFloat)marginRight marginBottom:(CGFloat)marginBottom;

@end

// ========================================= FloatingActionMenuItem ============================================= //

@interface MenuItem : UIView

@property (nonatomic, weak) id<MenuItemDelegate> delegate;
- (id)initWithFrame:(CGRect)frame
              image:(UIImage*)image
      expandedImage:(UIImage*)expandedImage
          titleText:(NSString*)titleText
              color:(UIColor*)color;
- (id)initWithFrame:(CGRect)frame
              image:(UIImage*)image
          titleText:(NSString*)titleText
              color:(UIColor*)color;
- (void)animateMainItemToState:(MainItemState)state;
- (void)animateToState:(MainItemState)state;

@end

@interface LabelButton : UIButton

@property (nonatomic, strong) UIColor* color;
@property (nonatomic, strong) UIColor* highlightedColor;

@end

@interface ActionButton : BFPaperButton

@property (nonatomic, strong) UIColor* color;
@property (nonatomic, strong) UIColor* highlightedColor;

@end
