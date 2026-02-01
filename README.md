# Home Assistant Configuration

This repository contains the configuration files for a Home Assistant installation.

## Repository Structure

```
.
├── configuration.yaml      # Main configuration file
├── automations.yaml        # Automation definitions
├── scripts.yaml            # Custom scripts
├── scenes.yaml             # Scene definitions
├── lovelace/               # Lovelace dashboard configurations
│   └── home.yaml           # Home dashboard
└── blueprints/             # Automation and script blueprints
    ├── automation/
    └── script/
```

## Key Components

### Configuration Files

- **configuration.yaml**: Main configuration file that includes:
  - Frontend configuration with theme support
  - Lovelace dashboard setup in YAML mode
  - HomeKit integration with exposed entities
  - Shell commands for configuration management
  - Logger settings

- **scripts.yaml**: Contains custom scripts:
  - `hello`: Welcome home script that activates the home scene
  - `goodbye`: Departure script with staged scene transitions
  - `git_pull_and_reload`: Pulls latest configuration from git and reloads Home Assistant

- **automations.yaml**: Currently empty, ready for automation definitions

- **scenes.yaml**: Scene definitions for different home states

### Lovelace Dashboards

- **lovelace/home.yaml**: Main home dashboard configuration
  - Accessible via the "Home" dashboard in the UI
  - Runs in YAML mode for version control

## Deploying Changes

### Method 1: Git Pull Script (Recommended)

The repository includes a built-in deployment script that can be triggered from Home Assistant:

1. Push your changes to the git repository:
   ```bash
   git add .
   git commit -m "Your commit message"
   git push
   ```

2. Edit `http-client.env.json` with your Home Assistant host and API token

3. Execute the HTTP request in `ha.http` to trigger the deployment:
   - The POST request will call the `git_pull_and_reload` script
   - Alternatively, trigger via UI: Developer Tools → Services → `script.git_pull_and_reload`

This script will:
- Pull the latest configuration from the git repository
- Log the git output
- Wait 2 seconds
- Reload all Home Assistant configuration

### Method 2: Manual Deployment

1. Push changes to the repository:
   ```bash
   git add .
   git commit -m "Your commit message"
   git push
   ```

2. SSH into your Home Assistant instance

3. Navigate to the config directory:
   ```bash
   cd /config
   ```

4. Pull the latest changes:
   ```bash
   git pull --rebase
   ```

5. Reload the configuration:
   - Via UI: Developer Tools → YAML → Check Configuration, then Reload All
   - Via CLI: `ha core reload` (if using Home Assistant OS/Supervised)
