//
//  LLHtmlModel.m
//  LLWKWebView
//

#import "LLHtmlModel.h"
#import "objc/runtime.h"
@implementation LLHtmlModel
/** 初始化 方法*/
+(instancetype)initWithModel:(NSDictionary *)dict{
    LLHtmlModel *model = [[LLHtmlModel alloc] init];
    model.title = [NSString stringWithFormat:@"%@",dict[@"title"]];
    model.message = [NSString stringWithFormat:@"%@",dict[@"message"]];
    model.buttonCount = dict[@"buttonCount"];
    model.functionType = [NSString stringWithFormat:@"%@",dict[@"functionType"]];
    model.placeholder = [NSString stringWithFormat:@"%@",dict[@"placeholder"]];
    
    return model;
}
@end
