# Task: Set up Godot 4.x project for Dungeon Seed

**Priority:** P2 – Medium Priority  
**Tier:** Core Infrastructure  
**Complexity:** 5 (Fibonacci points)  
**Phase:** Foundation  
**Dependencies:** None  

## Description

Dungeon Seed is an idle/progression RPG where players plant magical seeds that grow into procedurally generated dungeons over time. Adventurers are sent into these dungeons to harvest loot, creating a core idle loop of planting → growing → adventuring → harvesting. This task establishes the foundational Godot 4.x project structure with basic scene hierarchy, UI canvas, and node organization optimized for the idle/progression gameplay pattern.

### Executive Summary
Set up a new Godot 4.x project with standardized scene structure for Dungeon Seed, including main game scene, UI overlay canvas, and hierarchical node organization supporting the idle/progression game loop. The project will use Godot's scene system for modularity, with clear separation between game logic, UI, and world elements.

### Return on Investment
- **Cost of NOT doing this**: Manual project setup takes 4-6 hours of developer time, with inconsistent structure leading to 2-3 days of refactoring later
- **Cost of doing this**: 2-3 hours of structured setup following Godot best practices
- **Break-even**: ~1-2 weeks (when first feature additions begin)
- **Qualitative benefits**: Consistent codebase structure enables parallel development across multiple agents, reduces onboarding time for new contributors, and establishes patterns for the entire game's technical architecture

### Technical Architecture Overview
```
DungeonSeed (Main Scene)
├── World (Node2D)
│   ├── DungeonContainer (Node2D)
│   ├── AdventurerManager (Node2D)
│   └── SeedManager (Node2D)
├── UI (CanvasLayer)
│   ├── HUD (Control)
│   ├── Inventory (Control)
│   └── MenuSystem (Control)
├── GameState (Node)
│   ├── SaveLoadManager (Node)
│   ├── ProgressionManager (Node)
│   └── EconomyManager (Node)
└── AudioManager (Node)
```

### Integration Points
- **Godot Engine 4.x**: Core game engine providing scene system, node hierarchy, and GDScript runtime
- **File System**: Project directory structure following Godot conventions
- **Scene Instantiation**: Dynamic loading of dungeon scenes, adventurer scenes, and UI panels
- **Signal System**: Godot's signal/slot system for event-driven communication between game systems

### Constraints and Design Decisions
1. **Decision**: Use Godot 4.x scene system with .tscn files for all game objects  
   **Rationale**: Enables modular development and runtime scene instantiation  
   **Trade-off**: Slightly higher memory usage vs. pure code instantiation, but better maintainability

2. **Decision**: Separate UI from world rendering using CanvasLayer  
   **Rationale**: Ensures UI remains fixed while world camera moves, standard Godot pattern  
   **Trade-off**: Additional node hierarchy complexity vs. simpler single-canvas approach

3. **Decision**: Use Node2D for world elements, Control for UI  
   **Rationale**: Leverages Godot's built-in positioning and layout systems appropriately  
   **Trade-off**: Learning curve for Godot's dual hierarchy system vs. unified custom system

4. **Decision**: Implement game state as autoload singletons  
   **Rationale**: Provides global access to persistent game data without prop drilling  
   **Trade-off**: Potential for tight coupling vs. dependency injection pattern

5. **Decision**: Structure project with clear folder separation (scenes/, scripts/, assets/)  
   **Rationale**: Supports parallel development and asset management  
   **Trade-off**: Initial setup overhead vs. organic folder growth

### Business Value
This foundation enables the idle/progression loop by providing:
- **Planting Phase**: SeedManager node handles seed placement and growth timers
- **Growth Phase**: DungeonContainer manages procedural dungeon expansion
- **Adventuring Phase**: AdventurerManager coordinates adventurer AI and dungeon exploration
- **Harvesting Phase**: Integration points for loot collection and inventory management

The structured approach ensures all subsequent features (procedural generation, adventurer AI, loot systems) can be developed independently while maintaining clean interfaces.

## Use Cases

### Use Case 1: Project Initialization
**Persona**: Game Developer (Jordan), setting up the initial project structure  
**Context**: Jordan has just started development on Dungeon Seed and needs to create the foundational Godot project  
**Action**: Jordan runs Godot, creates new project, configures basic settings, and sets up initial scene hierarchy  
**Outcome**: Clean project structure with main scene, UI canvas, and organized node hierarchy ready for feature development. Jordan can immediately begin adding game systems without structural concerns.

### Use Case 2: Scene Organization for Idle Loop
**Persona**: Technical Artist (Sarah), implementing visual elements for the planting/growth phases  
**Context**: Sarah needs to add seed planting animations and dungeon growth visualizations  
**Action**: Sarah works within the established World/DungeonContainer node structure, adding child scenes for seeds and dungeon elements  
**Outcome**: Visual elements integrate seamlessly with the idle progression system, with clear separation between world rendering and UI overlays. Growth animations trigger at appropriate times in the idle loop.

### Use Case 3: UI Development for Game Management
**Persona**: UI Designer (Alex), creating interfaces for inventory and adventurer management  
**Context**: Alex needs to add UI panels for managing loot inventory and sending adventurers into dungeons  
**Action**: Alex extends the UI/CanvasLayer structure with new Control nodes for inventory grids and adventurer selection  
**Outcome**: UI elements remain properly positioned and scaled regardless of world camera movement, supporting the idle management gameplay where players monitor progress without constant interaction.

## Glossary

