# Coolify Database Restore Tool

A utility script for managing and restoring PostgreSQL database backups in Coolify environments.

## ⚠️ Disclaimer

This tool is not officially affiliated with Coolify. Use at your own risk. Always ensure you have proper backups before performing any database operations.

- This script performs destructive operations (dropping and recreating databases)
- Test in a non-production environment first
- Verify your backup files before running a restore
- The script assumes default Coolify container and database naming conventions

## 🚀 Features

- Lists available backups with human-readable dates
- Handles backup extraction and restoration
- Automatically manages database connections
- Restarts Coolify containers after restore
- Supports both Linux and macOS environments

## 📋 Prerequisites

- Docker installed and running
- Access to Coolify backup directory
- Appropriate permissions to:
  - Read backup files
  - Execute Docker commands
  - Restart Coolify containers

## 🛠️ Installation

1. Clone this repository:
```bash
git clone https://github.com/dwillitzer/coolify-db-restore.git
cd coolify-db-restore
```

2. Make the script executable:
```bash
chmod +x restore-coolify-db.sh
```

## 📖 Usage

### List Available Backups

```bash
./restore-coolify-db.sh
```

Example output:
```
Available backups:
----------------------------------------
DATE                      TIMESTAMP        FILEPATH
----------------------------------------
2024-02-07 10:00:01      1737590401      /data/coolify/backups/.../pg-dump-all-1737590401.gz
2024-02-06 10:00:01      1737504001      /data/coolify/backups/.../pg-dump-all-1737504001.gz
```

### Restore a Backup

```bash
./restore-coolify-db.sh 1737590401
```

Example output:
```
Starting database restore process...
Using backup file: /data/coolify/backups/coolify/coolify-db-hostdockerinternal/pg-dump-all-1737590401.gz

Extracting backup file...

Copying backup file to container...

Executing restore commands in container...
Terminating existing connections...
Dropping and recreating database...
Restoring database...
Verifying restoration...
Table count:
 count 
-------
    60
(1 row)

Cleaning up temporary files...

Restarting Coolify containers...

Waiting for containers to be ready...

Current Coolify container status:
CONTAINER ID   IMAGE                           COMMAND                  STATUS          NAMES
abc123def456   coolify/coolify:latest         "docker-entrypoint.s…"   Up 8 seconds    coolify
def456abc789   postgres:14-alpine             "docker-entrypoint.s…"   Up 10 seconds   coolify-db

Restore process completed!

To verify or make manual adjustments, you can connect to the container with:
docker exec -it coolify-db bash
```

## ⚙️ Configuration

Default configuration in the script:
```bash
BACKUP_DIR="/data/coolify/backups/coolify/coolify-db-hostdockerinternal"
CONTAINER_NAME="coolify-db"
DB_USER="coolify"
DB_NAME="coolify"
```

Modify these variables in the script if your setup differs from the default Coolify installation.

## 🔍 Troubleshooting

### Common Issues

1. **Permission Denied**
```bash
sudo chown -R yourusername:yourusername /path/to/script
```

2. **Backup Directory Not Found**
   - Verify the backup directory path
   - Check if backups are stored in a different location

3. **Container Restart Issues**
   - Manually restart containers: `docker restart coolify*`
   - Check container logs: `docker logs coolify-db`

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Coolify](https://coolify.io/) - The self-hostable Heroku/Netlify alternative
- Contributors to this tool

## 📞 Support

- Create an issue in this repository
- Join the [Coolify Discord](https://coolify.io/discord/) community

---

**Note**: This is a community tool. For official Coolify support, please refer to the [official Coolify documentation](https://coolify.io/docs/).
```
