/* Product-switcher label override for the local visual experiment. */
const codexLabel = "Codex";
const claudeLabel = "Claude";

function isModeSwitcherLabel(element) {
  return Boolean(
    element.closest('[aria-label^="Switch mode"], [role="menu"], [role="menuitem"]'),
  );
}

function relabelModeSwitcher(root = document.body) {
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
  const nodes = [];

  while (walker.nextNode()) {
    const node = walker.currentNode;
    if (node.nodeValue?.trim() === codexLabel && isModeSwitcherLabel(node.parentElement)) {
      nodes.push(node);
    }
  }

  for (const node of nodes) node.nodeValue = claudeLabel;

  document.querySelectorAll('[aria-label^="Switch mode"]').forEach((element) => {
    element.setAttribute(
      'aria-label',
      element.getAttribute('aria-label')?.replace(codexLabel, claudeLabel) ?? '',
    );
  });
}

function addClaudeWordmark() {
  if (!globalThis.__CODEX_CLAUDE_THEME_WORDMARK__) return;
  const trigger = document.querySelector('[aria-label^="Switch mode"]');
  if (!trigger) return;

  const source = document.documentElement.classList.contains('electron-light')
    ? './assets/custom-wordmark-light.svg'
    : './assets/custom-wordmark-dark.svg';
  const existing = trigger.querySelector('.claude-lab-wordmark');
  if (existing) {
    existing.src = source;
    return;
  }

  const walker = document.createTreeWalker(trigger, NodeFilter.SHOW_TEXT);
  let labelNode;
  while (walker.nextNode()) {
    const node = walker.currentNode;
    if ([codexLabel, claudeLabel].includes(node.nodeValue?.trim())) {
      labelNode = node;
      break;
    }
  }
  if (!labelNode?.parentElement) return;

  const wordmark = document.createElement('img');
  wordmark.className = 'claude-lab-wordmark';
  wordmark.src = source;
  wordmark.alt = '';
  wordmark.setAttribute('aria-hidden', 'true');
  labelNode.parentElement.replaceChildren(wordmark);
  trigger.dataset.claudeLabWordmark = 'true';
}

function refreshBranding() {
  relabelModeSwitcher();
  addClaudeWordmark();
}

refreshBranding();
new MutationObserver(refreshBranding).observe(document.documentElement, {
  attributes: true,
  attributeFilter: ['class'],
  childList: true,
  subtree: true,
});
