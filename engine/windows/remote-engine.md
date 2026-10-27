# MySQL and the engine on different machines

The engine package's install guide, [README.md](README.md) beside this file, puts the engine on one machine, where it takes connections from that machine only. Nothing in this file is needed when the MySQL servers with the plugin and the reporting tools are on that machine too.

The engine can also run elsewhere, and one engine can serve several MySQL servers. Each server is one `[sources.<name>]` entry in the engine's config, and the optional MySQL shim's plugin goes on each server that should create and query tables from inside MySQL. A mixed install is fine: the engine on the machine of one MySQL server, and other servers reaching it over the network.

## What crosses the network

- The plugin opens connections to the engine's port (9742). The rows of a `CREATE TABLE ... ENGINE=AXIALDB` go to the engine over them, and query results come back.
- The engine opens connections to MySQL: to the main instance when a live table is created (it reads the source tables' columns and keys and the server's position there, also for a `CREATE` typed in MySQL) and for `axialdb create-table` and `axialdb drop-table`, and to the main instance or a replica to read the binlog for live tables.
- Clients (the `axialdb` command line, the SDK, ODBC, JDBC) connect to the engine's port.

**Without TLS all of it is clear text**: table rows, query results, and SQL. The secrets described below are not sent, but someone who can change traffic inside your network could take over a connection after it has proven its secret. Turn TLS on (below) unless the machines are on a network you trust the way you trust the machines themselves.

## On the engine's machine

`/etc/axialdb/axialdb.toml` (Windows: `C:\ProgramData\AxialDB\mysql\axialdb.toml`):

```toml
[helper]
listen = "0.0.0.0:9742"        # or one address of this machine

[access]
client_secret = "a long random text"      # for the axialdb CLI, the SDK, ODBC, JDBC
# tls_cert = "engine-cert.pem"            # both, to accept TLS
# tls_key = "engine-key.pem"

[sources.orders]                          # one entry per MySQL server; the name is yours
kind = "mysql"
shim_secret = "another long random text"  # what this server's plugin proves
host = "10.0.0.5"                         # the MySQL server, as the engine reaches it
port = 3306
user = "axialdb"                          # live tables, and creates and drops from the command line
password = "..."
capture_user = "axialdb_cdc"              # live tables only: reads the binlog
capture_password = "..."
capture_server_id = 19001                 # different for every source
```

Rules the engine follows:

- A connection from the engine's own machine needs no secret, as before.
- A connection from another machine proves a secret before it may do anything. The secret is not sent: the engine sends a random challenge, and the caller answers with a keyed hash of it.
- `client_secret` opens everything a client does. A source's `shim_secret` opens only what that server's plugin does, and only for that source's tables.
- Treat `client_secret` as an administrator's secret: whoever holds it can create and drop tables. The engine writes every request that changes something and does not come from a plugin to its log as `admin request`, with the caller's address, how it was let in (this machine, client secret, open network), and the table. Queries are not logged.
- The engine does not start with `listen` beyond its own machine and no secret in the config. `allow_open_network = true` under `[access]` turns that check off: anyone who reaches the port may then query, create, and drop, and through the engine acts on MySQL under the source's account. Use it on a closed lab network only.
- With `tls_cert` and `tls_key` set, every connection from another machine has to use TLS: each plugin (`tls = true`) and each client. The engine's own machine may still connect in the clear.

Open port 9742 on the engine's machine for the MySQL servers and the clients. On each MySQL server, let the engine's machine reach MySQL's port, and create the accounts for its address (`'axialdb'@'<engine address>'`, `'axialdb_cdc'@'<engine address>'`) with the grants the install guide lists.

Restart `axialdb-engine` after changing its config.

## On each MySQL server

Install the plugin, the bridge, and the helper functions as the MySQL shim package's guide says. There is no engine and no `axialdb.toml` on this machine. The server has a small file of its own, `axialdb-shim.toml` (a copy is in the MySQL shim package):

```toml
engine = "10.0.0.9:9742"                   # the engine's machine
source = "orders"                          # this server's [sources.<name>] on the engine
secret_file = "/etc/axialdb/shim.secret"   # one line: the source's shim_secret
# tls = true
# tls_ca = "/etc/axialdb/engine-cert.pem"  # the engine's certificate, or the authority that signed it
query_timeout_secs = 300
publish_retry_secs = 15
log_level = "info"
```

Linux:

