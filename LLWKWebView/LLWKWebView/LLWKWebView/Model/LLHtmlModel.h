//
//  LLHtmlModel.h
//  LLWKWebView
//
//  监听 alert,confirm,prompt 发送过来的json格式模型
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LLHtmlModel : NSObject
/** json格式目前必须只能用此格式,无此内容传空字符串即可
 {
 "title":"确定要删除吗?",
 "message":"内容",
 "buttonCount":[
 {"title":"取消","buttonStyle":"2"},
 {"title":"确定","buttonStyle":"1"}],
 "functionType":"isCart"
 "placeholder":"输入框提示语"
 }
 */

/** 弹窗标题*/
@property (nonatomic, strong) NSString *title;

/** 弹窗内容*/
@property (nonatomic, strong) NSString *message;

/** 按钮数组及内容
 title : 按钮文字
 buttonStyle : 类型
 */
@property (nonatomic, strong) NSArray *buttonCount;

/** 作为一个方法标识*/
@property (nonatomic, strong) NSString *functionType;

/** 输入框提示语*/
@property (nonatomic, strong) NSString *placeholder;

/** 初始化 方法*/
+(instancetype)initWithModel:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
