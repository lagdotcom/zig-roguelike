const displayConversion = {
  ￚ: "┌",
  ￄ: "─",
  "﾿": "┐",
  ﾳ: "│",
  "￀": "└",
  "￙": "┘",
};

class Display {
  /**
   * @param {number} width
   * @param {number} height
   */
  constructor(width, height, charWidth = 12, charHeight = 18) {
    this.width = width;
    this.height = height;
    this.charWidth = charWidth;
    this.charHeight = charHeight;
    this.x = 0;
    this.y = 0;
    this.fg = "grey";
    this.bg = "black";
    this.showCursor = true;

    this.table = document.createElement("table");
    this.table.style.borderCollapse = "collapse";
    this.table.style.textAlign = "center";
    this.table.style.fontFamily = "monospace";

    this.body = document.createElement("tbody");
    this.table.append(this.body);

    this.rows = [];
    for (let y = 0; y < height; y++) {
      const row = [];
      this.rows.push(row);

      const tr = document.createElement("tr");
      this.body.append(tr);

      for (let x = 0; x < width; x++) {
        const td = document.createElement("td");
        td.style.width = `${charWidth}px`;
        td.style.height = `${charHeight}px`;
        td.dataset.x = x;
        td.dataset.y = y;
        td.innerText = "";
        tr.append(td);
        row.push(td);
      }
    }

    document.body.append(this.table);
  }

  /**
   * @param {number} x
   * @param {number} y
   * @param {string} c
   */
  set(x, y, c) {
    const ch = displayConversion[c] ?? c;
    const td = this.rows[y][x];

    td.innerText = ch;
    td.style.color = this.fg;
    td.style.backgroundColor = this.bg;
  }

  /**
   * @param {string} c
   */
  emit(c) {
    this.set(this.x, this.y, c);

    this.x++;
    if (this.x >= this.width) {
      this.x = 0;
      this.y++;

      // TODO y scrolling
      if (this.y >= this.height) this.y = this.height - 1;
    }
  }

  clearToEnd() {
    for (let y = this.y; y < this.height; y++)
      for (let x = y === this.y ? this.x : 0; x < this.width; x++)
        this.set(x, y, " ");
  }
  clearToBeginning() {
    for (let y = 0; y <= this.y; y++)
      for (let x = 0; x < (y === this.y ? this.x : this.width); x++)
        this.set(x, y, " ");
  }
  clearAndReset() {
    for (let y = 0; y < this.height; y++)
      for (let x = 0; x < this.width; x++) this.set(x, y, " ");

    this.x = 0;
    this.y = 0;
  }
}

/**
 * @param {string} s
 * @param {number} defaultValue
 * @returns {number[]}
 */
function toNumberArray(s, defaultValue) {
  return s.split(";").map((n) => (n ? Number(n) : defaultValue));
}

/**
 * @param {string} s
 * @param {string[]} patterns
 * @returns {string|undefined}
 */
function isTerminatedBy(s, patterns) {
  for (const p of patterns) {
    if (s.endsWith(p)) return s.slice(0, -p.length);
  }
}

const ESC = "\x1b";
const BEL = "\b";
const ST = ESC + "\\";

class ANSIParser {
  /**
   * @param {Display} display
   */
  constructor(display) {
    this.display = display;
    /** @type {"IDLE"|"ESCAPE"|"CSI_PARAMS"|"CSI_INTERMEDIATE"|"OSC"} */
    this.state = "IDLE";
  }

  /**
   * @param {string} msg
   * @returns {"IDLE"}
   */
  warn(msg) {
    console.warn(msg);
    return "IDLE";
  }

  /**
   * @param {string} c
   */
  feed(c) {
    const newState = this[this.state](c);
    if (newState) this.state = newState;
  }

  /**
   * @param {string} c
   */
  IDLE = (c) => {
    if (c === ESC) return "ESCAPE";
    this.display.emit(c);
  };

  /**
   * @param {string} c
   */
  ESCAPE = (c) => {
    this.command = "";
    this.params = "";
    this.intermediate = "";
    if (c === "[") return "CSI_PARAMS";
    if (c === "]") return "OSC";
    return this.warn(`unknown escape char: ${c}`);
  };