- **Scene**: A collection of nodes organized in a tree structure, saved as a .tscn file in Godot. Scenes can be instantiated as children of other scenes.
- **Node**: The base building block in Godot. All game objects inherit from Node, with specialized types like Node2D (2D positioning), Control (UI), and Node (logic).
- **Scene Tree**: The hierarchical structure of nodes in a running scene, managed by Godot's engine.
- **CanvasLayer**: A node that renders its children on a separate layer, typically used for UI elements that should appear above the game world.
- **Autoload**: A scene or script that loads automatically when the game starts, providing global access to game systems (similar to singletons).
- **Signal**: Godot's event system allowing nodes to emit signals that other nodes can connect to, enabling decoupled communication.
- **GDScript**: Godot's Python-like scripting language used for game logic, optimized for the Godot engine.
- **Idle Game Loop**: Gameplay pattern where progress occurs over time without constant player input, with periodic check-ins for management.
- **Procedural Generation**: Algorithmic creation of game content (dungeons, loot) based on seed values for replayability.
- **Progression System**: Game mechanics that provide long-term goals and rewards, keeping players engaged over extended periods.

## Out of Scope

- Game logic implementation (idle timers, dungeon generation algorithms, adventurer AI)
- Asset creation (sprites, sounds, 3D models)
- UI styling and theming (colors, fonts, layouts beyond basic structure)
- Multiplayer/networking features
- Platform-specific optimizations (mobile, web, console)
- Advanced Godot features (custom shaders, GDNative extensions)
- Save/load system implementation
- Procedural generation algorithms
- Loot economy mechanics
- Adventurer stat systems
- Audio system beyond basic manager structure
- Testing frameworks and CI/CD pipeline
- Performance optimization and profiling
- Localization/internationalization
- Accessibility features
- Analytics and telemetry
- Monetization systems (IAP, ads)

## Functional Requirements

**FR-001**: Create new Godot 4.x project with standard configuration  
**FR-002**: Set up project directory structure following Godot conventions  
**FR-003**: Configure project settings for 2D game development  
**FR-004**: Create main scene (DungeonSeed.tscn) as project entry point  
**FR-005**: Implement World node as container for game world elements  
**FR-006**: Implement DungeonContainer node for managing dungeon instances  
**FR-007**: Implement AdventurerManager node for adventurer coordination  
**FR-008**: Implement SeedManager node for seed planting and growth  
**FR-009**: Create UI CanvasLayer for overlay interface elements  
**FR-010**: Implement HUD control for displaying game status  
**FR-011**: Implement Inventory control for loot management  
**FR-012**: Implement MenuSystem control for game menus  
**FR-013**: Create GameState node for persistent game data management  
**FR-014**: Implement SaveLoadManager as autoload singleton  
**FR-015**: Implement ProgressionManager for game advancement tracking  
**FR-016**: Implement EconomyManager for resource and currency handling  
**FR-017**: Create AudioManager node for sound coordination  
**FR-018**: Set up signal connections between game systems  
**FR-019**: Configure scene loading and instantiation system  
**FR-020**: Implement basic node hierarchy with proper parenting  
**FR-021**: Add placeholder scripts for all manager nodes  
**FR-022**: Configure input actions for basic game controls  
**FR-023**: Set up viewport and camera system for world viewing  
**FR-024**: Implement basic scene transitions and loading  
**FR-025**: Add export templates for target platforms  
**FR-026**: Create default scene configuration files  
**FR-027**: Implement node grouping and organization  
**FR-028**: Set up resource loading system for scenes and assets  
**FR-029**: Configure Godot editor settings for team development  
**FR-030**: Add version control integration (.gitignore for Godot)  
**FR-031**: Create documentation for scene structure and node purposes  
**FR-032**: Implement error handling for missing scene dependencies  
**FR-033**: Set up debug logging system for development  
**FR-034**: Configure performance monitoring for frame rate and memory  
**FR-035**: Add scene validation checks on load

## Non-Functional Requirements

**NFR-001**: Project startup time < 2 seconds on target hardware  
**NFR-002**: Scene loading time < 500ms for main game scenes  
**NFR-003**: Memory usage < 100MB at idle for base scene structure  
**NFR-004**: Frame rate maintained at 60 FPS during scene transitions  
**NFR-005**: Node hierarchy depth limited to 5 levels maximum  
**NFR-006**: Scene file sizes < 1MB each for modular loading  
**NFR-007**: Autoload scripts initialize within 100ms of game start  
**NFR-008**: Signal connections established without circular dependencies  
**NFR-009**: Resource loading asynchronous to prevent UI blocking  
**NFR-010**: Error logging provides clear stack traces for debugging  
**NFR-011**: Scene validation runs in < 50ms per scene load  
**NFR-012**: Input responsiveness < 16ms (1 frame) for UI interactions  
**NFR-013**: Camera system supports smooth panning at 60 FPS  
**NFR-014**: UI scaling works across 1080p to 4K resolutions  
**NFR-015**: Project exports successfully to Windows, macOS, and Linux  
**NFR-016**: Godot editor remains responsive during scene editing  
**NFR-017**: Version control operations complete within 30 seconds  
**NFR-018**: Documentation accessible within project files  
**NFR-019**: Debug builds include performance profiling tools  
**NFR-020**: Scene hierarchy remains stable under node addition/removal  

## User Manual Documentation

### Godot Project Setup

1. **Install Godot 4.x**
   - Download Godot 4.x from official website
   - Install for your platform (Windows/macOS/Linux)
   - Verify installation by running Godot editor

2. **Create New Project**
   - Open Godot editor
   - Click "New Project"
   - Set project path to `c:\Users\wrstl\source\dev-agent-tool\dungeon-seed`
   - Select "2D" renderer
   - Choose GDScript as primary language
   - Click "Create"

3. **Configure Project Settings**
   - Go to Project → Project Settings
   - Under "Application/Config", set:
     - Name: "Dungeon Seed"
     - Description: "Idle RPG with magical dungeon seeds"
   - Under "Display/Window", set:
     - Size: 1920x1080
     - Resizable: true
   - Under "Rendering", ensure 2D renderer is selected

