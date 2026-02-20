# GetMac Buildkite Plugin

A [Buildkite plugin](https://buildkite.com/docs/plugins) that provisions ephemeral macOS virtual machines on [GetMac Cloud](https://getmac.io) for your CI/CD jobs.

Each Buildkite job gets a fresh macOS VM that is automatically created before the build and deleted after it completes.

## Requirements

- `curl`
- `jq`
- `ssh`

## Usage

```yaml
steps:
  - command: "make test"
    plugins:
      - getmac-io/getmac#v1.0.0:
          project-id: "2f8aa35f-b1d7-4425-bb26-889dfe92cb53"
```

## Configuration

### Required

#### `project-id` (string)

Your GetMac Cloud project ID.

### Optional

#### `image` (string, default: `macos-tahoe`)

The macOS image to use for the VM.

#### `machine-type` (string, default: `mac-m4-c4-m8`)

The machine type for the VM.

#### `region` (string, default: `eu-central-ltu-1`)

The region to provision the VM in.

#### `ssh-private-key-path` (string, default: `~/.ssh/id_rsa`)

Path to the SSH private key used to connect to the VM.

#### `api-url` (string, default: `https://api.getmac.io/v1`)

The GetMac Cloud API URL.

#### `debug` (boolean, default: `false`)

Enable debug logging.

## Environment Variables

### `GETMAC_CLOUD_API_KEY` (required)

Your GetMac Cloud API key. Set this as a Buildkite pipeline environment variable or agent environment hook for security — do not put it in your pipeline YAML.

## How It Works

1. **pre-command hook**: Creates a new macOS VM via the GetMac API and waits for it to boot.
2. **command hook**: Connects to the VM via SSH and executes the build command.
3. **pre-exit hook**: Deletes the VM to clean up resources.

## Example

```yaml
steps:
  - label: ":mac: Build & Test"
    command: "swift test"
    plugins:
      - getmac-io/getmac#v1.0.0:
          project-id: "2f8aa35f-b1d7-4425-bb26-889dfe92cb53"
          image: "macos-tahoe"
          machine-type: "mac-m4-c4-m8"
          region: "eu-central-ltu-1"
```

## License

MIT