  /**
   * @param {string} c
   */
  CSI_PARAMS = (c) => {
    if ("1234567890:;<=>?".includes(c)) this.params += c;
    else return this.CSI_INTERMEDIATE(c);
  };

  /**
   * @param {string} c
   */
  CSI_INTERMEDIATE = (c) => {
    if (` !"#$%&'()*+,-./`.includes(c)) {
      this.intermediate += c;
      return "CSI_INTERMEDIATE";
    }

    const { params, intermediate } = this;
    const final = c;

    if (final === "m") this.sgr(params, intermediate);
    else if (final === "H") {
      // Cursor Position
      const numbers = toNumberArray(params, 1);
      const row = numbers[0] ?? 1;
      const col = numbers[1] ?? 1;
      this.display.x = col - 1;
      this.display.y = row - 1;
    } else if (final === "J") {
      // Erase in Display
      const mode = toNumberArray(params, 0)[0] ?? 0;

      if (mode === 0) this.display.clearToEnd();
      else if (mode === 1) this.display.clearToBeginning();
      else this.display.clearAndReset();
    } else if (params === "?25") {
      // Show/Hide Cursor
      this.display.showCursor = final === "h";
    } else console.warn("CSI", final, params, intermediate);

    return "IDLE";
  };

  /**
   * @param {string} c
   */
  OSC = (c) => {
    this.command += c;

    const command = isTerminatedBy(this.command, [BEL, ST, "\x9c"]);
    if (command) {
      // Set Window Title
      if (command.startsWith("\0;")) {
        document.title = command.slice(2);
      } else console.warn("OSC", command);

      return "IDLE";
    }
  };

  /**
   * @param {string} params
   * @param {string} intermediate
   */
  sgr(params, intermediate) {
    const numbers = toNumberArray(params, 0);
    let i = 0;

    while (i < numbers.length) {
      const n = numbers[i++];

      // Set Background Color
      if (n === 48) {
        const space = numbers[i++];
        if (space !== 2) throw new Error(`Don't support ${space}; yet`);

        const r = numbers[i++];
        const g = numbers[i++];
        const b = numbers[i++];
        this.display.bg = `rgb(${r},${g},${b})`;
      }
      // Set Foreground Color
      else if (n === 38) {
        const space = numbers[i++];
        if (space !== 2) throw new Error(`Don't support ${space}; yet`);

        const r = numbers[i++];
        const g = numbers[i++];
        const b = numbers[i++];
        this.display.fg = `rgb(${r},${g},${b})`;
      }
      // Reset
      else if (n === 0) {
        this.display.fg = "grey";
        this.display.bg = "black";
      }
      // huh
      else console.warn("SGR", numbers);
    }
  }
}

class Writer {
  /**
   * @param {DataView} data
   * @param {number|undefined} offset
   */
  constructor(data, offset = 0) {
    this.data = data;
    this.offset = offset;
  }

  /**
   * @param {number} n
   */
  align(n) {
    const off = this.offset % n;
    if (off) this.offset += n - off;
  }

  /**
   * @param {number} n
   */
  WORD(n) {
    this.data.setUint16(this.offset, n, true);
    this.offset += 2;
  }

  /**
   * @param {boolean} v
   */
  BOOL(v) {
    this.data.setUint32(this.offset, v ? 1 : 0, true);
    this.offset += 4;
  }

  /**
   * @param {number} n
   */
  DWORD(n) {
    this.data.setUint32(this.offset, n, true);
    this.offset += 4;
  }
}

class Env {
  constructor() {
    this.display = new Display(80, 50);
    this.mode = 0;
    this.parser = new ANSIParser(this.display);
    /** @type {KeyboardEvent[]} */
    this.keyEvents = [];

    document.addEventListener("keydown", this.onKey);
    document.addEventListener("keyup", this.onKey);
    document.addEventListener("mousemove", this.onMouse);
    document.addEventListener("mousedown", this.onMouse);
    document.addEventListener("mouseup", this.onMouse);
  }