4. **Set Up Directory Structure**
   ```
   dungeon-seed/
   ├── scenes/
   │   ├── main/
   │   ├── world/
   │   ├── ui/
   │   └── managers/
   ├── scripts/
   │   ├── managers/
   │   ├── ui/
   │   └── utilities/
   ├── assets/
   │   ├── sprites/
   │   ├── audio/
   │   └── fonts/
   └── tests/
   ```

5. **Create Main Scene**
   - In Godot editor, create new scene
   - Add Node as root, name it "DungeonSeed"
   - Save as `scenes/main/DungeonSeed.tscn`

6. **Build World Hierarchy**
   - Add Node2D child to DungeonSeed, name "World"
   - Add Node2D children to World:
     - "DungeonContainer"
     - "AdventurerManager" 
     - "SeedManager"

7. **Set Up UI Layer**
   - Add CanvasLayer child to DungeonSeed, name "UI"
   - Add Control children to UI:
     - "HUD"
     - "Inventory"
     - "MenuSystem"

8. **Create Game State Managers**
   - Add Node child to DungeonSeed, name "GameState"
   - Add Node children to GameState:
     - "SaveLoadManager"
     - "ProgressionManager"
     - "EconomyManager"

9. **Add Audio Manager**
   - Add Node child to DungeonSeed, name "AudioManager"

10. **Configure Autoloads**
    - Go to Project → Project Settings → Autoload
    - Add `GameState.tscn` as autoload
    - Add `AudioManager.tscn` as autoload

11. **Set Main Scene**
    - Go to Project → Project Settings → Application/Run
    - Set Main Scene to `scenes/main/DungeonSeed.tscn`

12. **Test Project**
    - Press F5 or click Play button
    - Verify scene loads without errors
    - Check Godot console for any warnings

### Scene Organization Guidelines

- **World nodes** (Node2D): Position-dependent game elements
- **UI nodes** (Control): Interface elements on CanvasLayer
- **Manager nodes** (Node): Game logic and state management
- **Signals**: Use for communication between systems
- **Groups**: Organize related nodes for batch operations

### Troubleshooting Common Issues

- **Scene won't load**: Check file paths and node names
- **Nodes not visible**: Verify parenting and CanvasLayer settings
- **Performance issues**: Check node count and hierarchy depth
- **Signals not connecting**: Ensure signal names match exactly

## Assumptions

### Technical Assumptions
- Godot 4.x is installed and functional on development machines
- Target platforms (Windows, macOS, Linux) support Godot 4.x
- Development team has basic familiarity with Godot editor
- GDScript is acceptable as primary scripting language
- 2D rendering pipeline meets game requirements
- Standard Godot project structure is suitable for team size

### Operational Assumptions
- Project repository is accessible via Git
- Team members can install Godot independently
- Development occurs on machines meeting Godot's system requirements
- Project will be version controlled from initial commit
- Documentation will be maintained alongside code
- Regular backups of project files will be performed

### Integration Assumptions
- No existing Godot projects need migration
- Third-party addons will be evaluated separately
- Asset pipeline integrates with Godot's import system
- Build pipeline supports Godot's export templates
- Testing framework compatible with Godot's architecture

## Security Considerations

### Threat 1: Scene File Tampering

**Description:** Malicious actors modify .tscn scene files to inject harmful code or corrupt game state.

**Attack Vector:** Attacker gains access to project repository and modifies scene files with embedded malicious GDScript, or alters node hierarchies to cause runtime crashes.

**Impact:** HIGH - Could lead to game crashes, data corruption, or execution of arbitrary code on player machines.

**Mitigations:**
- Implement scene file validation on load using checksums
- Use Godot's built-in script encryption for exported builds
- Store critical game logic in compiled GDScript vs. plain text
- Implement runtime scene integrity checks

**Audit Requirements:**
- Log scene file hash mismatches during development
- Monitor for unauthorized scene file modifications
- Include scene validation in automated testing

### Threat 2: Save File Manipulation

**Description:** Players modify save files to gain unfair advantages or corrupt game progression.

**Attack Vector:** Users edit save files (JSON/text format) to alter currency, inventory, or progression values.

**Impact:** MEDIUM - Affects game balance and player experience, potential for cheating.

**Mitigations:**
- Implement save file encryption using Godot's Crypto class
- Add integrity checks with hash validation
- Store critical values server-side for online features
- Use binary save format instead of human-readable text

**Audit Requirements:**
- Validate save file integrity on load
- Log save file corruption attempts
- Monitor for unusual progression patterns

### Threat 3: Resource Loading Vulnerabilities

**Description:** Malicious resource files cause crashes or performance issues when loaded.

**Attack Vector:** Modified asset files (PNG, audio) with invalid headers or extremely large sizes cause memory exhaustion or parsing errors.

**Impact:** MEDIUM - Could cause game crashes or performance degradation.

**Mitigations:**
- Validate resource file sizes before loading
- Implement timeout limits for resource loading
- Use Godot's resource loader with error handling
- Sandbox resource loading in separate threads

**Audit Requirements:**
- Log resource loading failures
- Monitor memory usage during asset loading
- Test with corrupted asset files

### Threat 4: Input Validation Gaps

**Description:** Unvalidated input from configuration files or user inputs causes unexpected behavior.

**Attack Vector:** Modified project configuration files or save data with invalid values cause runtime errors or exploits.

**Impact:** LOW - Limited to game stability issues in development.

**Mitigations:**
- Validate all configuration values on load
- Implement bounds checking for numeric inputs
- Use type-safe parsing for configuration files
- Provide default values for missing configurations

**Audit Requirements:**
- Test with malformed configuration files
- Log configuration validation failures
- Include input validation in unit tests

## Best Practices

