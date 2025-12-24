// SnapAny g-footer 拦截器 - 简化版
// 复制整个文件内容到浏览器控制台运行

(function() {
    console.log('🔍 SnapAny 拦截器已启动');
    
    // 拦截 Fetch API
    const originalFetch = window.fetch;
    window.fetch = function(...args) {
        const [url, options] = args;
        
        if (url.includes('api.snapany.com') || url.includes('extract')) {
            console.log('='.repeat(80));
            console.log('🎯 拦截到 API 请求！');
            console.log('URL:', url);
            console.log('Headers:', options?.headers);
            console.log('Body:', options?.body);
            
            if (options?.headers) {
                const gFooter = options.headers['g-footer'];
                const gTimestamp = options.headers['g-timestamp'];
                
                if (gFooter && gTimestamp) {
                    console.log('='.repeat(80));
                    console.log('✅ 捕获签名！');
                    console.log('g-footer:', gFooter);
                    console.log('g-timestamp:', gTimestamp);
                    console.log('Body:', options.body);
                    
                    try {
                        const bodyObj = JSON.parse(options.body);
                        const link = bodyObj.link || '';
                        console.log('Link:', link);
                        console.log('='.repeat(80));
                        console.log('📋 Python 测试代码：');
                        console.log('TEST_LINK = "' + link + '"');
                        console.log('TEST_TIMESTAMP = ' + gTimestamp);
                        console.log('ACTUAL_G_FOOTER = "' + gFooter + '"');
                    } catch (e) {}
                    
                    console.log('='.repeat(80));
                    console.log('调用堆栈：');
                    console.trace();
                    console.log('='.repeat(80));
                }
            }
        }
        
        return originalFetch.apply(this, args);
    };
    
    // 拦截 XMLHttpRequest
    const originalOpen = XMLHttpRequest.prototype.open;
    const originalSetRequestHeader = XMLHttpRequest.prototype.setRequestHeader;
    const xhrData = new WeakMap();
    
    XMLHttpRequest.prototype.open = function(method, url, ...rest) {
        if (url.includes('api.snapany.com') || url.includes('extract')) {
            xhrData.set(this, { method, url, headers: {} });
        }
        return originalOpen.apply(this, [method, url, ...rest]);
    };
    
    XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
        const data = xhrData.get(this);
        if (data) {
            data.headers[header] = value;
            if (header === 'g-footer' || header === 'g-timestamp') {
                console.log('🎯 拦截到头部:', header, '=', value);
                console.trace();
            }
        }
        return originalSetRequestHeader.apply(this, arguments);
    };
    
    console.log('✅ 拦截器安装完成！');
    console.log('🚀 现在可以在 SnapAny 网站上测试了');
})();

