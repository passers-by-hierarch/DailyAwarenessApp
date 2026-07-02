package redis

import (
	"context"
	"fmt"
	"time"

	"github.com/dailyawareness/backend/internal/config"
	"github.com/redis/go-redis/v9"
)

// Client Redis客户端封装
type Client struct {
	client *redis.Client
}

// NewClient 创建Redis客户端
func NewClient(cfg config.RedisConfig) (*Client, error) {
	client := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", cfg.Host, cfg.Port),
		Password: cfg.Password,
		DB:       cfg.DB,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to connect to redis: %w", err)
	}

	return &Client{client: client}, nil
}

// Close 关闭连接
func (c *Client) Close() error {
	return c.client.Close()
}

// Get 获取值
func (c *Client) Get(ctx context.Context, key string) (string, error) {
	return c.client.Get(ctx, key).Result()
}

// Set 设置值
func (c *Client) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	return c.client.Set(ctx, key, value, expiration).Err()
}

// Del 删除键
func (c *Client) Del(ctx context.Context, keys ...string) error {
	return c.client.Del(ctx, keys...).Err()
}

// Client 返回底层redis客户端
func (c *Client) Client() *redis.Client {
	return c.client
}