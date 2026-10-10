# Backup and recovery
Production PostgreSQL: use restricted backup role and `pg_dump --format=custom` to encrypted
storage with access logs and an owner-defined expiry. Never place dumps in the repository.
Local SQLite: stop writes and use SQLite's backup API; copying a live WAL database is insufficient.
Store secrets separately from dumps and encrypt transport/storage. Test restoration into an
isolated empty database with `pg_restore`, then run migrations, /ready and user-isolation smoke tests.
Treat dumps as sensitive: report comments and account emails remain present until backup expiry.
Record deletion requests separately so restoration does not resurrect deleted accounts silently.
Target recovery time/point objectives are owner-defined and must be tested before release.
No backup service has been provisioned or restoration exercise run against production.
