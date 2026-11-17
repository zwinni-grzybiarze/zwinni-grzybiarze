# OnlyShrooms
## Local docker deployment

Full rebuild + start (removes any old `onlyshrooms` container first):

```bash
./run-lan.sh
```

Or equivalently:

```bash
docker rm -f onlyshrooms onlyshrooms-dev 2>/dev/null || true
docker compose up --build --force-recreate --remove-orphans
```

App: `http://localhost:18000` (host port; avoids clash with Trilium on 8080).