### Development Workflow
- Commit scene changes with descriptive messages including node modifications
- Use Godot's scene inheritance for UI component reuse
- Group related nodes using Godot's group system for batch operations
- Document signal connections in comments for maintainability

### Performance Optimization
- Limit scene hierarchy depth to prevent traversal overhead
- Use instancing for repeated scene elements (seeds, adventurers)
- Preload resources during loading screens to avoid runtime stalls
- Profile scene loading times and optimize slow-loading assets

### Code Organization
- Place scripts in matching directory structure (scripts/managers/ for manager scripts)
- Use Godot's class_name for script identification and autocompletion
- Implement error handling in all resource loading operations
- Use signals for decoupled communication between game systems

### Version Control
- Include .godot/ directory in .gitignore (editor-specific files)
- Commit .tscn files as text for diff visibility
- Use meaningful scene and node names for team collaboration
- Document breaking changes in scene hierarchies

### Testing and Validation
- Create test scenes for isolated component testing
- Validate scene loading in different configurations
- Test UI scaling across target resolutions
- Verify signal connections in automated tests

## Troubleshooting

### Issue 1: Scene Loading Failures

**Symptoms:** Godot editor shows "Failed to load scene" or runtime crashes on scene instantiation

**Causes:**
- Incorrect file paths in scene references
- Missing dependencies (scripts, resources)
- Corrupted .tscn files
- Circular scene dependencies

**Solutions:**
1. Check file paths in scene's "Open Scene" dialog
2. Verify all referenced scripts and resources exist
3. Re-save scene file from Godot editor
4. Remove circular dependencies by restructuring scene hierarchy

### Issue 2: Nodes Not Appearing in Scene

**Symptoms:** Nodes exist in scene tree but are invisible in viewport or game

**Causes:**
- Incorrect node types (Control vs Node2D)
- CanvasLayer ordering issues
- Visibility flags disabled
- Positioning outside viewport bounds

**Solutions:**
1. Verify node type matches intended use (UI = Control, World = Node2D)
2. Check CanvasLayer layer numbers for proper stacking
3. Enable "Visible" property in inspector
4. Adjust position and size to fit within viewport

### Issue 3: Signal Connection Errors

**Symptoms:** "Signal not found" or "Connection failed" errors in console

**Causes:**
- Signal name typos
- Incorrect node paths
- Missing script attachments
- Signal emission before connection establishment

**Solutions:**
1. Verify signal names match exactly (case-sensitive)
2. Use GetNode() with correct paths for dynamic connections
3. Ensure target nodes have required scripts attached
4. Connect signals in _ready() function after scene initialization

### Issue 4: Performance Degradation

**Symptoms:** Frame rate drops, high CPU/memory usage, slow scene loading

**Causes:**
- Excessive node count in scenes
- Unoptimized resource loading
- Deep scene hierarchy traversal
- Memory leaks from improper cleanup

**Solutions:**
1. Reduce node count by using instancing and grouping
2. Implement asynchronous resource loading
3. Flatten hierarchy where possible
4. Use Godot's profiler to identify bottlenecks

### Issue 5: Export Build Failures

**Symptoms:** Export process fails or exported game crashes immediately

**Causes:**
- Missing export templates
- Incorrect export settings
- Platform-specific compatibility issues
- Missing dependencies in export

**Solutions:**
1. Install correct export templates for target platforms
2. Verify export settings match project requirements
3. Test on target platform hardware
4. Include all required resources in export

## Acceptance Criteria

- [ ] AC-001: Godot 4.x project created with correct directory structure
- [ ] AC-002: Project settings configured for 2D development
- [ ] AC-003: Main scene (DungeonSeed.tscn) loads without errors
- [ ] AC-004: World node exists as Node2D with correct child structure
- [ ] AC-005: DungeonContainer node present under World
- [ ] AC-006: AdventurerManager node present under World
- [ ] AC-007: SeedManager node present under World
- [ ] AC-008: UI CanvasLayer exists with proper layering
- [ ] AC-009: HUD control node present under UI
- [ ] AC-010: Inventory control node present under UI
- [ ] AC-011: MenuSystem control node present under UI
- [ ] AC-012: GameState node exists with manager children
- [ ] AC-013: SaveLoadManager node configured as autoload
- [ ] AC-014: ProgressionManager node present under GameState
- [ ] AC-015: EconomyManager node present under GameState
- [ ] AC-016: AudioManager node configured as autoload
- [ ] AC-017: All manager nodes have placeholder GDScript files
- [ ] AC-018: Signal connections established between systems
- [ ] AC-019: Scene instantiation system functional
- [ ] AC-020: Node hierarchy depth limited to 5 levels
- [ ] AC-021: Input actions configured for basic controls
- [ ] AC-022: Camera system set up for world viewing
- [ ] AC-023: Basic scene transitions implemented
- [ ] AC-024: Export templates configured for target platforms
- [ ] AC-025: Project runs without console errors
- [ ] AC-026: Scene loading time < 500ms
- [ ] AC-027: Memory usage < 100MB at startup
- [ ] AC-028: Frame rate maintained at 60 FPS
- [ ] AC-029: UI scales properly across resolutions
- [ ] AC-030: Version control properly configured
- [ ] AC-031: Documentation included in project
- [ ] AC-032: Error handling implemented for missing resources
- [ ] AC-033: Debug logging system functional
- [ ] AC-034: Scene validation checks pass
- [ ] AC-035: All node names follow naming conventions
- [ ] AC-036: Scripts use class_name declarations
- [ ] AC-037: Resource loading is asynchronous
- [ ] AC-038: Autoloads initialize within 100ms
- [ ] AC-039: No circular dependencies in scene hierarchy
- [ ] AC-040: Godot editor remains responsive during editing

## Testing Requirements

