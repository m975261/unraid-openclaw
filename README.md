# unraid-openclaw

> Auto-containerized for Unraid 7.0.1 by **TITAN Dockerizer v2.8**
> Source: [https://github.com/openclaw/openclaw](https://github.com/openclaw/openclaw)

## Docker Image
```
docker pull muaeabudhabi/openclaw:latest
```

## Install on Unraid
1. Download `unraid-templates/my-openclaw.xml`
2. Copy to `/boot/config/plugins/dockerMan/templates-user/`
3. Docker tab → Add Container → select `openclaw`

## Auto-Updates
| Workflow | Schedule | Purpose |
|---------|----------|---------|
| `docker-build.yml` | Push / Manual / Dispatch | Builds multi-arch image → DockerHub |
| `upstream-watch.yml` | Daily 02:00 UTC | Checks upstream releases → triggers rebuild |
