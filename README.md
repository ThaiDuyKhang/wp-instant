# WordPress Instant Setup (Docker + WP-CLI)

## Giới thiệu

WordPress Instant cài đặt WordPress hoàn toàn tự động bằng Docker với WP-CLI, không cần XAMPP, không cấu hình PHP/MySQL thủ công.

## Tính năng

- **Hoàn toàn tự động** - Một lệnh duy nhất
- **PHP 8.4** với tất cả extensions cần thiết
- **MySQL 8.0** với health checks
- **phpMyAdmin** dễ tuỳ chỉnh table database
- **WP-CLI** tích hợp sẵn
- **Auto-restart** containers
- **Tự động tạo** DB_NAME theo tên folder project, DB_USER, DB_PASS ngẫu nhiên
- **Tự động cài đặt** WordPress mới nhất
- **Tự động cài đặt** sẵn plugin backup WP-All in one

## Yêu cầu cài đặt

### Docker Desktop

- Windows / macOS: [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Sau khi cài đặt, khởi động Docker Desktop
- Kiểm tra: `docker --version` và `docker compose version`

### Git for Windows

- Download: [Git SCM](https://git-scm.com/downloads)
- Cần thiết để chạy bash scripts trên Windows
- Kiểm tra: `git --version`

## Hướng dẫn sử dụng

### Bước 1: Clone project

```bash
git clone https://github.com/ThaiDuyKhang/wp-instant.git
git clone wp-instant project-name
cd project-name
```

### Bước 2: Chạy script tạo site

```bash
.\create-site.ps1
```

Script sẽ tự động:

- Kiểm tra Docker có đang chạy không
- Tạo file `.env` với database credentials ngẫu nhiên
- Build và khởi động Docker containers
- Download WordPress core
- Tạo `wp-config.php`
- Cài đặt WordPress database
- Cài đặt plugins (All-in-One WP Migration)
- Hiển thị URL và credentials

### Bước 3: Truy cập WordPress

Sau khi hoàn thành:

- WordPress site is ready!
- Site URL: http://localhost:8081
- Dashboard URL: http://localhost:8081/wp-admin
- phpMyAdmin URL: http://localhost:8082
- Admin User: admin
- Admin Pass: admin

Mở trình duyệt và truy cập URL hiển thị.

## Cấu trúc Project

```
.
├── docker/
│   └── wordpress/
│       └── Dockerfile          # PHP 8.4 + Apache + WP-CLI + Extensions
├── scripts/
│   └── init.sh                 # WordPress initialization script
├── wp/                         # WordPress files (auto-generated)
├── plugins-private/            # Private plugins (optional)
├── .env.example                # Environment template
├── .env                        # Generated environment (auto-created)
├── docker-compose.yml          # Docker services configuration
├── gen-env.ps1                 # Generate .env script
└── create-site.ps1             # Main setup script
```

## Cấu hình

### File `.env`

File này được tạo tự động từ `.env.example`. Bạn có thể chỉnh sửa trước khi chạy:

```env
WP_PORT=8081                    # Port để truy cập WordPress
DB_NAME=test                    # Tên database (tự động tạo theo tên folder project)
DB_USER=randomuser              # Database user (tự động tạo ngẫu nhiên)
DB_PASS=randompass              # Database password (tự động tạo ngẫu nhiên)
SITE_URL=http://localhost:8081  # URL của site
SITE_TITLE=WordPress            # Tiêu đề site
ADMIN_USER=admin                # Admin username
ADMIN_PASS=admin                # Admin password
ADMIN_EMAIL=admin@example.com   # Admin email
```

### Thay đổi Port

Nếu port 8081 đã được sử dụng:

1. Sửa `WP_PORT` trong `.env.example` trước khi chạy
2. Hoặc sửa `.env` sau khi tạo và chạy `docker compose restart`

## Các lệnh hữu ích

```powershell
# Xem logs
docker compose logs -f

# Xem logs của service cụ thể
docker compose logs -f wordpress
docker compose logs -f db

# Restart containers
docker compose restart

# Stop containers
docker compose down

# Stop và xóa volumes (XÓA DỮ LIỆU!)
docker compose down -v

# Rebuild containers
docker compose up -d --build

# Chạy WP-CLI commands
docker compose exec wpcli wp plugin list --allow-root
docker compose exec wpcli wp theme list --allow-root
```

## phpMyAdmin

phpMyAdmin đã được tích hợp sẵn để quản lý database.

**Truy cập:** http://localhost:8082

**Đăng nhập:**

- **Server:** db
- **Username:** root
- **Password:** root

Hoặc sử dụng database user từ file `.env`:

- **Username:** Giá trị `DB_USER` trong `.env`
- **Password:** Giá trị `DB_PASS` trong `.env`
- **Database:** Giá trị `DB_NAME` trong `.env`

**Lưu ý:** phpMyAdmin chạy trên port 8082 mặc định. Nếu muốn thay đổi, sửa trong `docker-compose.yml`.

## Troubleshooting

### Lỗi: "Docker is not running"

**Giải pháp:** Mở Docker Desktop và đợi nó khởi động hoàn toàn.

### Lỗi: "Git Bash not found"

**Giải pháp:** Cài đặt Git for Windows từ https://git-scm.com/

Script sẽ tự động tìm Git Bash ở các vị trí:

- `C:\Program Files\Git\bin\bash.exe`
- `C:\Program Files (x86)\Git\bin\bash.exe`
- `%LOCALAPPDATA%\Programs\Git\bin\bash.exe`

### Lỗi: "MySQL failed to become healthy"

**Nguyên nhân:** MySQL container không khởi động được.

**Giải pháp:**

```powershell
# Xem logs MySQL
docker compose logs db

# Thử restart
docker compose restart db

# Nếu vẫn lỗi, xóa và tạo lại
docker compose down -v
.\create-site.ps1
```

### Lỗi: "Port already in use"

**Nguyên nhân:** Port 8081 đã được sử dụng bởi ứng dụng khác.

**Giải pháp:**

1. Sửa `WP_PORT` trong `.env` thành port khác (ví dụ: 8082)
2. Chạy `docker compose up -d`

### WordPress hiển thị lỗi "Error establishing database connection"

**Giải pháp:**

```powershell
# Kiểm tra MySQL có healthy không
docker compose ps

# Nếu không healthy, xem logs
docker compose logs db

# Restart containers
docker compose restart
```

### Không thể upload hình ảnh hoặc cài plugin

**Nguyên nhân:** PHP upload limits quá thấp.

**Giải pháp:** Dockerfile đã được cấu hình với:

- `upload_max_filesize = 64M`
- `post_max_size = 64M`

Nếu cần tăng thêm, sửa `docker/wordpress/Dockerfile` và rebuild:

```powershell
docker compose up -d --build
```

### Muốn reset toàn bộ và bắt đầu lại

```powershell
# Xóa containers và volumes
docker compose down -v

# Xóa WordPress files
Remove-Item -Recurse -Force .\wp

# Xóa .env
Remove-Item .env

# Chạy lại
.\create-site.ps1
```

## Security Notes

**QUAN TRỌNG:** Setup này dành cho **môi trường development** local.

Trước khi deploy lên production:

1. Đổi `ADMIN_USER` và `ADMIN_PASS` thành giá trị mạnh
2. Đổi `DB_USER` và `DB_PASS` thành giá trị phức tạp
3. Cấu hình SSL/HTTPS
4. Thêm firewall rules
5. Backup thường xuyên

## Private Plugins

Để cài đặt private plugins (không có trên WordPress.org):

1. Tạo folder `plugins-private/` (nếu chưa có)
2. Copy file `.zip` của plugin vào folder này
3. Sửa `scripts/init.sh` để thêm plugin:

```bash
PRIVATE_PLUGIN="/plugins-private/your-plugin.zip"

if docker compose exec wpcli test -f "$PRIVATE_PLUGIN"; then
  docker compose exec wpcli wp plugin install "$PRIVATE_PLUGIN" \
    --path=$WP_PATH \
    --activate \
    --allow-root
fi
```
