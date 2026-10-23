#!/usr/bin/env python3
"""App Store Connect API 小工具（PasteKey 上架用）。读 ~/.appstoreconnect/beihao.env 的团队 API 密钥。
   python3 scripts/asc.py GET /v1/apps/6826107455/appStoreVersions
   python3 scripts/asc.py PATCH /v1/... '{"data":...}'
"""
import base64, json, os, subprocess, sys, time
from pathlib import Path
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature

APP_ID = "6826107455"

def env():
    vals = {}
    for line in (Path.home() / ".appstoreconnect/beihao.env").read_text().splitlines():
        if "=" in line and not line.strip().startswith("#"):
            k, v = line.split("=", 1); vals[k.strip()] = v.strip().strip('"')
    return vals

def token():
    e = env(); kid = e["ASC_KEY_ID"]
    key = serialization.load_pem_private_key((Path.home() / f".appstoreconnect/private_keys/AuthKey_{kid}.p8").read_bytes(), None)
    b = lambda d: base64.urlsafe_b64encode(json.dumps(d, separators=(",", ":")).encode()).rstrip(b"=")
    now = int(time.time())
    msg = b({"alg": "ES256", "kid": kid, "typ": "JWT"}) + b"." + b({"iss": e["ASC_ISSUER_ID"], "iat": now, "exp": now + 1000, "aud": "appstoreconnect-v1"})
    r, s = decode_dss_signature(key.sign(msg, ec.ECDSA(hashes.SHA256())))
    return (msg + b"." + base64.urlsafe_b64encode(r.to_bytes(32, "big") + s.to_bytes(32, "big")).rstrip(b"=")).decode()

_tok = None
def call(method, path, body=None, raw_url=None):
    global _tok
    _tok = _tok or token()
    url = raw_url or ("https://api.appstoreconnect.apple.com" + path)
    cmd = ["curl", "-sg", "-X", method, url, "-H", f"Authorization: Bearer {_tok}", "-H", "Content-Type: application/json"]
    if body is not None: cmd += ["-d", json.dumps(body)]
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    return json.loads(out) if out.strip() else {}

if __name__ == "__main__":
    m, p = sys.argv[1], sys.argv[2]
    body = json.loads(sys.argv[3]) if len(sys.argv) > 3 else None
    print(json.dumps(call(m, p, body), ensure_ascii=False, indent=1)[:6000])


def push_metadata(version_id="b9b95c6b-0e54-45e1-a819-56bc296ccb22", info_id="b9b8faef-2a3a-4a95-9a94-ee583cae4a49"):
    """把 Config/appstore-metadata.json 推到 App Store Connect（名称、副标题、介绍、关键词、宣传语、网址）"""
    meta = json.loads((Path(__file__).resolve().parent.parent / "Config/appstore-metadata.json").read_text())
    infos = {x["attributes"]["locale"]: x["id"] for x in call("GET", f"/v1/appInfos/{info_id}/appInfoLocalizations")["data"]}
    vers = {x["attributes"]["locale"]: x["id"] for x in call("GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")["data"]}
    for loc, d in meta["locales"].items():
        ia = {"name": d["name"], "subtitle": d["subtitle"], "privacyPolicyUrl": meta["privacyPolicyUrl"]}
        r1 = call("PATCH", f"/v1/appInfoLocalizations/{infos[loc]}", {"data": {"type": "appInfoLocalizations", "id": infos[loc], "attributes": ia}}) if loc in infos else \
             call("POST", "/v1/appInfoLocalizations", {"data": {"type": "appInfoLocalizations", "attributes": {"locale": loc, **ia}, "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info_id}}}}})
        va = {"description": d["desc"], "keywords": d["kw"], "promotionalText": d["promo"], "supportUrl": meta["supportUrl"], "marketingUrl": meta["marketingUrl"]}
        if loc not in vers:
            vers = {x["attributes"]["locale"]: x["id"] for x in call("GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")["data"]}
        r2 = call("PATCH", f"/v1/appStoreVersionLocalizations/{vers[loc]}", {"data": {"type": "appStoreVersionLocalizations", "id": vers[loc], "attributes": va}})
        print(loc, "info", "OK" if "data" in r1 else r1.get("errors"), "| version", "OK" if "data" in r2 else r2.get("errors"))


def upload_screenshots(folder, version_id="b9b95c6b-0e54-45e1-a819-56bc296ccb22", display="APP_DESKTOP"):
    """folder 里放 <locale>-1.png … ，按 locale 上传到对应语言的截图组（已有同名截图组会先清空）"""
    import hashlib
    folder = Path(folder)
    vers = {x["attributes"]["locale"]: x["id"] for x in call("GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")["data"]}
    for loc, lid in vers.items():
        files = sorted(folder.glob(f"{loc}-*.png"))
        if not files: continue
        sets = call("GET", f"/v1/appStoreVersionLocalizations/{lid}/appScreenshotSets").get("data", [])
        sset = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == display), None)
        if sset:
            for shot in call("GET", f"/v1/appScreenshotSets/{sset['id']}/appScreenshots").get("data", []):
                call("DELETE", f"/v1/appScreenshots/{shot['id']}")
        else:
            sset = call("POST", "/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets", "attributes": {"screenshotDisplayType": display},
                        "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": lid}}}}})["data"]
        for f in files:
            data = f.read_bytes()
            r = call("POST", "/v1/appScreenshots", {"data": {"type": "appScreenshots", "attributes": {"fileName": f.name, "fileSize": len(data)},
                     "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": sset["id"]}}}}})["data"]
            for op in r["attributes"]["uploadOperations"]:
                chunk = data[op["offset"]: op["offset"] + op["length"]]
                cmd = ["curl", "-sg", "-X", op["method"], op["url"], "--data-binary", "@-"]
                for h in op["requestHeaders"]: cmd += ["-H", f"{h['name']}: {h['value']}"]
                subprocess.run(cmd, input=chunk, capture_output=True)
            done = call("PATCH", f"/v1/appScreenshots/{r['id']}", {"data": {"type": "appScreenshots", "id": r["id"],
                        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
            print(loc, f.name, "OK" if "data" in done else done.get("errors"))
