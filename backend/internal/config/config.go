package config

import (
	"github.com/spf13/viper"
)

// Config 应用配置
type Config struct {
	Environment string         `mapstructure:"environment"`
	Port        string         `mapstructure:"port"`
	LogLevel    string         `mapstructure:"log_level"`
	Database    DatabaseConfig `mapstructure:"database"`
	Redis       RedisConfig    `mapstructure:"redis"`
	JWT         JWTConfig      `mapstructure:"jwt"`
	AI          AIConfig       `mapstructure:"ai"`
}

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
	Host     string `mapstructure:"host"`
	Port     string `mapstructure:"port"`
	User     string `mapstructure:"user"`
	Password string `mapstructure:"password"`
	DBName   string `mapstructure:"dbname"`
	SSLMode  string `mapstructure:"sslmode"`
}

// RedisConfig Redis配置
type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     string `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
}

// JWTConfig JWT配置
type JWTConfig struct {
	Secret    string `mapstructure:"secret"`
	ExpiresIn int    `mapstructure:"expires_in"` // 小时
}

// AIConfig AI服务配置
type AIConfig struct {
	XunfeiAppID     string `mapstructure:"xunfei_app_id"`
	XunfeiAPIKey    string `mapstructure:"xunfei_api_key"`
	XunfeiAPISecret string `mapstructure:"xunfei_api_secret"`
	DeepSeekAPIKey  string `mapstructure:"deepseek_api_key"`
}

// Load 加载配置
func Load() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./configs")
	viper.AddConfigPath("/etc/dailyawareness/")

	// 设置默认值
	viper.SetDefault("environment", "development")
	viper.SetDefault("port", "8080")
	viper.SetDefault("log_level", "info")
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", "5432")
	viper.SetDefault("database.dbname", "daily_awareness")
	viper.SetDefault("database.sslmode", "disable")
	viper.SetDefault("redis.host", "localhost")
	viper.SetDefault("redis.port", "6379")
	viper.SetDefault("jwt.expires_in", 168) // 7天

	// 从环境变量读取
	viper.AutomaticEnv()

	var cfg Config
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, err
		}
	}

	if err := viper.Unmarshal(&cfg); err != nil {
		return nil, err
	}

	return &cfg, nil
}

// DSN 返回PostgreSQL连接字符串
func (c *DatabaseConfig) DSN() string {
	return "host=" + c.Host + " port=" + c.Port + " user=" + c.User +
		" password=" + c.Password + " dbname=" + c.DBName + " sslmode=" + c.SSLMode
}