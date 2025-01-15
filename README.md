# README

Deployed using Kamal, accessed via Cloudflare Tunnel:

- Ensure ssh works via public key to hostname specified in `config/deploy.yml` (under `servers` -> `web`)
- Set `KAMAL_REGISTRY_PASSWORD` env variable (`set -Ux FOO bar` in fish shell)
- Ensure tunnel is setup pointing to same hostname specified in `config/deploy.yml` (under `proxy` -> `host`)
- Run `kamal setup`
