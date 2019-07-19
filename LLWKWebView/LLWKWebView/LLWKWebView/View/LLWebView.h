//
//  LLWebView.h
//  JavaScript
//
//  Created by L² on 2018/6/3.

//  自定义WebView

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h> // 导库
@class LLWebView;
@class WKWebView;
@protocol LLWebViewDelegate <NSObject>
@optional
/** 开始加载 */
- (void)LLWebViewDidStart:(WKWebView *)webView;

/** 完成加载 */
- (void)LLWebViewDidFinish:(WKWebView *)webView;

/** 加载失败 */
- (void)LLWebViewDidFail:(WKWebView *)webView;

/** 获取到标题 */
- (void)LLWebViewDidGetTitle:(NSString *)title;

/** 网页播放视频的代理*/
- (void)LLWebViewWindowVideo:(BOOL)videoType notify:(NSNotification *)notify;

/** 注册监听方法的响应*/
- (void)LLWebViewUserContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;
@end
@interface LLWebView : UIView


/** 代理*/
@property (nonatomic,weak) id <LLWebViewDelegate> delegate;

/** 进度条颜色 默认红色*/
@property (nonatomic, strong) UIColor *progressTintColor;
/** 进度条背景 默认透明*/
@property (nonatomic, strong) UIColor *trackTintColor;

/** 加载网页
 @param urlString : 路径或者网址
 */
-(void)loadUrlString:(NSString *)urlString;


/** 调用js方法,发送参数
 @param method : HTML的方法名
 @param js : 传送给HTML的值
 */
-(void)evaluateJSMethod:(NSString *)method JavaScript:(NSString *)js;

/** 调用js方法,发送参数
 @param method : HTML的方法名
 @param dict : 传送给HTML的JSON
 */
-(void)evaluateJSMethod:(NSString *)method JavaScriptDict:(NSDictionary *)dict  completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler;

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler;

/** 监听的方法名
 响应: LLWebViewUserContentController 此方法
 */
@property (nonatomic, strong) NSString *methodName;

/** HTML响应Alert时 返回内容的方法名*/
@property (nonatomic, strong) NSString *alertMethodName;

/** 初始化方法,必须用此方法
 @param frame : 坐标
 @param showAlertViewController : 传入当前控制器
 @param userAgent : 需要修改的userAgent 如果不修改传空字符串
 */
+(instancetype)initWithFrame:(CGRect)frame showAlertViewController:(UIViewController *)showAlertViewController userAgent:(NSString *)userAgent;

/** 返回上一级页面*/
-(BOOL)goBack;

/** 刷新页面*/ 
-(void)reload;

#pragma mark 通过监听getJSON_iOS方法,动态返回json 给html
-(void)getHTMLJSONWithDict:(NSDictionary *)dict;

#pragma mark 通过监听JumpToNewVC方法,动态创建传值跳转
- (void)jumpWithDict:(NSDictionary *)dict navController:(UINavigationController *)navController;

#pragma mark 通过监听getPhoto方法,唤起系统相机

#pragma mark 转换工具 (发送json,解析json)
/**
 *  字典转字符串
 */
+(NSString *)convertToJsonData:(NSDictionary *)dict;
//
/**
 *  字典转json字符串方法
 */
+(NSDictionary*)dictionaryWithJsonString:(NSString*)jsonString;

#pragma mark 转换工具 (拼接中文URL)
/**
 *  中文 转 Encode
 */
+ (NSString *)URLEncodedString:(NSString *)String;

/**
 *  Encode 转 中文
 */
+ (NSString *)URLDecodedString:(NSString *)String;
@end
