# 🚀 My DevSecOps Journey — TaskBoard

## Lesson 01 — What is DevOps / DevSecOps? + the terminal (2026-10-25)
- Learned: DevSecOps = security in every step. My first commands: pwd, ls, cd, mkdir.
- Broke: `docker` failed in Ubuntu with `failed to connect to the docker API at unix:///var/run/docker.sock ... no such file or directory`.
- Fixed: the socket file didn't exist because Docker Desktop's WSL integration was off for Ubuntu. Turned on Settings → Resources → WSL integration → Ubuntu, restarted Docker Desktop. `docker version` now shows a `Server:` section.
- Security note: `docker.sock` = full control of the machine. Never expose it or mount it into a container.

## Lesson 02 — Files, folders, permissions & nano (2026-10-25)
- Learned: cp / mv / rm, wildcards, editing with nano, reading `-rwxr-xr-x`, chmod with letters (`u+x`) and numbers (`644`, `755`, `600`), chown.
- Broke: nothing this time 🎉
- Fixed: —
- Security note: played the attacker with the `nobody` user. At 644 it could read my fake password, at 600 it was blocked, at 777 it overwrote the file. Never `chmod 777`; secrets get `600`.
- Project: built the skeleton (`app/api`, `app/frontend`, `docs`, `scripts`) and wrote the first README.md with nano.

## Lesson 03 — Processes, apt, env variables, pipes & scripts (2026-10-26)
- Learned: ps/kill, apt, export, pipes, my first real script
- Broke: nothing
- Fixed: nothing

## Lesson 04 — Networking: IP, ports, DNS, HTTP, curl (2026-10-31)
- Learned: IP addresses, ports, DNS, HTTP requests and status codes, curl.
- Project: wrote `docs/network-plan.md`: frontend 8080 → api 5000 → postgres 5432, database never exposed.

## Lesson 05 — Git & GitHub (2026-10-31)
- Project: the repo went public on GitHub, with a `.gitignore` for secrets and a finished README.
- Security note: commits use my GitHub noreply address, so my real email stays private.
