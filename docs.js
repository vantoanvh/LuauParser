/**
 * Luau Parser Documentation - Interactive Features
 * - Search filtering
 * - Scroll-spy for sidebar navigation
 * - Syntax highlighting initialization
 */

(function () {
    'use strict';

    // Initialize when DOM is ready
    document.addEventListener('DOMContentLoaded', function () {
        initSearch();
        initScrollSpy();
        initSyntaxHighlighting();
    });

    /**
     * Search Functionality
     * Filters navigation items and type entries based on input
     */
    function initSearch() {
        const searchInput = document.getElementById('search-input');
        if (!searchInput) return;

        // Create results container if it doesn't exist
        let resultsContainer = document.getElementById('search-results');
        if (!resultsContainer) {
            resultsContainer = document.createElement('div');
            resultsContainer.id = 'search-results';
            resultsContainer.className = 'search-results-dropdown hidden';
            searchInput.parentElement.appendChild(resultsContainer);
        }

        const typeEntries = document.querySelectorAll('.type-entry');
        const sections = document.querySelectorAll('.category-header');
        const tocItems = document.querySelectorAll('.toc-root li');

        searchInput.addEventListener('input', function () {
            const query = this.value.toLowerCase().trim();

            if (query === '') {
                resultsContainer.classList.add('hidden');
                typeEntries.forEach(entry => entry.classList.remove('hidden'));
                sections.forEach(s => s.classList.remove('hidden'));
                tocItems.forEach(t => t.classList.remove('hidden'));
                return;
            }

            // Global Search using SEARCH_INDEX
            if (window.SEARCH_INDEX) {
                const results = window.SEARCH_INDEX.filter(item =>
                    item.name.toLowerCase().includes(query) ||
                    (item.desc && item.desc.toLowerCase().includes(query)) ||
                    item.tags.some(t => t.toLowerCase().includes(query))
                ).slice(0, 10); // Limit to 10 results

                if (results.length > 0) {
                    resultsContainer.innerHTML = results.map(res => `
                        <a href="${res.file}#${res.name}" class="search-result-item">
                            <div class="result-name">${res.name}</div>
                            <div class="result-meta">${res.file.replace('.html', '').toUpperCase()} • ${res.tags.join(', ')}</div>
                        </a>
                    `).join('');
                    resultsContainer.classList.remove('hidden');
                } else {
                    resultsContainer.innerHTML = '<div class="search-no-results">No results found</div>';
                    resultsContainer.classList.remove('hidden');
                }
            }

            // Local filtering (still useful for immediate feedback on the current page)
            typeEntries.forEach(entry => {
                const name = entry.querySelector('.type-name, h3');
                const desc = entry.querySelector('.type-description');
                const nameText = name ? name.textContent.toLowerCase() : '';
                const descText = desc ? desc.textContent.toLowerCase() : '';

                if (nameText.includes(query) || descText.includes(query)) {
                    entry.classList.remove('hidden');
                } else {
                    entry.classList.add('hidden');
                }
            });

            // Hide sections with no visible entries
            sections.forEach(section => {
                let next = section.nextElementSibling;
                let hasVisible = false;
                while (next && !next.classList.contains('category-header')) {
                    if (next.classList.contains('type-entry') && !next.classList.contains('hidden')) {
                        hasVisible = true;
                        break;
                    }
                    if (next.classList.contains('union-section') && !next.classList.contains('hidden')) {
                        hasVisible = true;
                        break;
                    }
                    next = next.nextElementSibling;
                }
                if (hasVisible) section.classList.remove('hidden');
                else section.classList.add('hidden');
            });
        });

        // Close results when clicking outside
        document.addEventListener('click', function (e) {
            if (!searchInput.contains(e.target) && !resultsContainer.contains(e.target)) {
                resultsContainer.classList.add('hidden');
            }
        });

        // Clear search on Escape
        searchInput.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') {
                this.value = '';
                this.dispatchEvent(new Event('input'));
                this.blur();
            }
        });
    }

    /**
     * Scroll-Spy Functionality
     * Highlights the current visible section in the right sidebar
     */
    function initScrollSpy() {
        const sidebarRight = document.querySelector('.sidebar-right');
        if (!sidebarRight) return;

        const navLinks = sidebarRight.querySelectorAll('.nav-link[href^="#"]');
        if (navLinks.length === 0) return;

        // Get all target sections
        const sections = [];
        navLinks.forEach(link => {
            const href = link.getAttribute('href');
            const target = document.querySelector(href);
            if (target) {
                sections.push({ link, target });
            }
        });

        if (sections.length === 0) return;

        // Use Intersection Observer for efficient scroll tracking
        const observerOptions = {
            root: null,
            rootMargin: '-20% 0px -70% 0px',
            threshold: 0
        };

        let currentActive = null;

        const observer = new IntersectionObserver(function (entries) {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    // Find the link for this section
                    const section = sections.find(s => s.target === entry.target);
                    if (section) {
                        // Remove previous active
                        if (currentActive) {
                            currentActive.classList.remove('active-scroll');
                        }
                        // Set new active
                        section.link.classList.add('active-scroll');
                        currentActive = section.link;

                        // Expand parent details if any
                        let parent = section.link.closest('details');
                        if (parent && !parent.open) {
                            parent.open = true;
                        }
                    }
                }
            });
        }, observerOptions);

        // Observe all sections
        sections.forEach(section => {
            observer.observe(section.target);
        });

        // Handle click on nav links to smooth scroll
        navLinks.forEach(link => {
            link.addEventListener('click', function (e) {
                const href = this.getAttribute('href');
                const target = document.querySelector(href);
                if (target) {
                    e.preventDefault();
                    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
                    history.pushState(null, null, href);
                }
            });
        });
    }

    /**
     * Syntax Highlighting
     * Initialize highlight.js for code blocks
     */
    function initSyntaxHighlighting() {
        if (typeof hljs !== 'undefined') {
            // Register Luau as Lua (highlight.js doesn't have Luau specific yet)
            hljs.highlightAll();
        }
    }

})();
