import asyncio, pathlib, os, sys
from playwright.async_api import async_playwright

ROOT = pathlib.Path("/home/smouj/.openclaw/workspace/main/projects/forever-hud").resolve()
OUT = ROOT / "assets" / "screenshots"
OUT.mkdir(parents=True, exist_ok=True)

async def shot(page, path):
    await page.screenshot(path=str(OUT / path))
    print("wrote", path, flush=True)

async def main():
    base = (ROOT / "preview" / "index.html").as_uri()
    async with async_playwright() as p:
        browser = await p.chromium.launch(args=["--no-sandbox", "--disable-dev-shm-usage", "--force-color-profile=srgb"])
        page = await browser.new_page(viewport={"width":1600,"height":900}, device_scale_factor=1)
        await page.goto(base + "?still=1", wait_until="load")
        await page.wait_for_timeout(600)
        await shot(page, "hud-clasico.png")
        await page.click('button[data-theme="compact"]')
        await page.wait_for_timeout(300)
        await shot(page, "hud-compacto.png")
        await page.click('button[data-theme="minimal"]')
        await page.wait_for_timeout(300)
        await shot(page, "hud-minimo.png")
        page2 = await browser.new_page(viewport={"width":1600,"height":900}, device_scale_factor=1)
        await page2.goto(base + "?still=1&view=settings", wait_until="load")
        await page2.wait_for_timeout(600)
        await shot(page2, "configuracion.png")

try:
    asyncio.run(main())
except Exception as e:
    print("ERROR:", repr(e), flush=True)
finally:
    for f in sorted(OUT.glob("*.png")):
        print(f.name, f.stat().st_size // 1024, "KB", flush=True)
    os._exit(0)
