/**
 * Luau Parser Documentation - Interactive Features
 * - Search filtering
 * - Scroll-spy for sidebar navigation
 * - Syntax highlighting initialization
 */

(function() {
    'use strict';

    // Initialize when DOM is ready
    document.addEventListener('DOMContentLoaded', function() {
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

        const navLinks = document.querySelectorAll('.sidebar-left .nav-link');
        const typeEntries = document.querySelectorAll('.type-entry');

        searchInput.addEventListener('input', function() {
            const query = this.value.toLowerCase().trim();

            if (query === '') {
                // Show all when empty
                navLinks.forEach(link => link.classList.remove('hidden'));
                typeEntries.forEach(entry => entry.classList.remove('hidden'));
                return;
            }

            // Filter navigation links
            navLinks.forEach(link => {
                const text = link.textContent.toLowerCase();
                if (text.includes(query)) {
                    link.classList.remove('hidden');
                } else {
                    link.classList.add('hidden');
                }
            });

            // Filter type entries on the page
            typeEntries.forEach(entry => {
                const name = entry.querySelector('.type-name');
                const desc = entry.querySelector('.type-description');
                const nameText = name ? name.textContent.toLowerCase() : '';
                const descText = desc ? desc.textContent.toLowerCase() : '';

                if (nameText.includes(query) || descText.includes(query)) {
                    entry.classList.remove('hidden');
                } else {
                    entry.classList.add('hidden');
                }
            });
        });

        // Clear search on Escape
        searchInput.addEventListener('keydown', function(e) {
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

        const observer = new IntersectionObserver(function(entries) {
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
            link.addEventListener('click', function(e) {
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
