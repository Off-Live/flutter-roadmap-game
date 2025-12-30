# Flutter 2D Road Map Spec (1536×1024, PNG background)

This spec defines **data formats + rendering/animation architecture** for a “stage node + winding road + rainbow-completed road + character-on-cloud moving along the road” world map in Flutter.

---

## 0) Goals & constraints

- **Map canvas size (design coordinate space):** `1536 × 1024` (landscape; 3:2 feel).
- **Background:** pre-rendered **PNG** at exactly `1536×1024` (or authored at higher resolution but displayed with consistent scaling).
- **Nodes:** multiple stage nodes; only **next stage** is tappable.
- **Completed nodes:** node art changes (e.g., “filled”).
- **Road:** winding/squiggly like the reference; **completed segments** become **rainbow**; remaining segments stay “dirt”.
- **Character:** rides a cloud; moves **along the road** from current node to next node; no walk cycle required.

---

## 1) Coordinate system (important)

All positions/paths are authored in the **map design coordinate space**:

- Origin: **top-left** = `(0, 0)`
- X: rightwards
- Y: downwards
- Canvas: `(0..1536, 0..1024)`

At runtime, the map is displayed inside an `InteractiveViewer` or scaled container.  
**Never author node positions in screen pixels**—always in this design space.

### Scaling rule

Let `designSize = Size(1536, 1024)` and `viewportSize = constraints.biggest`.

Recommended: **contain** scaling (keep aspect ratio; allow letterboxing):

- `scale = min(viewportW / 1536, viewportH / 1024)`
- `offset = (viewportSize - designSize * scale) / 2`  (center the map)

All rendering (background, road painter, nodes, character) should be placed in the **same transformed space**.

---

## 2) Data model (authorable JSON)

### File: `assets/map/safari_world_map.json`

```jsonc
{
  "version": 1,
  "designSize": { "w": 1536, "h": 1024 },

  "background": {
    "asset": "assets/map/safari_world_bg.png"
  },

  "nodes": [
    {
      "id": 1,
      "pos": { "x": 220, "y": 420 },
      "tapRadius": 58,
      "assets": {
        "locked": "assets/nodes/node_locked.png",
        "next": "assets/nodes/node_next.png",
        "done": "assets/nodes/node_done.png"
      }
    }
  ],

  // One of the two road-definition modes below:
  // (A) "spline" or (B) "cubicSegments"
  "road": {
    "mode": "spline",
    "segments": [
      {
        "fromId": 1,
        "toId": 2,
        "points": [
          { "x": 220, "y": 420 },
          { "x": 340, "y": 360 },
          { "x": 520, "y": 410 },
          { "x": 640, "y": 520 }
        ],
        "style": {
          "base": "dirt",
          "completed": "rainbow"
        }
      }
    ]
  },

  "character": {
    "asset": "assets/character/koala_cloud.png",
    "size": { "w": 140, "h": 140 },
    "anchor": { "x": 0.5, "y": 0.75 } // relative pivot (0..1). 0.5 center, 0.75 lower-ish
  },

  "paint": {
    "dirt": {
      "strokeWidth": 30,
      "color": "#CDA46B",
      "shadow": { "blur": 6, "dx": 0, "dy": 3, "color": "#33000000" },
      "dash": { "enabled": false, "pattern": [12, 10] },
      "footprints": { "enabled": true, "spacing": 80, "asset": "assets/map/footprint.png" }
    },
    "rainbow": {
      "strokeWidth": 34,
      "colors": ["#FF4D4D","#FFA94D","#FFE44D","#55D66B","#4DA3FF","#7B5BFF","#C04DFF"],
      "glow": { "enabled": true, "blur": 10, "color": "#66FFFFFF" }
    }
  }
}
```

---

## 3) Road definition (how to pre-define “winding paths”)

You have two good options. Both are authorable and deterministic.

### Option A — `mode: "spline"` (recommended)
Define each segment by a **polyline of points** (4–10 points). At runtime, convert points to a smooth spline path:

- Use **Catmull-Rom spline** (centripetal recommended) or
- Use a smoothing algorithm to generate cubic Béziers from points.

Pros:
- Easy to author manually (even by placing points visually).
- Path is smooth and controllable.
- Great for “wiggly road” look.

### Option B — `mode: "cubicSegments"`
Define each segment as one or more explicit cubic Béziers:

