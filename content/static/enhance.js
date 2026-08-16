function enhance(type) {
  const grid = document.querySelector("main ul");
  if (!grid) return;

  const rows = () => Array.from(grid.children);
  let dragged = null;
  let from = null;

  for (const row of rows()) {
    row.draggable = true;
    // Links and images are natively draggable and would hijack the row's own drag
    for (const child of row.querySelectorAll("a, img")) {
      child.draggable = false;
    }
  }

  grid.addEventListener("dragstart", (event) => {
    dragged = event.target.closest("li");
    if (!dragged) return;

    from = rows().indexOf(dragged);
    event.dataTransfer.effectAllowed = "move";
    // Firefox refuses to start a drag unless some data is set
    event.dataTransfer.setData("text/plain", String(from));

    // Drag just the poster. Left to itself the browser snapshots the whole grid
    // row, which drags the neighbouring cards' titles along with it.
    const poster = dragged.querySelector("div");
    if (poster) {
      const box = poster.getBoundingClientRect();
      const x = Math.min(Math.max(event.clientX - box.left, 0), box.width);
      const y = Math.min(Math.max(event.clientY - box.top, 0), box.height);
      event.dataTransfer.setDragImage(poster, x, y);
    }

    requestAnimationFrame(() => dragged.classList.add("opacity-40"));
  });

  grid.addEventListener("dragover", (event) => {
    if (!dragged) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = "move";

    const target = event.target.closest("li");
    if (!target || target === dragged) return;

    // Drop after the target once we're past its midpoint, otherwise before it
    const box = target.getBoundingClientRect();
    const after = event.clientX > box.left + box.width / 2;
    grid.insertBefore(dragged, after ? target.nextSibling : target);
  });

  grid.addEventListener("drop", (event) => {
    if (!dragged) return;
    event.preventDefault();

    const to = rows().indexOf(dragged);
    if (to !== from) save(type, from, to);
  });

  grid.addEventListener("dragend", () => {
    if (!dragged) return;
    dragged.classList.remove("opacity-40");
    dragged = null;
  });
}

async function save(file, from, to) {
  try {
    const response = await fetch("http://localhost:8000/move", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ file, from_position: from, to_position: to }),
    });

    // Saving rewrites the csv, which makes saga rebuild and reload this page
    if (!response.ok) {
      throw new Error(`${response.status}: ${await response.text()}`);
    }
  } catch (error) {
    console.error(`Could not move ${file} ${from} -> ${to}`, error);
    alert(`Could not save the new order: ${error.message}`);
  }
}
