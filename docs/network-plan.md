# TaskBoard — Network plan

Which port each piece uses, and who may talk to whom.

| Piece    | What it is       | Listens on | Open on my laptop?  | Who may connect |
|----------|------------------|------------|---------------------|-----------------|
| frontend | web page (nginx) | 8080       | yes, 127.0.0.1:8080 | my browser      |
| api      | Python Flask API | 5000       | yes, 127.0.0.1:5000 | frontend        |
| postgres | database         | 5432       | no                  | api only        |

## Traffic flow

browser → frontend :8080 → api :5000 → postgres :5432

## Security rules

1. Every port is above 1024, so no piece needs to run as root.
2. On my laptop, ports open on 127.0.0.1 only, never on 0.0.0.0.
3. The database is never reachable from outside. Only the api talks to it.
4. Plain HTTP stays inside my laptop. Anything that travels further uses HTTPS.
5. A new port must be added to this file first.
