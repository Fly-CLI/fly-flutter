# service

Fly foundation service scaffolding brick for generating services.

## Description

This brick generates service scaffolding for existing Fly projects, supporting:

- API services (with retry, caching, interceptors)
- Local services
- Cache services
- Analytics services
- Storage services

## Usage

This brick is typically used via the Fly CLI:

```bash
fly generate service my_service --feature=api --service-type=api --template=fly_foundation
```

Variables are passed programmatically by the Fly CLI orchestrator. For manual usage, see the [Fly CLI documentation](https://github.com/fly-cli/fly).

## License

See the main Fly repository for license information.