  get processedInput() {
    return (this.mode & 0x1) > 0;
  }
  get lineInput() {
    return (this.mode & 0x2) > 0;
  }
  get echoInput() {
    return (this.mode & 0x4) > 0;
  }
  get windowInput() {
    return (this.mode & 0x8) > 0;
  }
  get mouseInput() {
    return (this.mode & 0x10) > 0;
  }

  /**
   * @param {number} h
   * @param {number} addr
   * @param {number} len
   * @returns {number} event count
   */
  getConsoleInput = (h, addr, len) => {
    let count = 0;
    const w = new Writer(new DataView(this.memory.buffer, addr));

    let flags = 0;
    for (const e of this.keyEvents) {
      flags = 0;
      if (e.altKey) flags |= 0x1;
      if (e.ctrlKey) flags |= 0x4;
      if (e.shiftKey) flags |= 0x10;

      w.WORD(1); // INPUT_RECORD_TYPE.Key
      w.align(4);
      w.BOOL(e.type === "keydown");
      w.WORD(1);
      w.WORD(e.keyCode);
      w.WORD(0);
      w.WORD(e.charCode);
      w.DWORD(flags);

      count++;
      if (count == len) return count;
    }
    this.keyEvents = [];

    if (this.mouseChange && this.mouseInput) {
      const { x, y, buttons, moved } = this.mouseChange;

      w.WORD(2); // INPUT_RECORD_TYPE.Mouse
      w.align(4);
      w.WORD(x);
      w.WORD(y);
      w.DWORD(buttons); // MOUSE_EVENT_RECORD.dwButtonState
      w.DWORD(flags);
      w.DWORD(moved ? 1 : 0); // MOUSE_EVENT_FLAGS.MOUSE_MOVED
      count++;
    }
    this.mouseChange = undefined;

    return count;
  };

  /**
   * @param {number} h
   * @returns {number} mode
   */
  getConsoleMode = (h) => {
    return this.mode;
  };

  /**
   * @param {number} h
   * @param {number} addr
   */
  getConsoleSize = (h, addr) => {
    const data = new DataView(this.memory.buffer, addr);
    data.setInt16(0, this.display.width, true);
    data.setInt16(2, this.display.height, true);
  };

  /**
   * @param {number} buffer
   * @param {number} len
   */
  getRandomBytes = (buffer, len) => {
    const array = new Int8Array(this.memory.buffer, buffer, len);
    window.crypto.getRandomValues(array);
  };

  /**
   * @param {number} h
   * @param {number} mode
   */
  setConsoleMode = (h, mode) => {
    this.mode = mode;
  };

  /**
   * @param {number} addr
   */
  setEngineAddress = (addr) => {
    this.engine = addr;
  };

  /**
   * @param {number} h
   * @param {number} buffer
   * @param {number} len
   */
  writeToHandle = (h, buffer, len) => {
    const data = new Int8Array(this.memory.buffer, buffer, len);
    const str = new TextDecoder().decode(data);

    if (h === 1)
      for (const ch of data) this.parser.feed(String.fromCharCode(ch));
    else console.warn(`fd=${h}: ${str}`);
  };

  run() {
    if (!this.interval) this.interval = setInterval(this.next, 100);
  }

  stop() {
    clearInterval(this.interval);
    this.interval = undefined;
  }

  next = () => {
    try {
      this.tick(this.engine);
    } catch (e) {
      console.error(e);
      this.stop();
    }
  };

  /**
   * @param {KeyboardEvent} e
   */
  onKey = (e) => {
    this.keyEvents.push(e);
  };

  /**
   *
   * @param {MouseEvent} e
   */
  onMouse = (e) => {
    const { x, y } = e.target.dataset;
    this.mouseChange = {
      x: parseInt(x),
      y: parseInt(y),
      buttons: e.buttons,
      moved: e.type === "mousemove",
    };
  };
}

window.addEventListener("load", () => {
  const env = new Env();
  WebAssembly.instantiateStreaming(fetch("bin/zig-roguelike.wasm"), {
    env,
  }).then((results) => {
    const { _start, memory, tick } = results.instance.exports;

    window.env = env;
    env.memory = memory;
    env.tick = tick;

    _start();
    env.run();
  });
});
