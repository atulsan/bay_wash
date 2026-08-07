import json
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    import numpy as np


@dataclass(frozen=True)
class Zone:
    id: str
    label: str
    points: tuple[tuple[float, float], ...]

    def as_pixels(self, width: int, height: int) -> "np.ndarray":
        import numpy as np

        return np.array(
            [[int(x * width), int(y * height)] for x, y in self.points],
            dtype=np.int32,
        )

    def contains(self, x: float, y: float, width: int, height: int) -> bool:
        import cv2

        polygon = self.as_pixels(width, height)
        return cv2.pointPolygonTest(polygon, (x, y), False) >= 0


@dataclass(frozen=True)
class ZoneConfig:
    station_id: str
    camera_id: str
    zones: tuple[Zone, ...]


def load_zone_config(path: str) -> ZoneConfig:
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    return parse_zone_config(raw)


def parse_zone_config(raw: dict[str, Any]) -> ZoneConfig:
    station_id = str(raw.get("stationId", "adnoc_demo_station")).strip()
    camera_id = str(raw.get("cameraId", "adnoc_demo_video")).strip()
    if not station_id or not camera_id:
        raise ValueError("Station and camera IDs cannot be empty")
    if len(station_id) > 80 or len(camera_id) > 80:
        raise ValueError("Station and camera IDs cannot exceed 80 characters")
    zones = tuple(_read_zone(item) for item in raw.get("zones", []))
    if not zones:
        raise ValueError("Zone config must include at least one zone")
    zone_ids = [zone.id for zone in zones]
    if len(zone_ids) != len(set(zone_ids)):
        raise ValueError("Zone IDs must be unique")
    if len(zones) > 24:
        raise ValueError("Zone config cannot include more than 24 zones")
    return ZoneConfig(
        station_id=station_id,
        camera_id=camera_id,
        zones=zones,
    )


def zone_config_to_dict(config: ZoneConfig) -> dict[str, Any]:
    return {
        "stationId": config.station_id,
        "cameraId": config.camera_id,
        "zones": [
            {
                "id": zone.id,
                "label": zone.label,
                "points": [[x, y] for x, y in zone.points],
            }
            for zone in config.zones
        ],
    }


def save_zone_config(path: str, config: ZoneConfig) -> None:
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_suffix(f"{target.suffix}.tmp")
    temporary.write_text(
        json.dumps(zone_config_to_dict(config), indent=2) + "\n",
        encoding="utf-8",
    )
    temporary.replace(target)


def _read_zone(raw: dict[str, Any]) -> Zone:
    zone_id = str(raw.get("id", "")).strip()
    if not zone_id:
        raise ValueError("Each zone needs a non-empty ID")
    if len(zone_id) > 64:
        raise ValueError("Zone IDs cannot be longer than 64 characters")
    label = str(raw.get("label", zone_id)).strip() or zone_id
    if len(label) > 80:
        raise ValueError("Zone labels cannot be longer than 80 characters")
    points = raw.get("points")
    if not isinstance(points, list) or len(points) < 3:
        raise ValueError("Each zone needs at least three normalized points")
    if len(points) > 16:
        raise ValueError("Each zone can contain at most 16 points")
    normalized = []
    for point in points:
        if not isinstance(point, list) or len(point) != 2:
            raise ValueError("Zone points must be [x, y]")
        x = min(1.0, max(0.0, float(point[0])))
        y = min(1.0, max(0.0, float(point[1])))
        normalized.append((x, y))
    return Zone(
        id=zone_id,
        label=label,
        points=tuple(normalized),
    )
