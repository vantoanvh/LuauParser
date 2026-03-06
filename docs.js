(function () {
	"use strict";

	const APP_CONFIG = {
		repo: {
			owner: "vantoanvh",
			name: "LuauParser",
			url: "https://github.com/vantoanvh/LuauParser/tree/main",
		},
	};

	const VIEW_META = {
		overview: {
			title: "LuauParser",
			description: "Parser reference for AST, CST, core records, and unions.",
		},
		"getting-started": {
			title: "Getting Started",
			description: "Public API, parser options, result shape, and exported enums.",
		},
		ast: {
			title: "Ast",
			description: "Semantic tree nodes and related records.",
		},
		cst: {
			title: "Cst",
			description: "Concrete syntax tree nodes and token metadata.",
		},
		core: {
			title: "Core",
			description: "Shared parser structures and internal support records.",
		},
		unions: {
			title: "Unions",
			description: "Shared union entry points collected into a dedicated view.",
		},
	};

	const state = {
		data: null,
		sections: [],
		sectionMap: new Map(),
		query: "",
		view: "overview",
		pendingAnchor: "",
	};

	const elements = {};

	document.addEventListener("DOMContentLoaded", init);

	function init() {
		if (!window.DOCS_DATA) {
			document.body.innerHTML = '<main class="page-shell"><section class="empty-state"><h1>Documentation data is missing</h1><p>Run <code>node page/build-gh-pages.js</code> to regenerate <code>gh-pages/docs-data.js</code>.</p></section></main>';
			return;
		}

		cacheElements();
		hydrateState();
		bindEvents();
		render();
		hydrateGitHubCard();
	}

	function cacheElements() {
		elements.heroPanel = document.getElementById("hero-panel");
		elements.resourceList = document.getElementById("resource-list");
		elements.jumpPanel = document.querySelector(".jump-panel");
		elements.jumpTitle = document.getElementById("jump-title");
		elements.jumpLinks = document.getElementById("jump-links");
		elements.searchInput = document.getElementById("search-input");
		elements.searchResults = document.getElementById("search-results");
		elements.githubCard = document.getElementById("github-card");
		elements.githubName = document.getElementById("github-name");
		elements.githubStars = document.getElementById("github-stars");
		elements.githubRelease = document.getElementById("github-release");
		elements.navTabs = Array.from(document.querySelectorAll(".nav-tab"));
		elements.contentLayout = document.querySelector(".content-layout");
	}

	function hydrateState() {
		state.data = window.DOCS_DATA;
		state.sections = state.data.sections.map((section) => {
			const normalized = {
				...section,
				description: cleanDocText(section.description),
				table: {
					...section.table,
					rows: section.table.rows.map((row) => row.map(cleanDocText)),
				},
			};

			return {
				...normalized,
				searchBlob: buildSearchBlob(normalized),
			};
		});

		state.sectionMap = new Map(state.sections.map((section) => [section.anchor, section]));
		state.pendingAnchor = normalizeHash(window.location.hash);
		state.view = deriveInitialView();
	}

	function bindEvents() {
		elements.searchInput.addEventListener("input", (event) => {
			state.query = event.target.value.trim().toLowerCase();
			renderSearchResults();
		});

		elements.searchInput.addEventListener("keydown", (event) => {
			if (event.key === "Escape") {
				elements.searchInput.value = "";
				state.query = "";
				elements.searchResults.hidden = true;
			}
		});

		document.addEventListener("click", (event) => {
			const viewTrigger = event.target.closest("[data-view]");
			if (viewTrigger) {
				const view = viewTrigger.getAttribute("data-view");
				const anchor = viewTrigger.getAttribute("data-anchor");
				if (anchor) {
					navigateToAnchor(anchor, sanitizeView(view) || "overview");
				} else {
					setView(view);
				}
				return;
			}

			const anchorTrigger = event.target.closest("[data-anchor]");
			if (anchorTrigger) {
				event.preventDefault();
				const anchor = anchorTrigger.getAttribute("data-anchor");
				const target = state.sectionMap.get(anchor);
				if (target) {
					navigateToSection(target);
				} else if (isGuideAnchor(anchor)) {
					navigateToAnchor(anchor, "getting-started");
				}
				return;
			}

			if (!elements.searchResults.contains(event.target) && event.target !== elements.searchInput) {
				elements.searchResults.hidden = true;
			}
		});

		window.addEventListener("hashchange", () => {
			const anchor = normalizeHash(window.location.hash);
			if (!anchor) {
				return;
			}

			const target = state.sectionMap.get(anchor);
			if (target) {
				state.pendingAnchor = anchor;
				state.view = getSectionView(target);
				render();
			} else if (isGuideAnchor(anchor)) {
				state.pendingAnchor = anchor;
				state.view = "getting-started";
				render();
			}
		});
	}

	function deriveInitialView() {
		const params = new URLSearchParams(window.location.search);
		const explicitView = sanitizeView(params.get("view"));
		if (explicitView) {
			return explicitView;
		}

		if (!state.pendingAnchor) {
			return "overview";
		}

		const section = state.sectionMap.get(state.pendingAnchor);
		return section ? getSectionView(section) : "overview";
	}

	function sanitizeView(value) {
		if (
			value === "overview"
			|| value === "getting-started"
			|| value === "ast"
			|| value === "cst"
			|| value === "core"
			|| value === "unions"
		) {
			return value;
		}

		return "";
	}

	function normalizeHash(hash) {
		return decodeURIComponent((hash || "").replace(/^#/, "")).trim().toLowerCase();
	}

	function getSectionView(section) {
		return section.group === "Unions" ? "unions" : section.category;
	}

	function isGuideAnchor(anchor) {
		return anchor === "api"
			|| anchor === "options"
			|| anchor === "result"
			|| anchor === "enums"
			|| anchor === "cst-access";
	}

	function buildSearchBlob(section) {
		const rowText = section.table.rows.flat().join(" ");
		return [
			section.name,
			section.group,
			section.category,
			section.badges.join(" "),
			section.tags.join(" "),
			section.description,
			section.example,
			rowText,
		].join(" ").toLowerCase();
	}

	function setView(view) {
		const nextView = sanitizeView(view);
		if (!nextView) {
			return;
		}

		state.view = nextView;
		state.pendingAnchor = "";
		state.query = "";
		elements.searchInput.value = "";
		elements.searchResults.hidden = true;
		updateUrl();
		render();
		window.scrollTo({ top: 0, behavior: "auto" });
	}

	function navigateToAnchor(anchor, view) {
		state.view = view;
		state.pendingAnchor = anchor;
		state.query = "";
		elements.searchInput.value = "";
		elements.searchResults.hidden = true;
		updateUrl(anchor);
		render();
	}

	function navigateToSection(section) {
		navigateToAnchor(section.anchor, getSectionView(section));
	}

	function updateUrl(anchor) {
		const params = new URLSearchParams(window.location.search);
		if (state.view === "overview") {
			params.delete("view");
		} else {
			params.set("view", state.view);
		}

		const query = params.toString();
		const nextUrl = `${window.location.pathname}${query ? `?${query}` : ""}${anchor ? `#${anchor}` : ""}`;
		history.replaceState(null, "", nextUrl);
	}

	function isHomeView() {
		return state.view === "overview" && !state.query;
	}

	function isGettingStartedView() {
		return state.view === "getting-started" && !state.query;
	}

	function getVisibleSections() {
		if (state.view === "overview") {
			return [];
		}

		if (state.view === "getting-started") {
			return [];
		}

		if (state.view === "unions") {
			return state.sections.filter((section) => section.group === "Unions");
		}

		return state.sections.filter((section) => section.category === state.view && section.group !== "Unions");
	}

	function getSearchResults() {
		if (!state.query) {
			return [];
		}

		return state.sections
			.filter((section) => section.searchBlob.includes(state.query))
			.sort((left, right) => {
				const leftStarts = left.name.toLowerCase().startsWith(state.query) ? 0 : 1;
				const rightStarts = right.name.toLowerCase().startsWith(state.query) ? 0 : 1;
				if (leftStarts !== rightStarts) {
					return leftStarts - rightStarts;
				}

				return left.name.localeCompare(right.name);
			})
			.slice(0, 10);
	}

	function render() {
		const home = isHomeView();
		const guide = isGettingStartedView();
		document.body.classList.toggle("is-home-view", home);
		document.body.classList.toggle("is-guide-view", guide);
		elements.contentLayout.classList.toggle("is-home", home);
		elements.contentLayout.classList.toggle("is-guide", guide);
		elements.jumpPanel.hidden = home;

		renderNav();
		renderHero();
		renderResources();
		renderJumpLinks();
		renderSearchResults();
		queueHighlight();
		queueScroll();
	}

	function renderNav() {
		for (const tab of elements.navTabs) {
			const isActive = sanitizeView(tab.getAttribute("data-view")) === state.view;
			tab.classList.toggle("is-active", isActive);
		}
	}

	function renderHero() {
		if (isHomeView()) {
			elements.heroPanel.innerHTML = renderOverviewHero();
			return;
		}

		if (isGettingStartedView()) {
			elements.heroPanel.innerHTML = renderGettingStartedHero();
			return;
		}

		const visibleSections = getVisibleSections();
		const meta = VIEW_META[state.view];
		elements.heroPanel.innerHTML = `
			<div class="hero-block">
				<h1>${escapeHtml(meta.title)}</h1>
				<p>${escapeHtml(meta.description)} ${visibleSections.length ? `(${visibleSections.length})` : ""}</p>
			</div>
		`;
	}

	function renderOverviewHero() {
		const astCount = state.data.summary.views.ast.count;
		const cstCount = state.data.summary.views.cst.count;
		const coreCount = state.data.summary.views.core.count;
		const homeExample = [
			"local Parser = require(path.to.LuauParser)",
			"",
			"local success, result = Parser.parse('local foo: (string, ...number) -> (...any)')",
			"",
			"if success then",
			"\tprint(result.root) -- do anything you want",
			"else",
			"\twarn(result.errors)",
			"end",
		].join("\n");

		return `
			<div class="hero-block home-doc" id="getting-started">
				<div class="home-top">
					<div class="hero-home-copy">
						<div class="hero-kicker">Documentation</div>
						<h1>${escapeHtml(state.data.title)}</h1>
						<p class="home-lead">
							A modern, fully featured <a href="https://luau.org/" target="_blank" rel="noreferrer noopener">Luau</a> parser written entirely in Luau.<br>
							Fully strict-typing with the New Type Solver and optimized for high performance.
						</p>
						<div class="home-action-grid">
							<button type="button" class="home-action" data-view="ast">
								<strong>AST nodes</strong>
								<span>Semantic tree records and parser output.</span>
								<label>${astCount} entries</label>
							</button>
							<button type="button" class="home-action" data-view="cst">
								<strong>CST nodes</strong>
								<span>Concrete syntax nodes and token metadata.</span>
								<label>${cstCount} entries</label>
							</button>
							<button type="button" class="home-action" data-view="core">
								<strong>Core nodes</strong>
								<span>Shared parser internals and support structures.</span>
								<label>${coreCount} entries</label>
							</button>
						</div>
					</div>
					<div class="home-logo-wrap">
						<img class="home-logo" src="LuauParser.png" alt="LuauParser">
					</div>
				</div>

				<section class="home-section">
					<h2>Introduction</h2>
					<p class="home-note">Only compatibles with <strong>New Type Solver</strong>.</p>
					<p>
						A complete port of <a href="https://github.com/luau-lang/luau/blob/master/Ast/src/Parser.cpp" target="_blank" rel="noreferrer noopener">Parser.cpp</a>
						providing both <em>AST</em> <strong>(Abstract Syntax Tree)</strong> and <em>CST</em> <strong>(Concrete Syntax Tree)</strong>.<br>
						<strong>To stay true to the original implementation</strong>, the CST does not include low-level trivia such as whitespace.
					</p>
					<p>
						This Luau parser is primarily intended for plugin development and for building Luau compilers or tooling.<br>
						It provides detailed syntax through both <strong>AST</strong> and <strong>CST</strong>, making it well suited for advanced language tooling such as
						<em>linters, formatters, highlighter, refactoring tools,</em> or even a full <em>luau compiler/transpiler</em>.
					</p>
				</section>

				<section class="home-section">
					<h2>Performance</h2>
					<p class="home-note">
						After <code>0.710</code> updates, I do alot of optimization changes, and able to make this <strong>FASTER</strong> than
						<a href="https://github.com/jackdotink/luaup" target="_blank" rel="noreferrer noopener">luaup</a> itself.
					</p>
					<p>
						This parser is fast because it uses a simple singleton-style procedural design. It just resets its internal variables and runs,
						avoiding the overhead of more complex architectures.
					</p>
				</section>

				<section class="home-section">
					<div class="home-section-head">
						<h2>Code Examples</h2>
					</div>
					${renderExample(homeExample)}
				</section>
			</div>
		`;
	}

	function renderGettingStartedHero() {
		return `
			<div class="hero-block guide-hero">
				<div class="hero-kicker">Getting Started</div>
				<h1>Public API & Usage</h1>
				<p>The main entry point is <code>Parser.parse(source, options?)</code>. This page documents the current exported surface from <code>src/init.luau</code> and the typed shapes from <code>src/Syntax.luau</code>.</p>
			</div>
		`;
	}

	function renderGettingStartedPage() {
		const parseSignature = [
			"local success, result = Parser.parse(source, options)",
			"-- success: boolean",
			"-- result: Parser.Result",
		].join("\n");

		const apiExample = [
			"local Parser = require(path.to.LuauParser)",
			"",
			"local success, result = Parser.parse(\"local foo: (string, ...number) -> (...any)\", {",
			"\tstoreCstData = true,",
			"\tcaptureComments = true,",
			"})",
			"",
			"if success then",
			"\tprint(result.root)",
			"\tprint((result.root :: any).cstNode)",
			"else",
			"\twarn(result.errors)",
			"end",
		].join("\n");

		const optionsBlock = [
			"type Options = {",
			"\tallowDeclarationSyntax: boolean?, -- typed, but currently unused in init.luau",
			"\tcaptureComments: boolean?,",
			"\tparseFragment: {",
			"\t\tlocalMap: { [string]: AstLocal? },",
			"\t\tlocalStack: { AstLocal? },",
			"\t\tresumePosition: Position,",
			"\t}?,",
			"\tstoreCstData: boolean?,",
			"}",
		].join("\n");

		const resultBlock = [
			"type Result = {",
			"\troot: AstStatBlock?,",
			"\tcommentLocations: { Comment },",
			"\thotcomments: { HotComment },",
			"\terrors: { ParseError },",
			"}",
		].join("\n");

		const enumsBlock = [
			"Parser.QuoteStyle = {",
			"\t-- Double-quoted strings and parsed interpolated-string text pieces.",
			"\tQuotedSimple = 0,",
			"\t-- Single-quoted strings: 'foo'",
			"\tQuotedSingle = 1,",
			"\t-- Raw strings: [[foo]]",
			"\tQuotedRaw = 2,",
			"\t-- Unquoted string keys inside table fields: { foo = 1 }",
			"\tUnquoted = 3,",
			"}",
			"",
			"Parser.BraceType = {",
			"\t-- Lexer state for braces opened by interpolated strings.",
			"\tInterpolatedString = 0,",
			"\t-- Normal braces used by tables, blocks, and regular expressions.",
			"\tNormal = 1,",
			"}",
			"",
			"Parser.UnaryOp = {",
			"\t-- `not expr`",
			"\tNot = 0,",
			"\t-- `-expr`",
			"\tMinus = 1,",
			"\t-- `#expr`",
			"\tLen = 2,",
			"}",
			"",
			"Parser.BinaryOp = {",
			"\tAdd = 0, -- `+`",
			"\tSub = 1, -- `-`",
			"\tMul = 2, -- `*`",
			"\tDiv = 3, -- `/`",
			"\tFloorDiv = 4, -- `//`",
			"\tMod = 5, -- `%`",
			"\tPow = 6, -- `^`",
			"\tConcat = 7, -- `..`",
			"\tCompareNe = 8, -- `~=`",
			"\tCompareEq = 9, -- `==`",
			"\tCompareLt = 10, -- `<`",
			"\tCompareLe = 11, -- `<=`",
			"\tCompareGt = 12, -- `>`",
			"\tCompareGe = 13, -- `>=`",
			"\tAnd = 14, -- `and`",
			"\tOr = 15, -- `or`",
			"}",
			"",
			"-- Note: there is no `CstQuotes.QuotedSimple` in the current parser.",
			"-- The CST uses QuotedSingle / QuotedDouble / QuotedRaw / QuotedInterp.",
			"Parser.CstQuotes = {",
			"\tQuotedSingle = 0, -- ''",
			"\tQuotedDouble = 1, -- \"\"",
			"\tQuotedRaw = 2, -- [[]]",
			"\tQuotedInterp = 3, -- ``",
			"}",
		].join("\n");

		return `
			<section class="guide-page">
				<section class="guide-section" id="api">
					<h2>Public API</h2>
					<p><code>Parser.parse</code> is the main entry point. It returns <code>(boolean, Result)</code>, where the boolean only reports parse success when <code>pcall</code> succeeds and no parse errors were recorded.</p>
					${renderExample(parseSignature)}
					${renderExample(apiExample)}
				</section>

				<section class="guide-section" id="options">
					<h2>Options</h2>
					<p>The current options type comes from <code>src/Syntax.luau</code>. The two commonly used toggles are <code>captureComments</code> and <code>storeCstData</code>. <code>parseFragment</code> is for resumed parsing, and <code>allowDeclarationSyntax</code> is still typed but is currently not consumed in <code>src/init.luau</code>.</p>
					${renderExample(optionsBlock)}
				</section>

				<section class="guide-section" id="result">
					<h2>Result</h2>
					<p><code>result.root</code> is an <code>AstStatBlock?</code>, not a flat <code>{AstNode}</code> list. Comments and hotcomments are returned separately, and all parse errors are collected in <code>result.errors</code>.</p>
					${renderExample(resultBlock)}
				</section>

				<section class="guide-section" id="enums">
					<h2>Enums</h2>
					<p>The parser currently exports <code>QuoteStyle</code>, <code>BraceType</code>, <code>UnaryOp</code>, <code>BinaryOp</code>, and <code>CstQuotes</code> directly from <code>src/init.luau</code>. The code block below now documents each enum member inline.</p>
					${renderExample(enumsBlock)}
				</section>

				<section class="guide-section" id="cst-access">
					<h2>CST Access</h2>
					<p>When <code>storeCstData = true</code>, CST-backed AST nodes expose <code>node.cstNode</code>. The parse result itself does not expose a separate <code>cstNodeMap</code>.</p>
				</section>
			</section>
		`;
	}

	function renderResources() {
		if (isHomeView()) {
			elements.resourceList.innerHTML = "";
			return;
		}

		if (isGettingStartedView()) {
			elements.resourceList.innerHTML = renderGettingStartedPage();
			return;
		}

		const visibleSections = getVisibleSections();
		if (visibleSections.length === 0) {
			elements.resourceList.innerHTML = `
				<section class="empty-state">
					<h2>No results</h2>
					<p>Try a shorter search term or switch sections.</p>
				</section>
			`;
			return;
		}

		elements.resourceList.innerHTML = visibleSections.map(renderResourceCard).join("");
	}

	function renderResourceCard(section) {
		const tags = section.tags.filter((tag) => !isBadgeTag(tag));
		const titleBadges = collectTitleBadges(section);

		return `
			<article class="resource-card" id="${section.anchor}">
				<div class="resource-header">
					<div class="resource-heading">
						${titleBadges.map(renderBadge).join("")}
						<h3><a href="#${section.anchor}" data-anchor="${section.anchor}">${escapeHtml(section.name)}</a></h3>
					</div>
					${tags.length ? `<div class="resource-tags">${tags.map(renderTag).join("")}</div>` : ""}
				</div>
				${section.description ? `<p class="resource-description">${renderInlineMarkdown(section.description)}</p>` : ""}
				${renderExample(section.example)}
				${renderTable(section)}
			</article>
		`;
	}

	function collectTitleBadges(section) {
		const labels = [...section.badges, ...section.tags].map((item) => item.toUpperCase());
		if (labels.includes("INTERNAL")) {
			return ["INTERNAL"];
		}

		if (labels.includes("AST")) {
			return ["AST"];
		}

		if (labels.includes("CST")) {
			return ["CST"];
		}

		return ["CORE"];
	}

	function isBadgeTag(tag) {
		return tag.toLowerCase() === "internal";
	}

	function renderBadge(label) {
		return `<span class="node-badge node-badge-${getBadgeTone(label)}">${escapeHtml(label)}</span>`;
	}

	function renderTag(label) {
		return `<span class="tag-pill">${escapeHtml(label)}</span>`;
	}

	function getBadgeTone(label) {
		const key = label.toLowerCase();
		if (key === "ast") {
			return "ast";
		}

		if (key === "cst") {
			return "cst";
		}

		return "core";
	}

	function renderExample(example) {
		if (!example) {
			return "";
		}

		const lineNumbers = buildLineNumberColumn(example);
		return `
			<div class="example-shell">
				<div class="code-frame">
					<pre class="code-gutter" aria-hidden="true">${lineNumbers}</pre>
					<pre><code class="language-lua">${escapeHtml(example)}</code></pre>
				</div>
			</div>
		`;
	}

	function renderTable(section) {
		if (!section.table.type || section.table.rows.length === 0) {
			return "";
		}

		if (section.table.type === "members") {
			return `
				<div class="table-shell">
					<div class="member-list">
						${section.table.rows.map((row) => `
							<div class="member-item">
								<div class="member-name">${renderInlineMarkdown(row[0] || "")}</div>
								<div class="member-description">${renderInlineMarkdown(row[1] || "")}</div>
							</div>
						`).join("")}
					</div>
				</div>
			`;
		}

		return `
			<div class="table-shell">
				<div class="field-list">
					${section.table.rows.map((row) => `
						<div class="field-row">
							<div class="field-name">${renderInlineMarkdown(row[0] || "")}</div>
							<div class="field-type">${renderFieldValue(row[1] || "")}</div>
							<div class="field-description">${renderInlineMarkdown(row[2] || "")}</div>
						</div>
					`).join("")}
				</div>
			</div>
		`;
	}

	function renderJumpLinks() {
		if (isHomeView()) {
			elements.jumpLinks.innerHTML = "";
			return;
		}

		if (isGettingStartedView()) {
			elements.jumpTitle.textContent = "Guide";
			elements.jumpLinks.innerHTML = [
				["api", "Public API"],
				["options", "Options"],
				["result", "Result"],
				["enums", "Enums"],
				["cst-access", "CST Access"],
			].map(([anchor, label]) => `<a href="#${anchor}" class="jump-link" data-anchor="${anchor}">${escapeHtml(label)}</a>`).join("");
			return;
		}

		const visibleSections = getVisibleSections().slice(0, 32);
		elements.jumpTitle.textContent = state.view === "unions" ? "Unions" : "Nodes";
		elements.jumpLinks.innerHTML = visibleSections
			.map((section) => `<a href="#${section.anchor}" class="jump-link" data-anchor="${section.anchor}">${escapeHtml(section.name)}</a>`)
			.join("");
	}

	function renderSearchResults() {
		const results = getSearchResults();
		if (!state.query) {
			elements.searchResults.hidden = true;
			elements.searchResults.innerHTML = "";
			return;
		}

		elements.searchResults.hidden = false;
		elements.searchResults.innerHTML = results.length
			? results.map((section) => `
				<a href="#${section.anchor}" class="search-result" data-anchor="${section.anchor}">
					<div class="search-result-name">${escapeHtml(section.name)}</div>
					<div class="search-result-meta">${escapeHtml(getSectionView(section))} / ${escapeHtml(section.group === "Unions" ? "union" : "entry")}</div>
				</a>
			`).join("")
			: '<div class="search-empty">No matches.</div>';
	}

	function renderInlineMarkdown(text) {
		if (!text) {
			return "";
		}

		let html = escapeHtml(text).replace(/\\\|/g, "|");
		html = html.replace(/\[([^\]]+)\]\((#[^)]+)\)/g, (_match, label, anchor) => {
			const normalized = anchor.replace(/^#/, "").toLowerCase();
			return `<a href="#${normalized}" data-anchor="${normalized}">${escapeHtml(label)}</a>`;
		});
		html = html.replace(/`([^`]+)`/g, (_match, code) => `<code>${escapeHtml(code)}</code>`);
		return html;
	}

	function renderFieldValue(text) {
		if (!text) {
			return "";
		}

		const source = String(text).replace(/\\\|/g, "|");
		const pattern = /"(\[([^\]]+)\]\((#[^)]+)\))"|'(\[([^\]]+)\]\((#[^)]+)\))'|\[([^\]]+)\]\((#[^)]+)\)|`([^`]+)`|"[^"]*"|'[^']*'|\b[A-Za-z_][A-Za-z0-9_]*\b/g;
		let html = "";
		let lastIndex = 0;
		let match = pattern.exec(source);

		while (match) {
			html += escapeHtml(source.slice(lastIndex, match.index));

			if (match[2] && match[3]) {
				const label = match[2];
				const anchor = match[3].replace(/^#/, "").toLowerCase();
				html += `<span class="field-token field-token-string">"</span><a href="#${anchor}" data-anchor="${anchor}" class="field-link field-token-string">${escapeHtml(label)}</a><span class="field-token field-token-string">"</span>`;
			} else if (match[5] && match[6]) {
				const label = match[5];
				const anchor = match[6].replace(/^#/, "").toLowerCase();
				html += `<span class="field-token field-token-string">'</span><a href="#${anchor}" data-anchor="${anchor}" class="field-link field-token-string">${escapeHtml(label)}</a><span class="field-token field-token-string">'</span>`;
			} else if (match[7] && match[8]) {
				const label = match[7];
				const anchor = match[8].replace(/^#/, "").toLowerCase();
				html += `<a href="#${anchor}" data-anchor="${anchor}" class="field-link field-token-${classifyFieldToken(label)}">${escapeHtml(label)}</a>`;
			} else if (match[9]) {
				html += `<code>${escapeHtml(match[9])}</code>`;
			} else {
				const token = match[0];
				html += `<span class="field-token field-token-${classifyFieldToken(token)}">${escapeHtml(token)}</span>`;
			}

			lastIndex = pattern.lastIndex;
			match = pattern.exec(source);
		}

		html += escapeHtml(source.slice(lastIndex));
		return html;
	}

	function classifyFieldToken(token) {
		const raw = String(token).replace(/^['"]|['"]$/g, "");
		const lower = raw.toLowerCase();

		if (token.startsWith('"') || token.startsWith("'")) {
			return "string";
		}

		if (lower === "string" || lower === "any") {
			return "string";
		}

		if (lower === "number" || lower === "boolean" || lower === "true" || lower === "false") {
			return "primitive";
		}

		if (/^Ast[A-Z]/.test(raw)) {
			return "ast";
		}

		if (/^[A-Z][A-Za-z0-9_]*$/.test(raw)) {
			return "ref";
		}

		return "plain";
	}

	function cleanDocText(text) {
		if (!text) {
			return "";
		}

		return text
			.replace(/\s+\((?:`[^`]+`|[^()]+)\)\.?$/, "")
			.replace(/\s+/g, " ")
			.trim();
	}

	function buildLineNumberColumn(source) {
		const lineCount = source.replace(/\r\n/g, "\n").split("\n").length;
		return Array.from({ length: lineCount }, (_value, index) => String(index + 1)).join("\n");
	}

	function queueHighlight() {
		requestAnimationFrame(() => {
			if (!window.hljs) {
				return;
			}

			document.querySelectorAll(".example-shell pre code").forEach((block) => {
				window.hljs.highlightElement(block);
			});
		});
	}

	function queueScroll() {
		if (!state.pendingAnchor) {
			return;
		}

		const anchor = state.pendingAnchor;
		state.pendingAnchor = "";

		requestAnimationFrame(() => {
			const target = document.getElementById(anchor);
			if (target) {
				target.scrollIntoView({ behavior: "auto", block: "start" });
			}
		});
	}

	function escapeHtml(value) {
		return String(value)
			.replace(/&/g, "&amp;")
			.replace(/</g, "&lt;")
			.replace(/>/g, "&gt;")
			.replace(/"/g, "&quot;")
			.replace(/'/g, "&#39;");
	}

	async function hydrateGitHubCard() {
		const repo = resolveRepository();
		if (!repo) {
			elements.githubName.textContent = "not configured";
			elements.githubStars.textContent = "";
			elements.githubRelease.textContent = "";
			elements.githubCard.removeAttribute("href");
			return;
		}

		const repoUrl = repo.url || `https://github.com/${repo.owner}/${repo.name}`;
		elements.githubCard.href = repoUrl;
		elements.githubName.textContent = `${repo.owner}/${repo.name}`;
		elements.githubStars.textContent = "loading";
		elements.githubRelease.textContent = "loading";

		try {
			const [repoResponse, releaseResponse] = await Promise.all([
				fetch(`https://api.github.com/repos/${repo.owner}/${repo.name}`),
				fetch(`https://api.github.com/repos/${repo.owner}/${repo.name}/releases/latest`),
			]);

			if (repoResponse.ok) {
				const repoData = await repoResponse.json();
				elements.githubName.textContent = repoData.full_name || `${repo.owner}/${repo.name}`;
				elements.githubStars.textContent = `${formatNumber(repoData.stargazers_count || 0)} stars`;
			} else {
				elements.githubStars.textContent = "stars unavailable";
			}

			if (releaseResponse.ok) {
				const releaseData = await releaseResponse.json();
				elements.githubRelease.textContent = releaseData.tag_name || "no release";
			} else {
				elements.githubRelease.textContent = "no release";
			}
		} catch (_error) {
			elements.githubStars.textContent = "offline";
			elements.githubRelease.textContent = "offline";
		}
	}

	function resolveRepository() {
		if (APP_CONFIG.repo && APP_CONFIG.repo.owner && APP_CONFIG.repo.name) {
			return APP_CONFIG.repo;
		}

		if (!window.location.hostname.endsWith(".github.io")) {
			return null;
		}

		const owner = window.location.hostname.split(".")[0];
		const pathParts = window.location.pathname.split("/").filter(Boolean);
		if (pathParts.length === 0) {
			return null;
		}

		const repo = pathParts[0];
		if (repo === "gh-pages") {
			return null;
		}

		return { owner, name: repo };
	}

	function formatNumber(value) {
		return new Intl.NumberFormat("en-US", { notation: value >= 1000 ? "compact" : "standard" }).format(value);
	}
})();
