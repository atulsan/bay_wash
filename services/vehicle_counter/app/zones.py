import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import cv2
import numpy as np


@dataclass(frozen=True)
class Zone:
    id: str
    label: str
    points: tuple[tuple[float, float], ...]

    def as_pixels(self, width: int, height: int) -> np.ndarray:
        return np.array(
            [[int(x * width), int(y * height)] for x, y in self.points],
            dtype=np.int32,
        )

    def contains(self, x: float, y: float, width: int, height: int) -> bool:
        polygon = self.as_pixels(width, height)
        return cv2.pointPolygonTest(polygon, (x, y), False) >= 0


@dataclass(frozen=True)
class ZoneConfig:
    station_id: str
    camera_id: str
    zones: tuple[Zone, ...]


def load_zone_config(path: str) -> ZoneConfig:
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    zones = tuple(_read_zone(item) for item in raw.get("zones", []))
    if not zones:
        raise ValueError("Zone config must include at least one zone")
    return ZoneConfig(
        station_id=str(raw.get("stationId", "adnoc_demo_station")),
        camera_id=str(raw.get("cameraId", "adnoc_demo_video")),
        zones=zones,
    )


def _read_zone(raw: dict[str, Any]) -> Zone:
    points = raw.get("points")
    if not isinstance(points, list) or len(points) < 3:
        raise ValueError("Each zone needs at least three normalized points")
    normalized = []
    for point in points:
        if not isinstance(point, list) or len(point) != 2:
            raise ValueError("Zone points must be [x, y]")
        x = min(1.0, max(0.0, float(point[0])))
        y = min(1.0, max(0.0, float(point[1])))
        normalized.append((x, y))
    return Zone(
        id=str(raw["id"]),
        label=str(raw.get("label", raw["id"])),
        points=tuple(normalized),
    )
