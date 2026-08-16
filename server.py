#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.14"
# dependencies = [
#   "fastapi",
#   "uvicorn",
# ]
# ///

import logging
from pathlib import Path

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

CSV_DIR = Path(__file__).parent / "Sources" / "Bolhoed" / "csv"

# Piggyback on uvicorn's logger so this lines up with its own output, which
# matters when `just run` interleaves it with saga's
log = logging.getLogger("uvicorn.error")

app = FastAPI()

# enhance.js posts from the saga dev server on :3000, so this is cross origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_methods=["POST"],
    allow_headers=["Content-Type"],
)


class MoveRequest(BaseModel):
    file: str
    from_position: int
    to_position: int


def csv_path(name: str) -> Path:
    # Guard against path traversal: only a bare name of an existing csv is allowed
    if "/" in name or "\\" in name or name.startswith("."):
        log.warning("Rejected file name %r", name)
        raise HTTPException(status_code=400, detail=f"Invalid file name: {name}")

    path = CSV_DIR / f"{Path(name).stem}.csv"
    if not path.is_file():
        log.warning("No csv at %s", path)
        raise HTTPException(status_code=404, detail=f"No such csv: {path.name}")

    return path


@app.post("/move")
def move_row(request: MoveRequest):
    log.info(
        "Move %s: %s -> %s",
        request.file,
        request.from_position,
        request.to_position,
    )

    path = csv_path(request.file)

    # Work line by line rather than through the csv module, so quoting and
    # rows with omitted trailing fields survive the round trip untouched.
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    header, rows = lines[0], lines[1:]

    for label, position in (("from", request.from_position), ("to", request.to_position)):
        if not 0 <= position < len(rows):
            log.warning(
                "%s_position %s out of range, %s has %s rows", label, position, path.name, len(rows)
            )
            raise HTTPException(
                status_code=400,
                detail=f"{label}_position {position} out of range (0..{len(rows) - 1})",
            )

    if request.from_position == request.to_position:
        log.info("Nothing to do, positions are the same")
    else:
        # Make sure the last row keeps its newline if it moves up
        if not rows[-1].endswith("\n"):
            rows[-1] += "\n"

        row = rows.pop(request.from_position)
        rows.insert(request.to_position, row)
        path.write_text(header + "".join(rows), encoding="utf-8")
        log.info("Moved %r, wrote %s rows to %s", row.strip(), len(rows), path.name)

    return {"file": path.name, "rows": len(rows)}


@app.get("/")
def read_root():
    return {"Hello": "World"}


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
