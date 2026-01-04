# WordPress Instant Setup (Docker + WP-CLI)

## Giới thiệu

WordPress Instant Setup giúp bạn tạo project WordPress local chỉ với 1 lệnh,
không cần XAMPP, không cấu hình PHP/MySQL thủ công.

## Tính năng chính

- Cài WordPress stable mới nhất
- Tuỳ chọn PHP version (8.2 / 8.4)
- MySQL chạy trong Docker
- Tự động tạo database & user
- Script an toàn (chạy lại không lỗi)
- Backup / restore database & uploads
- Dễ dàng clone & tiếp tục làm việc ở máy khác

## Yêu cầu cài đặt

### Docker Desktop

- Windows / macOS: [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Linux: Docker Engine + Docker Compose v2

### Git + Git Bash

Download: [Git SCM](https://git-scm.com/downloads)

### Terminal

- Windows: Git Bash
- macOS / Linux: Terminal mặc định

## Hướng dẫn sử dụng nhanh

**Bước 1: Clone project**

```bash
git clone https://github.com/ThaiDuyKhang/wp-instant.git
git clone wp-instant-template project-name
cd project-name
```

**Bước 2: Tạo file .env (tuỳ chọn)**

```bash
cp .env.example .env
```

**Bước 3: Chạy Docker**

```bash
docker compose up -d
```

**Bước 4: Tạo project & chạy setup**

```bash
cd path\project-name
chmod +x scripts/init.sh
./scripts/init.sh
```

**Nhập thông tin tạo cấu hình**

- Database name
- Database user / password
- Site title
- Admin username / password / email

### Bước 4: Mở và cài đặt WordPress

Mở website: http://localhost:8080
