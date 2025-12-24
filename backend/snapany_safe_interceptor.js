// SnapAny g-footer 安全拦截器
// 此版本只监听，不修改任何请求

(function() {
    console.log('%c🔍 安全拦截器已启动', 'background: #28a745; color: white; padding: 5px; font-weight: bold;');
    
    // 方法 1: 监听 fetch（不干扰原始行为）
    const originalFetch = window.fetch;
    window.fetch = function(...args) {
        const [url, options] = args;
        
        // 只记录，不修改
        if (url.includes('api.snapany.com') || url.includes('extract')) {
            // 克隆参数以避免修改
            const safeOptions = JSON.parse(JSON.stringify(options || {}));
            
            console.log('%c════════════════════════════════════════════════════════════════════════════════', 'color: #667eea');
            console.log('%c🎯 检测到 SnapAny API 请求', 'background: #667eea; color: white; padding: 5px; font-weight: bold;');
            console.log('📡 URL:', url);
            console.log('📋 Method:', safeOptions.method || 'GET');
            
            if (safeOptions.headers) {
                console.log('📨 Headers:');
                for (let [key, value] of Object.entries(safeOptions.headers)) {
                    if (key === 'g-footer' || key === 'g-timestamp') {
                        console.log(`  %c${key}: ${value}`, 'color: #28a745; font-weight: bold;');
                    } else {
                        console.log(`  ${key}: ${value}`);
                    }
                }
            }
            
            if (safeOptions.body) {
                console.log('📦 Body:', safeOptions.body);
                try {
                    const bodyObj = JSON.parse(safeOptions.body);
                    console.log('📹 Parsed Body:', bodyObj);
                    
                    // 生成测试代码
                    if (bodyObj.link && safeOptions.headers) {
                        console.log('%c════════════════════════════════════════════════════════════════════════════════', 'color: #764ba2');
                        console.log('%c📋 Python 测试代码（复制使用）：', 'background: #764ba2; color: white; padding: 5px; font-weight: bold;');
                        console.log(`TEST_LINK = "${bodyObj.link}"`);
                        console.log(`TEST_TIMESTAMP = ${safeOptions.headers['g-timestamp'] || 0}`);
                        console.log(`ACTUAL_G_FOOTER = "${safeOptions.headers['g-footer'] || ''}"`);
                        console.log('%c════════════════════════════════════════════════════════════════════════════════', 'color: #764ba2');
                    }
                } catch (e) {
                    console.log('⚠️ Body 解析失败:', e.message);
                }
            }
            
            console.log('%c════════════════════════════════════════════════════════════════════════════════', 'color: #667eea');
        }
        
        // 完全不修改，直接调用原始函数
        return originalFetch.apply(this, args);
    };
    
    // 方法 2: 使用性能监控 API（完全非侵入式）
    if (window.PerformanceObserver) {
        try {
            const observer = new PerformanceObserver((list) => {
                for (const entry of list.getEntries()) {
                    if (entry.name.includes('api.snapany.com')) {
                        console.log('%c⚡ 性能监控检测到 API 请求', 'background: #ffc107; color: black; padding: 5px;');
                        console.log('URL:', entry.name);
                        console.log('Duration:', entry.duration, 'ms');
                        console.log('Size:', entry.transferSize, 'bytes');
                    }
                }
            });
            
            observer.observe({ entryTypes: ['resource'] });
            console.log('✅ 性能监控已启用');
        } catch (e) {
            console.log('⚠️ 性能监控不可用:', e.message);
        }
    }
    
    console.log('%c✅ 安全拦截器安装完成！', 'background: #28a745; color: white; padding: 5px; font-weight: bold;');
    console.log('%c💡 提示：此版本不会修改任何请求，保证原有功能正常', 'color: #667eea;');
    console.log('%c🚀 现在可以在 SnapAny 测试了，刷新页面后再次运行此脚本', 'color: #667eea;');
})();

