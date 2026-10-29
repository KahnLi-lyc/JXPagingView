#!/usr/bin/env python3
"""Keep the documented route/test inventory tied to the maintained Demo sources."""
import json
from pathlib import Path
import re
root = Path(__file__).resolve().parent.parent
if (root / "Demo/Resources/route-coverage.json").is_file():
    index = json.loads((root / "Demo/Resources/route-coverage.json").read_text())
    routes = set(re.findall(r'\.init\(id: "([^"]+)"', (root / "Demo/App/Catalog.swift").read_text()))
    tests = (root / "Demo/UITests/CatalogUITests.swift").read_text()
    catalog = (root / "Demo/App/Catalog.swift").read_text()
    catalog_presets = {
        match.group(1): json.loads("[" + match.group(2) + "]")
        for match in re.finditer(r'\.init\(id: "([^"]+)"[^\n]*presets: \[([^\n]*)\]\)', catalog)
    }
    for route in index["routes"]:
        method = route["test"].split("/")[-1]
        assert "func " + method + "(" in tests, method
        assert route["presets"] == catalog_presets[route["id"]], route["id"]
        assert f'exercise("{route["id"]}", presets: {len(route["presets"])})' in tests, route["id"]
else:
    index = json.loads((root / "Demo/coverage.json").read_text())
    catalog = (root / "Demo/Sources/CatalogController.swift").read_text()
    cases = re.search(r"enum PagingRoute.*?case ([^\n]+)", catalog, re.S).group(1)
    routes = set(x.strip() for x in cases.split(","))
    tests = (root / "Demo/UITests/DemoUITests.swift").read_text()
    for route in index["routes"]:
        for test in route["automated"]:
            assert "func " + test.split(".")[-1] + "(" in tests, test
listed = [x["id"] for x in index["routes"]]
assert len(listed) == len(set(listed)), "Duplicate coverage route"
assert set(listed) == routes, (listed, routes)
for source in (root / "Demo").rglob("*.swift"):
    assert "@testable import" not in source.read_text(), source
print("Verified", len(routes), "Demo routes, test references and public imports")
