// Untabit — pop the current tab out into its own window, or merge it back.
// Works in Chrome, Brave, Edge (chrome.*) and Firefox (browser.*).
const api = typeof browser !== "undefined" ? browser : chrome;
const IS_FIREFOX = typeof browser !== "undefined";

const DEFAULT_TITLE = "Untab it — pop this tab out, or merge it back";
const WARN_TITLE =
  "Untabit: the keyboard shortcut could not be registered (another extension may be using it) — click to fix";

// Origin records and focus history live in storage.session (not memory):
// the MV3 service worker is suspended after ~30s idle and would forget.
// storage.session is cleared when the browser closes — nothing hits disk.
const originKey = (tabId) => "origin:" + tabId;

async function untabit(tab, win) {
  await api.storage.session.set({
    [originKey(tab.id)]: { windowId: tab.windowId, index: tab.index }
  });
  // windows.create with tabId MOVES the tab: no reload, video keeps
  // playing, scroll position and form state survive.
  await api.windows.create({
    tabId: tab.id,
    focused: true,
    incognito: tab.incognito,
    state: win.state === "maximized" ? "maximized" : "normal"
  });
}

async function retabit(tab) {
  const key = originKey(tab.id);
  const stored = await api.storage.session.get(key);
  const origin = stored[key];

  let targetId = null;
  let index = -1;

  // First choice: the window the tab was untabbed from, at its old spot.
  if (origin) {
    try {
      const w = await api.windows.get(origin.windowId);
      if (w.type === "normal" && w.incognito === tab.incognito) {
        targetId = origin.windowId;
        index = origin.index;
      }
    } catch {
      // Origin window is gone — fall through to the focus-history fallback.
    }
  }

  if (targetId === null) {
    targetId = await findFallbackWindow(tab);
  }
  if (targetId === null) return; // no other window exists — stay put

  await api.storage.session.remove(key);
  await api.tabs.move(tab.id, { windowId: targetId, index });
  await api.tabs.update(tab.id, { active: true });
  await api.windows.update(targetId, { focused: true });
}

// Most recently focused other normal window (same incognito state), or null.
async function findFallbackWindow(tab) {
  const wins = await api.windows.getAll({ windowTypes: ["normal"] });
  const candidates = wins.filter(
    (w) => w.id !== tab.windowId && w.incognito === tab.incognito
  );
  if (candidates.length === 0) return null;

  const { focusHistory = [] } = await api.storage.session.get("focusHistory");
  for (const id of focusHistory) {
    if (candidates.some((w) => w.id === id)) return id;
  }
  return candidates[0].id;
}

// Alt+U (and the toolbar icon) toggle: siblings → pop out; alone → merge back.
async function toggle() {
  const [tab] = await api.tabs.query({ active: true, currentWindow: true });
  if (!tab) return;

  const win = await api.windows.get(tab.windowId, { populate: true });
  if (win.tabs.length > 1) {
    await untabit(tab, win);
  } else {
    await retabit(tab);
  }
}

// Browser state can change between querying a tab and moving it. Serialize
// toggle requests so rapid shortcut presses cannot race each other, and treat
// a tab/window disappearing during the operation as a harmless cancellation.
let toggleQueue = Promise.resolve();

function isMissingBrowserObject(error) {
  const message = error instanceof Error ? error.message : String(error);
  return /No (tab|window) with id|Invalid tab ID|Invalid window ID/i.test(message);
}

function queueToggle() {
  toggleQueue = toggleQueue.then(toggle).catch((error) => {
    if (!isMissingBrowserObject(error)) {
      console.error("Untabit toggle failed:", error);
    }
  });
  return toggleQueue;
}

// If the suggested shortcut couldn't be registered (usually claimed by
// another extension first), flag it with a badge on the toolbar icon.
// The next icon click then leads to the fix instead of toggling.
async function checkShortcut() {
  const commands = await api.commands.getAll();
  const cmd = commands.find((c) => c.name === "untab-it");
  if (cmd && cmd.shortcut === "") {
    await api.action.setBadgeBackgroundColor({ color: "#D93025" });
    await api.action.setBadgeText({ text: "!" });
    await api.action.setTitle({ title: WARN_TITLE });
  } else {
    await clearShortcutWarning();
  }
}

async function clearShortcutWarning() {
  await api.action.setBadgeText({ text: "" });
  await api.action.setTitle({ title: DEFAULT_TITLE });
}

api.runtime.onInstalled.addListener(checkShortcut);
api.runtime.onStartup.addListener(checkShortcut);

api.commands.onCommand.addListener((command) => {
  if (command === "untab-it") queueToggle();
});

api.action.onClicked.addListener(async () => {
  // The badge doubles as the state flag — it survives service worker
  // suspension without needing storage.
  const badge = await api.action.getBadgeText({});
  if (badge === "!") {
    await clearShortcutWarning();
    // Chromium extensions may open chrome:// pages; Firefox forbids
    // opening about:addons, so it gets a bundled instructions page.
    const url = IS_FIREFOX
      ? api.runtime.getURL("shortcut-help.html")
      : "chrome://extensions/shortcuts";
    await api.tabs.create({ url });
    return;
  }
  await queueToggle();
});

// Track window focus order so "merge back" has a sensible fallback when
// the origin window no longer exists.
api.windows.onFocusChanged.addListener(async (windowId) => {
  if (windowId === api.windows.WINDOW_ID_NONE) return;
  try {
    const w = await api.windows.get(windowId);
    if (w.type !== "normal") return;
  } catch {
    return;
  }
  const { focusHistory = [] } = await api.storage.session.get("focusHistory");
  const next = [windowId, ...focusHistory.filter((id) => id !== windowId)].slice(0, 10);
  await api.storage.session.set({ focusHistory: next });
});

// Drop the origin record when its tab closes.
api.tabs.onRemoved.addListener((tabId) => {
  api.storage.session.remove(originKey(tabId));
});