```csharp
using Xunit;
using Godot;
using DungeonSeed.Scenes;
using DungeonSeed.Managers;

namespace DungeonSeed.Tests
{
    public class ProjectSetupTests
    {
        [Fact]
        public void Should_LoadMainSceneWithoutErrors()
        {
            // Arrange
            var scene = GD.Load<PackedScene>("res://scenes/main/DungeonSeed.tscn");
            
            // Act
            var instance = scene.Instantiate();
            
            // Assert
            Assert.NotNull(instance);
            Assert.IsType<DungeonSeed>(instance);
        }

        [Fact]
        public void Should_ContainWorldNodeHierarchy()
        {
            // Arrange
            var scene = GD.Load<PackedScene>("res://scenes/main/DungeonSeed.tscn");
            var instance = scene.Instantiate();
            
            // Act
            var world = instance.GetNode<Node2D>("World");
            var dungeonContainer = world.GetNode<Node2D>("DungeonContainer");
            var adventurerManager = world.GetNode<Node2D>("AdventurerManager");
            var seedManager = world.GetNode<Node2D>("SeedManager");
            
            // Assert
            Assert.NotNull(world);
            Assert.NotNull(dungeonContainer);
            Assert.NotNull(adventurerManager);
            Assert.NotNull(seedManager);
        }

        [Fact]
        public void Should_ContainUINodeHierarchy()
        {
            // Arrange
            var scene = GD.Load<PackedScene>("res://scenes/main/DungeonSeed.tscn");
            var instance = scene.Instantiate();
            
            // Act
            var ui = instance.GetNode<CanvasLayer>("UI");
            var hud = ui.GetNode<Control>("HUD");
            var inventory = ui.GetNode<Control>("Inventory");
            var menuSystem = ui.GetNode<Control>("MenuSystem");
            
            // Assert
            Assert.NotNull(ui);
            Assert.NotNull(hud);
            Assert.NotNull(inventory);
            Assert.NotNull(menuSystem);
        }

        [Fact]
        public void Should_ContainGameStateManagers()
        {
            // Arrange
            var scene = GD.Load<PackedScene>("res://scenes/main/DungeonSeed.tscn");
            var instance = scene.Instantiate();
            
            // Act
            var gameState = instance.GetNode<Node>("GameState");
            var saveLoadManager = gameState.GetNode<Node>("SaveLoadManager");
            var progressionManager = gameState.GetNode<Node>("ProgressionManager");
            var economyManager = gameState.GetNode<Node>("EconomyManager");
            
            // Assert
            Assert.NotNull(gameState);
            Assert.NotNull(saveLoadManager);
            Assert.NotNull(progressionManager);
            Assert.NotNull(economyManager);
        }

        [Fact]
        public void Should_ConfigureAutoloadsCorrectly()
        {
            // Arrange & Act
            var gameState = Engine.GetSingleton("GameState");
            var audioManager = Engine.GetSingleton("AudioManager");
            
            // Assert
            Assert.NotNull(gameState);
            Assert.NotNull(audioManager);
        }

        [Fact]
        public void Should_ValidateSceneHierarchyDepth()
        {
            // Arrange
            var scene = GD.Load<PackedScene>("res://scenes/main/DungeonSeed.tscn");
            var instance = scene.Instantiate();
            
            // Act
            int maxDepth = GetMaxHierarchyDepth(instance);
            
            // Assert
            Assert.True(maxDepth <= 5, $"Hierarchy depth {maxDepth} exceeds maximum of 5");
        }

        [Fact]
        public void Should_LoadSceneWithinPerformanceLimits()
        {
            // Arrange
            var stopwatch = new System.Diagnostics.Stopwatch();
            
            // Act
            stopwatch.Start();
            var scene = GD.Load<PackedScene>("res://scenes/main/DungeonSeed.tscn");
            var instance = scene.Instantiate();
            stopwatch.Stop();
            
            // Assert
            Assert.True(stopwatch.ElapsedMilliseconds < 500, 
                $"Scene loading took {stopwatch.ElapsedMilliseconds}ms, exceeds 500ms limit");
        }

        [Fact]
        public void Should_InitializeAutoloadsWithinTimeLimit()
        {
            // Arrange
            var stopwatch = new System.Diagnostics.Stopwatch();
            
            // Act
            stopwatch.Start();
            var gameState = Engine.GetSingleton("GameState");
            var audioManager = Engine.GetSingleton("AudioManager");
            stopwatch.Stop();
            
            // Assert
            Assert.True(stopwatch.ElapsedMilliseconds < 100,
                $"Autoload initialization took {stopwatch.ElapsedMilliseconds}ms, exceeds 100ms limit");
        }

        [Fact]
        public void Should_ValidateNodeNamingConventions()
        {
            // Arrange
            var scene = GD.Load<PackedScene>("res://scenes/main/DungeonSeed.tscn");
            var instance = scene.Instantiate();
            
            // Act
            var invalidNames = GetNodesWithInvalidNames(instance);
            
            // Assert
            Assert.Empty(invalidNames, $"Nodes with invalid names: {string.Join(", ", invalidNames)}");
        }

        [Fact]
        public void Should_ContainRequiredScripts()
        {
            // Arrange
            var scene = GD.Load<PackedScene>("res://scenes/main/DungeonSeed.tscn");
            var instance = scene.Instantiate();
            
            // Act
            var managers = new[] { "SaveLoadManager", "ProgressionManager", "EconomyManager", "AudioManager" };
            var missingScripts = new List<string>();
            
            foreach (var manager in managers)
            {
                var node = instance.GetNode<Node>($"GameState/{manager}") ?? 
                          instance.GetNode<Node>(manager);
                if (node?.GetScript() == null)
                {
                    missingScripts.Add(manager);
                }
            }
            
            // Assert
            Assert.Empty(missingScripts, $"Managers missing scripts: {string.Join(", ", missingScripts)}");
        }

        [Fact]
        public void Should_HandleMissingResourcesGracefully()
        {
            // Arrange
            var scene = GD.Load<PackedScene>("res://scenes/main/DungeonSeed.tscn");
            
            // Act & Assert - This should not throw exceptions
            var instance = scene.Instantiate();
            Assert.NotNull(instance);
        }

        [Fact]
        public void Should_ValidateCanvasLayerOrdering()
        {
            // Arrange
            var scene = GD.Load<PackedScene>("res://scenes/main/DungeonSeed.tscn");
            var instance = scene.Instantiate();
            
            // Act
            var ui = instance.GetNode<CanvasLayer>("UI");
            
            // Assert
            Assert.Equal(1, ui.Layer); // Default layer should be 1
        }

        [Fact]
        public void Should_ContainInputActions()
        {
            // Arrange & Act
            var inputMap = InputMap.GetActions();
            
            // Assert
            Assert.Contains("ui_accept", inputMap);
            Assert.Contains("ui_cancel", inputMap);
        }

        [Fact]
        public void Should_ExportSuccessfully()
        {
            // Arrange
            var exportPath = "res://export_test/";
            
            // Act
            var result = EditorPlugin.ExportProject(exportPath, "Windows Desktop");
            
            // Assert
            Assert.True(result, "Export failed");
            Assert.True(FileAccess.FileExists(exportPath + "DungeonSeed.exe"), "Executable not found");
        }

        private int GetMaxHierarchyDepth(Node node, int currentDepth = 0)
        {
            if (node.GetChildCount() == 0)
                return currentDepth;
            
            int maxDepth = currentDepth;
            for (int i = 0; i < node.GetChildCount(); i++)
            {
                int childDepth = GetMaxHierarchyDepth(node.GetChild(i), currentDepth + 1);
                maxDepth = Mathf.Max(maxDepth, childDepth);
            }
            return maxDepth;
        }

        private List<string> GetNodesWithInvalidNames(Node root)
        {
            var invalidNames = new List<string>();
            CheckNodeName(root, invalidNames);
            return invalidNames;
        }

        private void CheckNodeName(Node node, List<string> invalidNames)
        {
            if (!System.Text.RegularExpressions.Regex.IsMatch(node.Name, "^[A-Z][a-zA-Z0-9]*$"))
            {
                invalidNames.Add(node.Name);
            }
            
            for (int i = 0; i < node.GetChildCount(); i++)
            {
                CheckNodeName(node.GetChild(i), invalidNames);
            }
        }
    }
}
```

