## SofwareLLC Docker Container for Que-Web

#### Description

Docker Container for Que-Web
Gem Included: [que-web](https://github.com/statianzo/que-web)
This will create the root endpoint for the Que-Web Interface

#### Environment Variables

- DATABASE_URL
- PORT

#### Build Instructions

```bash
 docker build -t sofware-que-web -f Dockerfile .
```

#### Run Instructions

```bash
docker run --env-file=env_development -p 3002:<Environment PORT> sofware-que-web
```
