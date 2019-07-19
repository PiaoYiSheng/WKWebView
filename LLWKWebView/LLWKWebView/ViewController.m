//
//  ViewController.m
//  LLWKWebView
//
//

/** 字符串是否为空 */
#define kStringIsEmpty(str) ([str isKindOfClass:[NSNull class]] || str == nil || [str length] < 1 ? YES : NO )

#import "ViewController.h"
#import "LLWebView.h"
#import "CViewController.h"
// runtime 设置 objc_msgSend Calls = NO;
#import "objc/runtime.h"
@interface ViewController ()<LLWebViewDelegate>
@property (strong ,nonatomic) LLWebView *webView; // 网页控件
@property (nonatomic, strong) NSString *absoluteString; // 首页路径
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 初始化 网页
    [self initWithWKWebView];
    
    // navItiems
    [self initItems];
}

#pragma mark LLWebViewDelegate
/** 开始加载 */
- (void)LLWebViewDidStart:(WKWebView *)webView{
    // 只记录第一次加载的页面
    if (kStringIsEmpty(self.absoluteString)) {
        self.absoluteString = webView.URL.absoluteString;
        NSLog(@"\n开始加载%@\n%d",webView.URL.absoluteString,kStringIsEmpty(self.absoluteString));
    }
}
// 加载完成
-(void)LLWebViewDidFinish:(WKWebView *)webView{
    // 给h5的setApi_token方法 发送iOS 参数
//    [self.webView evaluateJSMethod:@"setApi_token" JavaScript:@"iOS"];
    
    // 给h5的jieShouFangFa方法 发送SearchSaveName 参数
//    [self.webView evaluateJSMethod:@"jieShouFangFa" JavaScript:@"SearchSaveName"];
}

/** 监听方法*/
-(void)LLWebViewUserContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSString *methodName = message.name;
    NSString *messageJsonStr = message.body;
    
    NSLog(@"%@",messageJsonStr);
    
    // HTML 传参JSON 参数给iOS
    if ([methodName isEqualToString:@"SendValueiOSJSON"]) {
        // 如果是监听的某个方法,做不同的处理
        NSDictionary *h5Json = [LLWebView dictionaryWithJsonString:messageJsonStr];
        NSLog(@"SendValueiOSJSON:\n%@",h5Json);
    }

    // HTML  控制 iOS 跳转控制器
    if ([methodName isEqualToString:@"JumpToNewVC"]) {
        NSDictionary *h5Json = [LLWebView dictionaryWithJsonString:messageJsonStr];
        NSLog(@"%@",h5Json);
        // 动态跳转
        [self.webView jumpWithDict:h5Json navController:self.navigationController];
    }
    
    // HTML 调用 iOS 类, 获取参数
    if ([methodName isEqualToString:@"getJSON_iOS"]) {
        NSDictionary *h5Json = [LLWebView dictionaryWithJsonString:messageJsonStr];
        NSLog(@"%@",h5Json);
        // 根据发来的内容,返回json 给html
        [self.webView getHTMLJSONWithDict:h5Json];
    }
    
    // HTML 调用 iOS 相机
    if ([methodName isEqualToString:@"getPhoto"]) {
//        [self getPhoto];
    }
}

//-(void)getPhoto{
//    // 创建JSContext
//    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
//
//}


// 标题赋值
-(void)LLWebViewDidGetTitle:(NSString *)title
{
    self.title = title;
}



#pragma mark 初始化 网页
-(void)initWithWKWebView{
    // 必须用此方法初始化
    _webView = [LLWebView initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-64) showAlertViewController:self userAgent:@"newUserAgent"];
    _webView.delegate = self;
    // 加载网页(本地)
    [_webView loadUrlString:@"B.html"];
    
    // 注册监听方法
    _webView.methodName = @"SendValueiOSJSON";
    _webView.methodName = @"SendValueiOSMessage";
    _webView.methodName = @"JumpToNewVC";// 控制iOS 跳转控制器
    _webView.methodName = @"getJSON_iOS"; // 提供给h5 调用,返回给h5 一个json
    _webView.methodName = @"getPhoto"; // 监听唤起相机方法
    [self.view addSubview:self.webView];
}

// 重置返回按钮
-(void)initItems{
    // 后退按钮
    UIButton * goBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [goBackButton setImage:[UIImage imageNamed:@"backbutton"] forState:UIControlStateNormal];
    [goBackButton setTitle:@"后退" forState:UIControlStateNormal];
    [goBackButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [goBackButton addTarget:self action:@selector(goBackAction) forControlEvents:UIControlEventTouchUpInside];
    goBackButton.frame = CGRectMake(0, 0, 30, 64);
    UIBarButtonItem * goBackButtonItem = [[UIBarButtonItem alloc] initWithCustomView:goBackButton];
    
    UIBarButtonItem * jstoOc = [[UIBarButtonItem alloc] initWithTitle:@"首页" style:UIBarButtonItemStyleDone target:self action:@selector(localHtmlClicked)];
    self.navigationItem.leftBarButtonItems = @[goBackButtonItem,jstoOc];
    
    // 刷新按钮
    UIButton * refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [refreshButton setImage:[UIImage imageNamed:@"webRefreshButton"] forState:UIControlStateNormal];
    [refreshButton setTitle:@"Fount" forState:UIControlStateNormal];
    [refreshButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(setTextFount) forControlEvents:UIControlEventTouchUpInside];
    refreshButton.frame = CGRectMake(0, 0, 30, 64);
    UIBarButtonItem * refreshButtonItem = [[UIBarButtonItem alloc] initWithCustomView:refreshButton];
    
    UIBarButtonItem * ocToJs = [[UIBarButtonItem alloc] initWithTitle:@"PUSH" style:UIBarButtonItemStyleDone target:self action:@selector(pushVC)];
    self.navigationItem.rightBarButtonItems = @[refreshButtonItem, ocToJs];
}

// 首页
-(void)localHtmlClicked{
    if (![_absoluteString containsString:@"B.html"]) {
        [self.webView loadUrlString:self.absoluteString];
    }else{
        [self.webView loadUrlString:@"B.html"];
    }
}

// 后退
-(void)goBackAction{
    NSLog(@"后退----%d",[self.webView goBack]);
//    [self.webView goBack];
}


// 修改文字大小
-(void)setTextFount{
    //改变字体大小 调用原生JS方法, 不需要HTML 配置
    NSString *jsFont = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%d%%'", arc4random()%99 + 100];
    [self.webView evaluateJavaScript:jsFont completionHandler:nil];
}

// 推出控制器
-(void)pushVC{
    CViewController *rVC = [[CViewController alloc] init];
    [self.navigationController pushViewController:rVC animated:YES];
}


@end
