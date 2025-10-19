import json
import time
from smolagents import tool
from playwright.sync_api import sync_playwright, Page, Browser
import arxiv

class ChromiumBrowser:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ChromiumBrowser, cls).__new__(cls)
            try:
                cls._instance.playwright = sync_playwright().start()
                cls._instance.browser: Browser = cls._instance.playwright.chromium.launch(headless=True)
                cls._instance.page: Page = cls._instance.browser.new_page()
            except Exception as e:
                # Handle cases where Playwright might fail to start (e.g., in a minimal container)
                cls._instance.playwright = None
                cls._instance.browser = None
                cls._instance.page = None
                print(f"[ERROR] Playwright failed to initialize: {e}")
        return cls._instance

    def ensure_browser(self):
        if self.playwright is None or self.browser is None or not self.browser.is_connected():
             raise ConnectionError("Browser is not available. Playwright may have failed to initialize.")
        return self.page


    def go_to(self, url: str) -> str:
        try:
            page = self.ensure_browser()
            page.goto(url, timeout=60000)
            return f"Successfully navigated to {url}."
        except Exception as e:
            return f"Error navigating to {url}: {str(e)}"

    def click(self, selector: str) -> str:
        try:
            page = self.ensure_browser()
            page.click(selector, timeout=10000)
            time.sleep(1) # Wait for potential page loads
            return f"Successfully clicked on '{selector}'."
        except Exception as e:
            return f"Error clicking on '{selector}': {str(e)}"

    def fill(self, selector: str, text: str) -> str:
        try:
            page = self.ensure_browser()
            page.fill(selector, text, timeout=10000)
            return f"Successfully filled '{selector}' with text."
        except Exception as e:
            return f"Error filling '{selector}': {str(e)}"

    def get_text_content(self) -> str:
        try:
            page = self.ensure_browser()
            return page.evaluate("() => document.body.innerText")
        except Exception as e:
            return f"Error getting text content: {str(e)}"

    def close(self):
        if hasattr(self, 'browser') and self.browser and self.browser.is_connected():
            self.browser.close()
        if hasattr(self, 'playwright') and self.playwright:
            self.playwright.stop()
        ChromiumBrowser._instance = None

_browser = ChromiumBrowser()

@tool
def web_navigate(url: str) -> str:
    """Navigates the integrated browser to a specific URL."""
    return _browser.go_to(url)

@tool
def web_click(selector: str) -> str:
    """Clicks on an element in the browser, specified by a CSS selector."""
    return _browser.click(selector)

@tool
def web_fill(selector: str, text: str) -> str:
    """Fills an input field in the browser, specified by a CSS selector."""
    return _browser.fill(selector, text)

@tool
def web_get_text() -> str:
    """Returns the user-visible text of the current browser page."""
    return _browser.get_text_content()

@tool
def arxiv_search(query: str, max_results: int = 5) -> str:
    """Searches for research papers on Arxiv and returns a JSON string of the results."""
    try:
        search = arxiv.Search(query=query, max_results=max_results)
        results = []
        for result in search.results():
            results.append({
                "title": result.title,
                "authors": [author.name for author in result.authors],
                "summary": result.summary[:500] + '...',
                "pdf_url": result.pdf_url
            })
        if not results: return "No papers found for the given query."
        return json.dumps(results, indent=2)
    except Exception as e:
        return f"Error searching Arxiv: {str(e)}"
