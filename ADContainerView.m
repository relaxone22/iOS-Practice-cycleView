//
//  ADContainerView.m
//  Pods
//
//  Created by tonyliu on 24/07/2017.
//
//

#import "ADContainerView.h"

#define W self.frame.size.width
#define H self.frame.size.height
static CGFloat const kPageControlHeight = 6.f;
static NSString * const reuseIdentifier = @"collectionViewCell";

@interface ADContainerView()<UICollectionViewDelegate, UICollectionViewDataSource>
/// 循環頁面
@property (nonatomic, strong) UICollectionView *collectionView;
/// 循環頁面layout
@property (nonatomic, strong) UICollectionViewFlowLayout *flow;
/// 數據源
@property (nonatomic, strong) NSMutableArray<UIView *> *dataArray;
/// 分頁指示器
@property (nonatomic, strong) UIPageControl *pageControl;
/// 轉動畫面回調
@property (nonatomic, copy) void (^ scrollActionBlock) (NSInteger) ;
@end

@implementation ADContainerView

#pragma mark - initial
- (instancetype)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialize];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.collectionView.frame = CGRectMake(0, 0, W, H - kPageControlHeight - 2);
    self.flow.itemSize = self.collectionView.frame.size;
    self.pageControl.frame = CGRectMake(0, H - kPageControlHeight, W, kPageControlHeight);
}

#pragma mark - public method
- (void)addViews:(NSArray<UIView *> *)views scrollAction:(void (^) (NSInteger index))block {
    
    if (views.count <= 0) {
        return;
    }
    
    [self layoutIfNeeded];
    [self.dataArray removeAllObjects];
    [self.dataArray addObjectsFromArray:views];
    
    self.pageControl.numberOfPages = views.count;
    [self.pageControl updateCurrentPageDisplay];
    
    if (views.count <= 1) {
        [self scrollFreeze:YES];
    }
    else {
        [self scrollFreeze:NO];
    }
    
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        [weakSelf.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    } completion:^(BOOL finished) {
        [self scrollToCenterOrigin];
    }];
    
    self.scrollActionBlock = block;
}

- (void)randomPage {
    if (self.dataArray.count <= 0) {
        return;
    }
    NSUInteger randomIndex = arc4random() % self.dataArray.count;
    randomIndex = self.dataArray.count - randomIndex;
    [self scrollToindex:randomIndex];
}

- (void)nextPage {
    NSIndexPath *visibleIndexPath = [self.collectionView indexPathsForVisibleItems].firstObject;
    NSInteger nextIndex = (visibleIndexPath.row + 1) % self.dataArray.count;
    nextIndex = self.dataArray.count + nextIndex;
    [self scrollToindex:nextIndex];
}

- (void)scrollFreeze:(BOOL)freezAble {
    self.collectionView.scrollEnabled = !freezAble;
    self.pageControl.hidden = freezAble;
}

- (NSInteger)currentPage {
    return self.pageControl.currentPage;
}

#pragma mark - private method
/// 初始化方法
- (void)initialize {
    [self addSubview:self.collectionView];
    [self addSubview:self.pageControl];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
}

/// 滾動到中間初始位置
- (void)scrollToCenterOrigin {
    NSInteger centerOrigin = self.dataArray.count;
    [self scrollToindex:centerOrigin];
}

/// 滾動到中間結束位置
- (void)scrollToCenterEnd {
    NSInteger centerEnd = self.dataArray.count * 2 - 1;
    [self scrollToindex:centerEnd];
}

- (void)scrollToindex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
}

#pragma mark - property
- (UICollectionViewFlowLayout *)flow {
    if (!_flow) {
        _flow = [[UICollectionViewFlowLayout alloc] init];
        _flow.minimumLineSpacing = 0.0;
        _flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return _flow;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:self.flow];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.pagingEnabled = YES;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth & UIViewAutoresizingFlexibleHeight;
        
        if ([_collectionView respondsToSelector:@selector(setPrefetchingEnabled:)]) {
            _collectionView.prefetchingEnabled = NO;
        }
    }
    return _collectionView;
}

- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        _pageControl.pageIndicatorTintColor = [UIColor grayColor];
        _pageControl.userInteractionEnabled = NO;
    }
    return _pageControl;
}

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

#pragma marrk - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSUInteger dataCount = self.dataArray.count;
    return dataCount * 3;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    NSUInteger dataCount = self.dataArray.count;
    UIView *contentView = self.dataArray[indexPath.item % dataCount];
    contentView.frame = cell.contentView.frame;
    [cell.contentView addSubview:contentView];
    return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger offsetX = (NSInteger)scrollView.contentOffset.x;
    if (offsetX % (NSInteger)W != 0) {
        return;
    }
    
    // 設定分頁指示器
    NSInteger page = (NSInteger)(offsetX / W ) % self.dataArray.count;
    self.pageControl.currentPage = page;
    // 轉動頁面回調
    self.scrollActionBlock(self.pageControl.currentPage);
    // 循環調整
    NSInteger index = offsetX / W;
    NSInteger number = [self.collectionView numberOfItemsInSection:0];
    if (index == 0) {
        [self scrollToCenterOrigin];
    }
    if (index == number - 1) {
        [self scrollToCenterEnd];
    }    
}

@end
