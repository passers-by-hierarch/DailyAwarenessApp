.PHONY: build run test clean docker-build docker-up docker-down migrate

# 构建
build:
	go build -o bin/api ./cmd/api/main.go

# 运行
run:
	go run ./cmd/api/main.go

# 测试
test:
	go test -v ./...

# 清理
clean:
	rm -rf bin/

# Docker构建
docker-build:
	docker-compose build

# Docker启动
docker-up:
	docker-compose up -d

# Docker停止
docker-down:
	docker-compose down

# 数据库迁移（使用GORM自动迁移）
migrate:
	go run ./cmd/api/main.go

# 安装依赖
deps:
	go mod download
	go mod tidy

# 代码格式化
fmt:
	go fmt ./...

# 代码检查
lint:
	golangci-lint run

# 生成swagger文档
swagger:
	swag init -g ./cmd/api/main.go