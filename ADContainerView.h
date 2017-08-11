//
//  ADContainerView.h
//  Pods
//
//  Created by tonyliu on 24/07/2017.
//
//

#import <UIKit/UIKit.h>

@interface ADContainerView : UIView
/// 當前頁面
@property (nonatomic, assign, readonly) NSInteger currentPage;

/**
 將畫面加入輪播
 @param views 加入輪播的畫面
 @param block 轉動畫面回調
 */
- (void)addViews:(NSArray<UIView *> *)views scrollAction:(void (^) (NSInteger index))block;
/// 是否停止轉動
- (void)scrollFreeze:(BOOL)freezAble;
/// 隨機跳轉畫面
- (void)randomPage;
/// 下一則畫面
- (void)nextPage;
@end
