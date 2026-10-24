# 第一阶段：构建 GitBook
FROM node:12-alpine AS builder

# 安装 gitbook-cli
RUN npm install -g gitbook-cli

WORKDIR /book

# 复制仓库所有文件（你需要先把代码克隆到本地上下文）
COPY . .

# 安装 book.json 中定义的插件（如果报错可注释掉这行试试）
RUN gitbook install

# 构建静态网站到 _book 目录
RUN gitbook build

# 第二阶段：最小化运行镜像
FROM nginx:alpine

# 复制构建产物到 Nginx 默认目录
COPY --from=builder /book/_book /usr/share/nginx/html

# 暴露 80 端口
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
