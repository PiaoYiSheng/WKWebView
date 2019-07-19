//
//  CViewController.h
//  
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CViewController : UIViewController
// 无返回值,无参数
- (void)refresh;

// 无返回值,带参数 (参数还有多种类型)
- (void)setParam:(NSString *)param;

// 有返回值,有参数
- (NSString *)setParamReturn;

@property (nonatomic, assign) NSInteger msgType;
@end

NS_ASSUME_NONNULL_END
