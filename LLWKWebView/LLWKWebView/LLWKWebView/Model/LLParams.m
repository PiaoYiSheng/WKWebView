//
//  LLParams.m
//  LLWKWebView
//
//
/** APP版本号 */
#define LLWebViewAppVersion [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]

#import "LLParams.h"

@implementation LLParams
/**
    将类名: LLParams
    方法名: getParams
    告知HTML 调用时使用
 */
-(NSDictionary *)getParams{
    NSDictionary *dict = @{
                           @"token" : @"6666666666",
                           @"version" : LLWebViewAppVersion
                           };
    
    return dict;
}
@end