```bash
sudo mkdir -p /etc/axialdb
sudo cp axialdb-shim.toml /etc/axialdb/axialdb-shim.toml       # then edit engine and source
printf '%s\n' 'another long random text' | sudo tee /etc/axialdb/shim.secret >/dev/null
sudo chown mysql:mysql /etc/axialdb/shim.secret
sudo chmod 600 /etc/axialdb/shim.secret
sudo mkdir -p /etc/systemd/system/mysql.service.d
sudo tee /etc/systemd/system/mysql.service.d/axialdb.conf >/dev/null <<'EOF'
[Service]
Environment=AXIALDB_CONFIG=/etc/axialdb/axialdb-shim.toml
EOF
sudo systemctl daemon-reload
sudo systemctl restart mysql
```

Windows: put `axialdb-shim.toml` and `shim.secret` in `C:\ProgramData\AxialDB\mysql\`, keep the Machine variable `AXIALDB_CONFIG` at `C:\ProgramData\AxialDB`, let only the MySQL service account and administrators read `shim.secret` (`icacls ... /inheritance:r /grant:r "NT SERVICE\MySQL97:(R)" "Administrators:(F)"`), and restart MySQL.

Check from MySQL:

```sql
SELECT axialdb_init();
```

It opens a connection to the engine, proves the secret, and says which source this server is. An error names what is wrong: the engine cannot be reached, the secret does not match, or the source is not in the engine's config.

## One source is one server

The engine learns a server's id (`@@server_uuid`) from its plugin. Two servers must not use the same source name. Every table records the server it was made on, snapshot and live alike. While a source has any table, the engine refuses a different server under that name and names both ids. After a main instance has really been replaced by a server with a new id (see "Manual disaster recovery" in the design notes), drop the old server's tables, snapshot tables too, and create them again; the name is then free for the new server. A server restored with its data folder keeps its id and needs none of this.

Two servers that have a database and a table of the same name would land on the same AxialDB name with the default naming. The second create is refused with a message that says so. Give each source its own naming keys (`target_schema`, `prefix_source`) or name the schema in the create (`COMMENT='schema=...'`, `--schema`).

## Clients on another machine

| Client | The secret | TLS |
|--------|------------|-----|
| `axialdb` command line | `--secret-file path`, or the environment variable `AXIALDB_SECRET`. There is no flag for the secret itself | `--tls-ca path` |
| SDK (Rust) | `Client::connect_with_secret(address, secret)`, or `Client::connect_with(ConnectOptions { .. })` | `tls` and `tls_ca` in `ConnectOptions` |
| ODBC | `PWD=` in the DSN or the connection string, with `AllowRemote=1`. The user name is ignored | `TlsCa=path` |
| JDBC | the password field. The user name is ignored | the driver property `tlsCa` |

`tls_ca` is a PEM file with the engine's certificate, or with the certificate of the authority that signed it. The certificate has to name the address the clients use for the engine (a DNS name or an IP address in its subject alternative names).

A certificate of the engine's own, signed by nobody else, is made with OpenSSL. The address is the one the clients use; the key stays on the engine's machine, readable by the engine's service account only; `engine-cert.pem` is what every client and every MySQL server names as `tls_ca`:

```bash
openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj "/CN=axialdb-engine" -addext "subjectAltName=IP:10.0.0.9" -keyout engine-key.pem -out engine-cert.pem
```

## When the connection is lost during a CREATE

- Before MySQL has committed the `CREATE TABLE`: the statement fails, and MySQL has no table. What the engine had received is removed by the engine.
- After MySQL has committed and before the engine was told to publish: the plugin keeps trying for `publish_retry_secs`. If that fails too, the statement ends with an error that says the table is created in MySQL and not published. The engine keeps the rows. The next statement that uses the table publishes it; until then a query on it fails with a message, and `DROP TABLE` removes both halves. When nobody uses the table, the engine settles it itself: about once an hour it asks the MySQL server, with the account under `[sources.<name>]`, whether the table exists, and publishes it when it does. That takes between one and two hours after the create. It also covers a MySQL restart before the first use of the table, after which the plugin no longer knows that the table was waiting. A source with no `user` set cannot be asked: there the engine removes such a table after about an hour, and the MySQL table has to be dropped and created again.

## Upgrades

The plugin and the engine no longer have to be replaced in the same moment. The plugin tells the engine which protocol it speaks; when the two differ, the engine refuses that server's plugin with a message that says which side is older. Release notes say when the protocol changes and which side to upgrade first. A difference in build alone is written to the engine's log.
