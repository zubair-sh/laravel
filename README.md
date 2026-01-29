# Laravel Docker

Multi-environment Laravel setup with Docker (Development, Staging, Production).

## Quick Start

```bash
# Initialize development environment
make init

# Access application
open http://localhost:8000

# View Mailpit (email testing)
open http://localhost:8025
```

## Prerequisites

- Docker Desktop installed and running

## Environments

| Environment | Port | Command                    |
| ----------- | ---- | -------------------------- |
| Development | 8000 | `make init`                |
| Staging     | 8001 | `make init ENV=staging`    |
| Production  | 80   | `make init ENV=production` |

## Common Commands

```bash
# Container Management
make up              # Start containers
make down            # Stop containers
make restart         # Restart containers
make build           # Rebuild containers
make logs            # View logs
make ps              # List containers

# Laravel
make artisan ARGS="migrate"
make artisan ARGS="make:model Product -m"
make artisan ARGS="make:controller ProductController"
make composer ARGS="require laravel/sanctum"
make npm ARGS="install"
make migrate         # Run migrations
make fresh           # Fresh migration + seed
make test            # Run tests

# Database
make mysql           # Access MySQL shell
make redis           # Access Redis CLI
make backup          # Backup database and storage
make restore FILE=backups/db_xxx.sql

# Maintenance
make cache-clear     # Clear all caches
make optimize        # Optimize for production
make permissions     # Fix file permissions
make clean           # Remove containers and volumes

# Deployment
make deploy ENV=production

# Help
make help            # Show all commands
```

## Services

- **PHP 8.2-FPM** - Application server
- **Nginx** - Web server
- **MySQL 8.0** - Database
- **Redis** - Cache & Queue
- **Queue Worker** - Background jobs
- **Scheduler** - Cron jobs
- **Mailpit** - Email testing (dev only)

## Project Structure

```
.
├── src/                         # Laravel application
│   ├── app/                    # Application code
│   ├── config/                 # Configuration
│   ├── database/               # Migrations & seeds
│   ├── public/                 # Public assets
│   ├── resources/              # Views & assets
│   ├── routes/                 # Routes
│   ├── storage/                # Storage files
│   ├── tests/                  # Tests
│   └── .env                    # Environment file
├── docker/                      # Docker configuration
│   ├── Dockerfile              # PHP-FPM image
│   ├── entrypoint.sh          # Container startup
│   ├── nginx/conf.d/          # Nginx config
│   ├── php/local.ini          # PHP settings
│   ├── mysql/my.cnf           # MySQL config
│   └── supervisord/           # Supervisor config
├── docker-compose.yml          # Development
├── docker-compose.staging.yml  # Staging
├── docker-compose.prod.yml     # Production
├── .env.development           # Dev environment template
├── .env.staging              # Staging environment template
├── .env.production           # Production environment template
├── Makefile                  # All commands
└── README.md                 # This file
```

## Environment Variables

Copy the appropriate environment file:

```bash
# Development (default)
cp .env.development .env

# Staging
cp .env.staging .env

# Production
cp .env.production .env
```

Update credentials before deploying to staging/production.

## Examples

```bash
# Development workflow
make init                                    # Setup
make artisan ARGS="make:model Product -m"   # Create model
make migrate                                 # Run migration
make test                                    # Run tests

# Staging deployment
make init ENV=staging
make deploy ENV=staging

# Production deployment
make init ENV=production
make deploy ENV=production
make optimize ENV=production

# Daily tasks
make logs                                    # Check logs
make backup                                  # Backup database
make artisan ARGS="queue:work"              # Run queue worker
```

## Troubleshooting

```bash
# View logs
make logs

# Access container shell
make shell

# Fix permissions
make permissions

# Clear caches
make cache-clear

# Restart everything
make down && make up

# Clean start
make clean
make init
```

## Production Checklist

Before deploying to production:

- [ ] Update `.env.production` with real credentials
- [ ] Set `APP_DEBUG=false`
- [ ] Generate strong `APP_KEY`
- [ ] Use strong database passwords
- [ ] Configure SSL certificates
- [ ] Set up automated backups
- [ ] Configure monitoring

## SSL/HTTPS (Production)

1. Place SSL certificates in `docker/nginx/ssl/`
2. Update `docker/nginx/conf.d/default.conf` for HTTPS
3. Rebuild: `make build ENV=production`

## Backup & Restore

```bash
# Backup
make backup

# Restore
make restore FILE=backups/db_20260129_120000.sql
```

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