### Test Execution Matrix

| Test Category | Test Count | Execution Time | Pass Criteria |
|---------------|------------|----------------|----------------|
| Scene Loading | 5 | < 2 seconds | All scenes load without errors |
| Hierarchy Validation | 3 | < 1 second | Node structure meets requirements |
| Performance | 3 | < 5 seconds | Meets NFR timing requirements |
| Configuration | 2 | < 1 second | Autoloads and inputs configured |
| Export | 1 | < 30 seconds | Project exports successfully |
| **Total** | **14** | **< 40 seconds** | **100% pass rate** |

## User Verification Steps

### Scenario 1: Project Creation and Basic Loading
1. Open Godot 4.x editor
2. Create new project at `c:\Users\wrstl\source\dev-agent-tool\dungeon-seed`
3. Select 2D renderer and GDScript
4. Click "Create" and wait for project to initialize
5. **Expected**: Project opens with default scene, no errors in console

### Scenario 2: Main Scene Setup
1. Create new scene with Node as root
2. Name root node "DungeonSeed"
3. Add child nodes according to hierarchy diagram
4. Save scene as `scenes/main/DungeonSeed.tscn`
5. Set as main scene in project settings
6. Press F5 to run project
7. **Expected**: Scene loads, Godot console shows no errors, window displays with title "Dungeon Seed"

### Scenario 3: Node Hierarchy Validation
1. Open DungeonSeed.tscn in editor
2. Expand scene tree completely
3. Verify all required nodes exist:
   - World (Node2D) with DungeonContainer, AdventurerManager, SeedManager
   - UI (CanvasLayer) with HUD, Inventory, MenuSystem
   - GameState with managers
   - AudioManager
4. Check node types match specifications
5. **Expected**: All nodes present with correct types, hierarchy matches diagram

### Scenario 4: Autoload Configuration
1. Go to Project → Project Settings → Autoload
2. Add GameState.tscn and AudioManager.tscn
3. Enable autoload for both
4. Restart project (F5)
5. **Expected**: Project starts without autoload errors, singletons accessible globally

### Scenario 5: Performance Validation
1. Run project and monitor Godot debugger
2. Check frame rate in debugger (should be ~60 FPS)
3. Monitor memory usage (should be < 100MB)
4. Time scene loading (should be < 500ms)
5. **Expected**: All metrics within NFR limits, no performance warnings

### Scenario 6: Export Testing
1. Go to Project → Export
2. Add Windows Desktop preset
3. Click "Export Project"
4. Choose export directory
5. Run exported executable
6. **Expected**: Game launches from export, no missing file errors

### Scenario 7: Directory Structure Check
1. Open project folder in file explorer
2. Verify directory structure exists:
   - scenes/main/, scenes/world/, scenes/ui/, scenes/managers/
   - scripts/managers/, scripts/ui/, scripts/utilities/
   - assets/sprites/, assets/audio/, assets/fonts/
3. Check for .gitignore file
4. **Expected**: All directories present, version control configured

### Scenario 8: Script Attachment Verification
1. Open each manager node in inspector
2. Check "Script" property for each:
   - SaveLoadManager.gd
   - ProgressionManager.gd
   - EconomyManager.gd
   - AudioManager.gd
