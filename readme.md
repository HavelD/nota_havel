# Nota - Havel Daniel - Artificial Agents

## Project name: **nota_havel**

### Overview

**nota_havel** is a collection of AI behaviors and tools developed for coordinating multiple units in strategic scenarios for https://www.notaspace.com/. The project focuses on implementing practical solutions for common multi-agent challenges such as formation movement, terrain-aware navigation, and task coordination.

### Features

- **Formation Control**: Basic formation definitions and movement coordination between units
- **Terrain Analysis**: Height-based pathfinding and safe area detection using simple algorithms
- **Multi-Unit Behaviors**: Role assignment and coordinated actions for different unit types
- **Environmental Adaptation**: Wind direction integration and obstacle-aware navigation
- **Debug Visualization**: Widget-based tools for displaying unit paths, terrain data, and formation states

---
---
**Unit selection:** In all tasks you can just select all units (CTRL+A) - it should work fine
Click to open information about Task completion and provided solution and its files
<details>
<summary>Task: Sandsail2</summary>

### Behaviour: ***Sandsail2*** <img src="Behaviours/Sandsail.png" alt="Sandsail icon" style="height:1em; vertical-align:middle;" />

#### List of files:
- Delopment files
    - Behaviours
        - Sandsail.json (main behaviour)
    - Sensors
        - havelFormationDefinition.lua (line formation)
        - CommanderWindArrow.lua (widget data sender)
    - UnitCategories
        - commander.json
    - Widgets
        - dbg_arrowWidget.lua

#### Solution:
- Using Wind()
- Custom formation definition (line)
- Formation project commands
- Role definition + role action split for commander and others

#### Widget:
- Current direction of wind with strength (effecting the length and number of arrows)

![Sandsail screenshot with shown Widget and Formation](/readme_images/sandsail_solution.png)

![Sandsail showcase of wind strength adaptation](/readme_images/sandsail_wind_strength.png)


</details>

---

<details>
<summary>Task: CPT2</summary>

### Behaviour: ***CTP2*** <img src="Behaviours/CTP2.png" alt="CTP2 icon" style="height:1em; vertical-align:middle;" />

#### List of files:
- Development files
    - Behaviours
        - CTP2.json (main behaviour)
    - Sensors
        - AbsolutePointsToFormation.lua (Formation creation)
        - Peaks.lua (Find Hills)
        - widgetHelpHills.lua (widget data sender)
    - Widgets
        - dbg_hills.lua

#### Solution:
- Custom sensors
    - Peaks
        - Find local maxima and plateaus - with some or none minimal threshold
        - Calculation of middlepoint of every local zone (using Flood Fill algo)
        - Removal of peaks closest to specified list of points (e.g. enemy positions)
    - AbsolutePointsToFormation
        - Takes list of absolute points that the group should spread to and creates a formation that is defined as such each unit will reach its destination before the formation finishes its action. (Finds nearest unit from furthest path to set him as leader)
        - If set as parameter, when more units are given then there are positions in formation - sends multiple units to same location - failproofing
- Select all units and run behavior. Sensors calculate highest points and MissionInfo reveals enemy position. Remove hill with the enemy and conquer other three hills.

#### Widget:
- Height map of whole area with Colorcoding for: $\color{Gray}{\textsf{Low ground}}$, $\color{Purple}{\textsf{Above Threshold}}$, $\color{Orange}{\textsf{Local Maxima (or Plateau) above threshold}}$, $\color{Red}{\textsf{Centroid of each local Maxima}}$.

*(NOTE: This behaviour does not show its behaviour icon on my machine, don't know why.)*

![Sandsail screenshot with shown Widget and Formation](/readme_images/ctp2_solution.png)
![Sandsail screenshot with shown Widget and Formation](/readme_images/ctp_peaks_widget.png)

</details>

---

<details>
<summary>Task: TTDR</summary>

### Behaviour: ***TTDR-Multi*** <img src="Behaviours/TTDR-Multi.png" alt="TTDR-Multi icon" style="height:1em; vertical-align:middle;" />

#### List of files:
- Development files
    - Behaviours
        - TTDR-Multi.json (main behaviour)
        - SearchArea.json (Air Vision units line trough map)
        - SafelyTransport.json (Behaviour for one transporter unit and one (tower/unit))
    - Commands
        - FollowPath.lua
        - LoaderCommand.lua
    - Sensors
        - Peaks.lua (Using HeightMap to find safe spots)
        - FindSafePath.lua (Route from A to B using safe map)
        - havelFormationDefinition (For flying with Vision aircrafts)
        - ListClosestUnitsByCategory (Unit lists)
        - ReverseTable.lua (reversing path A->B to B->A)
        - widgetHelpPath.lua (widget data sender)
    - UnitCategories
        - AirVision.json (Observatory flying units)
        - towers.json (find WTC)
        - ttrd_groundUnits.json (mobile ground units)
    - Widgets
        - dbg_hills.lua (show Height Map - turned of for now but should work okay)
        - dbg_path.lua (Show Current path a unit will take)

#### Solution:
- Multiple actions simultaneously
    - Air Vision units fly in line trough whole map to gain knowledge about enemy positions (Afterall not used in decision-making)
    - Ground units (closest 11) go by foot to safe area
    - Closest 13 Towers are located and picked up by Air transporters (in group of five)
1. Evaluate Map
    1. find height of every point. Set threshold.
    1. Make "safe spot" grid (green) - where area heights are under threshold and are not reachable (and visible) by enemy guns on mountains
1. Each transporter get next tower in queue to be saved.
    1. Find closest point (A) of safespots to transporter 
    1. Find closest point (B) of safespots to Tower.
    1. Find shortest path from A to B using BFS in binary safespot grid.
    1. Plan route: Transporter Position, Path (A->B), Load Tower, Reverste Path (B->A), center of the safe area
1. In loop check if mission condition is met, end if yes,
- A Subtree behaviour is created - 

#### Widget:
- Path display of unit (red line from A to B using safe spot) + safespots - point on map considered as safe (just based on height - it is not updated on enemy encounter as it was not needed for base points.)
- Height map of whole area (currently turned of for more clearence - well used in development)

![Sandsail screenshot with shown Widget and Formation](/readme_images/ttdr_solution.png)

</details>