```jsonc
{
  "mode": "cubicSegments",
  "segments": [
    {
      "fromId": 1,
      "toId": 2,
      "beziers": [
        {
          "p0": {"x":220,"y":420},
          "c1": {"x":300,"y":320},
          "c2": {"x":520,"y":340},
          "p3": {"x":640,"y":520}
        }
      ]
    }
  ]
}
```

Pros:
- Total artistic control.
- Matches vector authoring workflows (Illustrator/Figma export).

Recommendation:
- Start with **Option A**. You can always bake it to cubic later if needed.

---

## 4) Progress rules (state)

Runtime state variables:

- `currentStageId` (the **next** stage to play)
- completed = nodes with `id < currentStageId`  (or explicit list if branching later)
- locked = nodes with `id > currentStageId`

Rules:
- Only node where `id == currentStageId` is tappable.
- When tapped:
  1. start character animation from `currentStageId - 1` to `currentStageId` (or from start node if first)
  2. on arrival → mark previous as done and increment `currentStageId`.

---

## 5) Rendering architecture (Flutter widgets)

### Widget hierarchy

- `InteractiveViewer`
  - `Stack`
    1. `Image.asset(background)`
    2. `CustomPaint(painter: RoadPainter(...))`
    3. `NodesLayer` (Positioned + GestureDetector)
    4. `CharacterLayer` (Positioned; animated along path)

All layers share the same transform (`scale` + `offset`) so they align.

### RoadPainter responsibilities

Inputs:
- `List<PathSegment>` (already converted to `Path` per segment)
- `currentStageId`
- theme paints from JSON (`dirt`, `rainbow`)

Draw logic:
- for each segment:
  - if segment.toId < currentStageId → draw rainbow
  - else → draw dirt

Optional “progressively filling” the current segment:
- while character animates, draw segment partially based on `t ∈ [0,1]` (advanced).

---

## 6) Character movement along the road (PathMetrics)

On transition `fromId -> toId`:

1) Get the segment Path for `(fromId, toId)`.
2) Compute `PathMetric metric = path.computeMetrics().first;`
3) Animate `t` from 0 to 1 with `AnimationController` (e.g., 800–1400ms).
4) Position is:

- `offset = metric.getTangentForOffset(metric.length * t)!.position`
- Place character with anchor pivot:
  - `pos = offset - Offset(characterW*anchorX, characterH*anchorY)`

No rotation required. If desired:
- use `tangent.angle` for subtle bob/tilt only.

---

## 7) Authoring workflow (how you’ll actually make the paths)

### Step 1 — Decide node positions
- Place nodes on the 1536×1024 canvas in Figma (or any editor).
- Export each node center position as `(x,y)`.

### Step 2 — Define road segment points
For each segment between consecutive nodes:
- add 4–8 “control points” that trace the road centerline.
- Ensure first point equals `fromNode.pos` and last equals `toNode.pos` (or very close).

### Step 3 — Validate
Create a debug overlay mode:
- show polyline points as small circles with indices
- show generated spline as a thin line
- snap/adjust until it matches your art direction

---

## 8) Acceptance checklist

- [ ] Background PNG aligns with node positions at all zoom levels
- [ ] Only next node is tappable
- [ ] Completed nodes show “done” art
- [ ] Completed road segments show rainbow stroke
- [ ] Character moves along the correct segment path
- [ ] Map is navigable with pan/zoom (InteractiveViewer)
- [ ] No jitter on animation (use RepaintBoundary + minimal setState)

---

## 9) Minimal file structure (suggested)

```
lib/
  map/
    map_screen.dart
    map_controller.dart           // ChangeNotifier: currentStageId, isMoving
    map_spec.dart                 // JSON parsing models
    road_path_builder.dart        // points->Path (CatmullRom or smoothing)
    road_painter.dart
    nodes_layer.dart
    character_layer.dart
assets/
  map/
    safari_world_bg.png
    safari_world_map.json
  nodes/
    node_locked.png
    node_next.png
    node_done.png
  character/
    koala_cloud.png
  map/
    footprint.png
```

---

## 10) Notes (future-proof)

- If you later want branching paths:
  - change progress from `currentStageId` to `completedNodeIds: [..]`
  - road segment completion becomes `completedSegments` derived from that set
- If you want per-world themes:
  - keep `paint` section per JSON map, not global constants