3. Open each script file
4. **Expected**: Scripts attached, files contain basic class structure with class_name

## Implementation Prompt

```gdscript
# DungeonSeed.gd - Main scene script
extends Node
class_name DungeonSeed

@onready var world: Node2D = $World
@onready var ui: CanvasLayer = $UI
@onready var game_state: Node = $GameState
@onready var audio_manager: Node = $AudioManager

func _ready() -> void:
    _initialize_game()
    _connect_signals()
    _start_idle_loop()

func _initialize_game() -> void:
    # Initialize core game systems
    game_state.initialize()
    audio_manager.initialize()
    world.initialize_world()

func _connect_signals() -> void:
    # Connect game systems
    game_state.connect("game_state_changed", Callable(self, "_on_game_state_changed"))
    world.connect("dungeon_grew", Callable(self, "_on_dungeon_grew"))
    ui.connect("ui_action", Callable(self, "_on_ui_action"))

func _start_idle_loop() -> void:
    # Begin the idle progression loop
    world.start_dungeon_growth()
    game_state.start_progression_tracking()

func _on_game_state_changed(new_state: Dictionary) -> void:
    ui.update_display(new_state)

func _on_dungeon_grew(dungeon_data: Dictionary) -> void:
    ui.show_growth_notification(dungeon_data)

func _on_ui_action(action: String, params: Dictionary) -> void:
    match action:
        "plant_seed":
            world.plant_seed(params.position)
        "send_adventurer":
            world.send_adventurer(params.dungeon_id, params.adventurer_id)
        "collect_loot":
            world.collect_loot(params.dungeon_id)

# World.gd - World container script
extends Node2D
class_name World

@onready var dungeon_container: Node2D = $DungeonContainer
@onready var adventurer_manager: Node2D = $AdventurerManager
@onready var seed_manager: Node2D = $SeedManager

signal dungeon_grew(dungeon_data: Dictionary)

func _ready() -> void:
    initialize_world()

func initialize_world() -> void:
    dungeon_container.initialize()
    adventurer_manager.initialize()
    seed_manager.initialize()

func start_dungeon_growth() -> void:
    seed_manager.start_growth_timers()

func plant_seed(position: Vector2) -> void:
    seed_manager.plant_seed_at(position)

func send_adventurer(dungeon_id: String, adventurer_id: String) -> void:
    adventurer_manager.send_to_dungeon(adventurer_id, dungeon_id)

func collect_loot(dungeon_id: String) -> Dictionary:
    return dungeon_container.collect_loot(dungeon_id)

# DungeonContainer.gd - Manages dungeon instances
extends Node2D
class_name DungeonContainer

var active_dungeons: Dictionary = {}

func _ready() -> void:
    initialize()

func initialize() -> void:
    # Load dungeon scene template
    pass

func create_dungeon(seed_data: Dictionary) -> String:
    var dungeon_id = _generate_dungeon_id()
    var dungeon_scene = preload("res://scenes/world/Dungeon.tscn").instantiate()
    dungeon_scene.initialize(seed_data)
    add_child(dungeon_scene)
    active_dungeons[dungeon_id] = dungeon_scene
    return dungeon_id

func collect_loot(dungeon_id: String) -> Dictionary:
    if active_dungeons.has(dungeon_id):
        return active_dungeons[dungeon_id].collect_loot()
    return {}

func _generate_dungeon_id() -> String:
    return "dungeon_" + str(randi())

# AdventurerManager.gd - Coordinates adventurers
extends Node2D
class_name AdventurerManager

var available_adventurers: Array = []

func _ready() -> void:
    initialize()

func initialize() -> void:
    # Load adventurer templates
    pass

func hire_adventurer(adventurer_type: String) -> String:
    var adventurer_id = _generate_adventurer_id()
    var adventurer_scene = preload("res://scenes/world/Adventurer.tscn").instantiate()
    adventurer_scene.initialize(adventurer_type)
    add_child(adventurer_scene)
    available_adventurers.append(adventurer_id)
    return adventurer_id

func send_to_dungeon(adventurer_id: String, dungeon_id: String) -> void:
    # Send adventurer to dungeon
    pass

func _generate_adventurer_id() -> String:
    return "adventurer_" + str(randi())

# SeedManager.gd - Handles seed planting and growth
extends Node2D
class_name SeedManager

var planted_seeds: Array = []

func _ready() -> void:
    initialize()

func initialize() -> void:
    # Load seed templates
    pass

func plant_seed_at(position: Vector2) -> void:
    var seed_scene = preload("res://scenes/world/Seed.tscn").instantiate()
    seed_scene.position = position
    add_child(seed_scene)
    planted_seeds.append(seed_scene)

func start_growth_timers() -> void:
    for seed in planted_seeds:
        seed.start_growth_timer()

# UI.gd - UI container script
extends CanvasLayer
class_name UI

@onready var hud: Control = $HUD
@onready var inventory: Control = $Inventory
@onready var menu_system: Control = $MenuSystem

signal ui_action(action: String, params: Dictionary)

func _ready() -> void:
    initialize_ui()

func initialize_ui() -> void:
    hud.initialize()
    inventory.initialize()
    menu_system.initialize()

func update_display(game_state: Dictionary) -> void:
    hud.update_stats(game_state)
    inventory.update_items(game_state.inventory)

func show_growth_notification(dungeon_data: Dictionary) -> void:
    hud.show_notification("Dungeon grew!", dungeon_data)

# GameState.gd - Game state management
extends Node
class_name GameState

signal game_state_changed(new_state: Dictionary)

var current_state: Dictionary = {
    "currency": 0,
    "level": 1,
    "inventory": [],
    "adventurers": [],
    "dungeons": []
}

func _ready() -> void:
    initialize()

func initialize() -> void:
    load_game_state()

func save_game_state() -> void:
    var save_data = JSON.stringify(current_state)
    var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
    file.store_string(save_data)
    file.close()

func load_game_state() -> void:
    if FileAccess.file_exists("user://savegame.json"):
        var file = FileAccess.open("user://savegame.json", FileAccess.READ)
        var json = JSON.new()
        var error = json.parse(file.get_as_text())
        if error == OK:
            current_state = json.data
        file.close()

func update_state(key: String, value) -> void:
    current_state[key] = value
    emit_signal("game_state_changed", current_state)
    save_game_state()

func start_progression_tracking() -> void:
    # Start idle progression timers
    pass

# AudioManager.gd - Audio coordination
extends Node
class_name AudioManager

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

func _ready() -> void:
    initialize()

func initialize() -> void:
    # Load audio resources
    pass

func play_music(track: String) -> void:
    var music_stream = load("res://assets/audio/music/" + track + ".ogg")
    music_player.stream = music_stream
    music_player.play()

func play_sfx(sound: String) -> void:
    var sfx_stream = load("res://assets/audio/sfx/" + sound + ".wav")
    sfx_player.stream = sfx_stream
    sfx_player.play()

# SaveLoadManager.gd - Save/load system
extends Node
class_name SaveLoadManager

func _ready() -> void:
    initialize()

func initialize() -> void:
    # Set up save directory
    pass

func save_game(data: Dictionary) -> void:
    var encrypted_data = _encrypt_data(JSON.stringify(data))
    var file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
    file.store_string(encrypted_data)
    file.close()

func load_game() -> Dictionary:
    if FileAccess.file_exists("user://savegame.dat"):
        var file = FileAccess.open("user://savegame.dat", FileAccess.READ)
        var encrypted_data = file.get_as_text()
        var json_data = _decrypt_data(encrypted_data)
        var json = JSON.new()
        json.parse(json_data)
        return json.data
    return {}

func _encrypt_data(data: String) -> String:
    # Basic encryption placeholder
    return data

func _decrypt_data(data: String) -> String:
    # Basic decryption placeholder
    return data

# ProgressionManager.gd - Game progression
extends Node
class_name ProgressionManager

var progression_data: Dictionary = {}

func _ready() -> void:
    initialize()

func initialize() -> void:
    # Load progression templates
    pass

func check_level_up(current_xp: int) -> bool:
    # Check for level advancement
    return false

func unlock_feature(feature: String) -> void:
    progression_data[feature] = true

# EconomyManager.gd - Resource management
extends Node
class_name EconomyManager

var currency: int = 0
var resources: Dictionary = {}

func _ready() -> void:
    initialize()

func initialize() -> void:
    # Set up initial economy
    currency = 100
    resources = {
        "seeds": 5,
        "potions": 0
    }

func add_currency(amount: int) -> void:
    currency += amount

func spend_currency(amount: int) -> bool:
    if currency >= amount:
        currency -= amount
        return true
    return false

func add_resource(resource: String, amount: int) -> void:
    if resources.has(resource):
        resources[resource] += amount
    else:
        resources[resource] = amount

# HUD.gd - Heads-up display
extends Control
class_name HUD

@onready var currency_label: Label = $CurrencyLabel
@onready var level_label: Label = $LevelLabel

func _ready() -> void:
    initialize()

func initialize() -> void:
    update_display()

func update_stats(game_state: Dictionary) -> void:
    currency_label.text = "Gold: " + str(game_state.currency)
    level_label.text = "Level: " + str(game_state.level)

func show_notification(message: String, data: Dictionary) -> void:
    # Show temporary notification
    pass

# Inventory.gd - Inventory management UI
extends Control
class_name Inventory

@onready var item_container: GridContainer = $ItemContainer

func _ready() -> void:
    initialize()

func initialize() -> void:
    # Set up inventory grid
    pass

func update_items(items: Array) -> void:
    # Update inventory display
    pass

# MenuSystem.gd - Game menus
extends Control
class_name MenuSystem

func _ready() -> void:
    initialize()

func initialize() -> void:
    # Set up menu navigation
    pass

func show_menu(menu_name: String) -> void:
    # Display specific menu
    pass
```

