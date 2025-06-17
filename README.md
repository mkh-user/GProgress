# GProgress
## Player Progress Management in Godot

`GProgress` is a powerful and practical plugin for managing player progress in games built with the Godot game engine. This plugin allows you to efficiently save, load, and manage player progress data.

> [!NOTE]
> See [main page](https://mkh-user.github.io/GProgress) and [demos page](https://mkh-user.github.io/GProgress-Demos) for more information and guides.
>
> Join [Discord server](https://discord.gg/7X8wgM5N) now!

We are thrilled to introduce an exciting new plugin for Godot that truly revolutionizes the way players save and load their game states! Say farewell to the cumbersome and often frustrating processes that have long been a part of gaming; this innovative tool effectively streamlines the entire experience, transforming it into something not only simpler for the user but also remarkably efficient. With this groundbreaking plugin, you now have the ability to effortlessly capture and store vital information about each player at multiple moments in their adventure, allowing for an unprecedented level of user engagement. Just imagine the thrill and convenience of being able to pick up right where you left off, regardless of when you choose to dive back into the action! This plugin doesn't just stop there; it also opens the door to a variety of even more exciting capabilities and functionalities, ensuring that every player's gaming experience is not only seamless but also highly engaging and enjoyable. This means that players can spend less time worrying about how to save their progress and more time immersed in the captivating narratives and gameplay that your game has to offer. Get ready to enhance your game design with this essential tool that keeps players coming back for more!

## Key Features

- **Save and Load Player Progress**: This feature allows you to save and load player progress at any stage of the game. Using the `save_progress` and `load_progress` functions, you can easily manage progress data.
- **Parallel Slots**: Each slot is dedicated to a player, and each player should have only one slot. However, each player can have multiple saves within their slot. This feature is especially useful for games that require multiple save profiles within a single account.
- **Backup**: This feature allows you to back up player progress. With regular backups, you can protect player data and easily restore it if needed.
- **Compression**: This feature helps reduce the size of saved data. By enabling compression, saved data is stored in a compressed format, improving efficiency and reducing space requirements.
- **Encryption**: This feature ensures the security of player data. Using advanced encryption algorithms, saved data is stored in an encrypted format, preventing unauthorized access.
- **Auto-Save**: This feature allows you to automatically save player progress at specified intervals or specific events. Using auto-save, you can prevent loss of player data.

## How to Use

1. **Installing the Plugin**:
   - Download the plugin and place it in your project's `addons` folder.
   - Enable the plugin from **Project Settings** > **Plugins**.
   - After installing and enabling the plugin, you can access the plugin documentation within the Godot environment by pressing the `F1` key and searching for `GProgress`.

2. **Configuring and Using**:
   - The plugin is automatically activated, and there is no need to add a node.
   - Use the new `GProgress` tab that is added after `General` tab in **Project Settings** to configure the plugin.

3. **Using Plugin Functions**:
   - You can access the automatically instantiated version of the plugin with the `GPro` keyword and use its functions.
   - After installing the plugin on each project, you need to run the `GPro.initialize()` code once. (See internal documentation for example code)
   - For the best usage practices, refer to the demo section.

## Demo

### See [GProgress Demos](https://mkh-user.github.io/GProgress-Demos) for example usage & guides 

## Plugin Settings

This tab includes three separate tabs:

#### User Settings

- **User Slots**: Total number of available slots (default: 3)
  - Determines the total number of slots available for users.
- **User Parameters**: Includes `id`, `index`, `name`, `last_open`, `last_save`
  - Various parameters stored for each user.
- **Limit Per User**: Limit for each user (default: 50)
  - The maximum number of saves each user can have. If the number of saves exceeds the limit, the oldest save will be automatically deleted.

#### Progress Settings

- **Progress Parameters**: Includes `id`, `index`, `name`, `details`, `date`, `time`, `tags`
  - Parameters stored for each progress.
- **Preview Parameters**: Includes `id`, `index`, `name`, `date`, `time`, `tags`
  - Parameters used for previewing each progress.

#### Save & Backup Settings

- **Auto-Save Interval**: Time interval between auto-saves (default: 1 month)
  - Sets the interval for automatic saves.
- **Save Path**: Path for saving files (default: `user://GProgress/Saves`)
  - Path where saved files are stored.
- **Backup Interval**: Time interval between backups (default: 3 months)
  - Sets the interval for regular backups.
- **Backup Path**: Path for storing backups (default: `res://GProgress/Backups`)
  - Path where backup files are stored.
- **Compression**: Enable or disable compression (default: enabled)
  - Reduces the size of saved data for improved efficiency.
- **Encryption**: Enable or disable encryption (default: enabled)
  - Enhances data security using encryption.
- **Encryption Key**: Encryption key (default: `q3@g.<9gF]JK-%qqAscBcf,>?k*I0pse`)
  - Key used for encrypting data.

### Managing Configuration Files

- **Open file**: Open the plugin's configuration file.
  - This option allows you to open the file containing the plugin's settings and make necessary changes.
- **Reload from file**: Reload settings from the file.
  - This option allows you to import settings from the file and apply changes made in the file to the plugin.
- **Reset to defaults**: Reset to default settings.
  - This option allows you to reset all plugin settings to their default state.

## Parameters

- **User Parameters**:
  - `id`: Unique identifier for the user.
  - `index`: User index.
  - `name`: User name.
  - `last_open`: The last time the user was opened.
  - `last_save`: The last time the user was saved.

- **Progress Parameters**:
  - `id`: Unique identifier for the progress.
  - `index`: Progress index.
  - `name`: Progress name.
  - `details`: Details about the progress.
  - `date`: Date of the progress.
  - `time`: Time of the progress.
  - `tags`: Tags associated with the progress.

- **Preview Parameters**:
  - `id`: Unique identifier for the preview.
  - `index`: Preview index.
  - `name`: Preview name.
  - `date`: Date of the preview.
  - `time`: Time of the preview.
  - `tags`: Tags associated with the preview.

## Contribution

If you would like to contribute to the improvement of this plugin, you can easily visit the GitHub repository and submit your suggestions, bugs, and updates.
