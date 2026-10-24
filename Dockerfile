# ============================================================
# 第一阶段：构建 GitBook
# 使用 Node 12 Alpine 镜像，因为旧版 gitbook-cli 对 Node 版本敏感
# ============================================================
FROM node:12-alpine AS builder

# 安装 gitbook-cli（GitBook 官方旧版命令行工具）
RUN npm install -g gitbook-cli

# ------------------------------------------------------------
# 关键修复：解决 Node 12+ 下 gitbook-cli 报
# "cb.apply is not a function" 的兼容性问题
# 原因：gitbook-cli 内置的 npm 依赖了旧版 graceful-fs，
#       其 polyfills.js 在新 Node 环境下会崩溃
# 做法：删除旧的 polyfills.js，替换为社区验证过的修复版本
# ------------------------------------------------------------
RUN cd /usr/local/lib/node_modules/gitbook-cli/node_modules/npm/node_modules/graceful-fs \
    && rm -f polyfills.js \
    && wget -q https://raw.githubusercontent.com/isaacs/node-graceful-fs/168bdb8f0bb3174e8499d4bc5878deead4172c39/polyfills.js

# 设置工作目录为书籍根目录
WORKDIR /book

# 复制仓库全部文件到镜像中（需在本地先克隆 english-note 仓库）
COPY . .

# 安装 book.json 中声明的 GitBook 插件
# 若 book.json 中没有必需插件，此步骤可尝试注释掉以简化构建
RUN gitbook install

# 构建静态网站，产物默认输出到 _book 目录
RUN gitbook build

# ============================================================
# 第二阶段：最小化运行镜像
# 仅复制构建产物到 Nginx，最终镜像体积小、无 Node 运行时
# ============================================================
FROM nginx:alpine

# 将第一阶段生成的静态文件复制到 Nginx 默认站点目录
COPY --from=builder /book/_book /usr/share/nginx/html

# 暴露 HTTP 端口
EXPOSE 80

# 前台运行 Nginx，保持容器不退出
CMD ["nginx", "-g", "daemon off;"]