### File Structure

```
dungeon-seed/
├── scenes/
│   ├── main/
│   │   ├── DungeonSeed.tscn
│   │   └── DungeonSeed.gd
│   ├── world/
│   │   ├── World.tscn
│   │   ├── DungeonContainer.tscn
│   │   ├── AdventurerManager.tscn
│   │   ├── SeedManager.tscn
│   │   ├── Dungeon.tscn
│   │   ├── Adventurer.tscn
│   │   └── Seed.tscn
│   ├── ui/
│   │   ├── UI.tscn
│   │   ├── HUD.tscn
│   │   ├── Inventory.tscn
│   │   └── MenuSystem.tscn
│   └── managers/
│       ├── GameState.tscn
│       ├── SaveLoadManager.tscn
│       ├── ProgressionManager.tscn
│       ├── EconomyManager.tscn
│       └── AudioManager.tscn
├── scripts/
│   ├── managers/
│   │   ├── SaveLoadManager.gd
│   │   ├── ProgressionManager.gd
│   │   ├── EconomyManager.gd
│   │   └── AudioManager.gd
│   ├── ui/
│   │   ├── HUD.gd
│   │   ├── Inventory.gd
│   │   └── MenuSystem.gd
│   └── utilities/
│       └── GameUtils.gd
├── assets/
│   ├── sprites/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   └── fonts/
├── tests/
│   └── ProjectSetupTests.cs
├── project.godot
├── .gitignore
└── README.md
```</content>
<parameter name="filePath">c:\Users\wrstl\source\dev-agent-tool\neil-docs\tickets\task-001-set-up-godot-project.md